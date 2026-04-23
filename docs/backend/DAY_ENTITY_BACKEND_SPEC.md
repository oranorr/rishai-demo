# ТЗ: Создание сущности Дня на бэкенде

**Версия:** 1.0  
**Дата:** 17.03.2025  
**Аудитория:** Senior Backend Developer  
**Контекст:** WHOOP proxy-эндпоинты и токены уже перенесены на бэкенд. Текущая задача — вынести создание/получение Day Entity на бэкенд, чтобы фронт вызывал одну ручку и получал готовый день.

---

## 1. Цель

Реализовать эндпоинт `GET /days/current` (или `POST /days/current`), который:
- Получает или создаёт день пользователя на дату «сегодня»
- Использует WHOOP данные (через уже существующие proxy-эндпоинты)
- Рассчитывает макросы, TDEE, Health Metrics по тем же формулам, что и фронт
- Создаёт/обновляет запись в Directus
- Возвращает JSON в формате, совместимом с `DayEntity.fromMap()` на фронте

---

## 2. Предварительные условия

- WHOOP proxy-эндпоинты работают: `GET /whoop/cycles`, `/whoop/body`, `/whoop/recovery`, `/whoop/workouts`, `/whoop/sleep`, `/whoop/cycle/:id`
- Токены WHOOP хранятся и обновляются на бэкенде
- Заголовки: `pivot-identity-key`, `x-user-id` (обязателен)
- Directus: есть коллекция `days` с полями, совместимыми с текущей схемой (см. раздел 6)

---

## 3. Контракт API

### 3.1 Запрос

```
GET /days/current
Headers:
  pivot-identity-key: {IDENTITY_KEY}
  x-user-id: {directusUserId}
Query params (опционально):
  forceRefresh: boolean — при true пересчитать день заново даже если день на сегодня уже есть
```

### 3.2 Успешный ответ (200 OK)

```json
{
  "id": 123,
  "weekTdeeAverage": 2100,
  "macros": {
    "kcal": 2200,
    "protein": 150,
    "carbs": 180,
    "fat": 80
  },
  "healthMetrics": {
    "bmi": 22,
    "lastTdee": 2100,
    "bmr": 1600,
    "bodyFatPerc": 0
  },
  "dateTime": "1742797257888",
  "cycleId": "650800430",
  "mealPlan": null,
  "chatSnap": {
    "dateTime": 1742797257888,
    "requestsLeft": 13,
    "threadId": null
  },
  "welnessEntity": null
}
```

**Важно:** `dateTime` — строка, миллисекунды с эпохи Unix. `cycleId` — строка. Поле `id` в ответе — `directusId` дня.

### 3.3 Коды ошибок

| Код | Ситуация |
|-----|----------|
| 400 | Отсутствует `x-user-id` |
| 401 | Неверный `pivot-identity-key` |
| 403 | WHOOP не подключён или токены невалидны |
| 404 | Пользователь не найден |
| 502 | WHOOP API недоступен |
| 503 | Недостаточно WHOOP данных для расчёта (fallback невозможен) |

---

## 4. Последовательность действий (алгоритм)

### Шаг 1: Валидация и загрузка пользователя

1. Проверить `x-user-id`.
2. Загрузить пользователя из Directus/User Service: `id`, `bodyMeasurements` (weight, height), `gender`, `age`, `userGoal` (modificator, goal type, updatedAt), `foodPreferences.diets`.
3. Проверить, что WHOOP подключён: `GET /whoop/status` (или эквивалент) — `connected: true`.

### Шаг 2: Решить — создавать новый день или вернуть существующий

1. Получить последний день пользователя из Directus (по `userId`, сортировка по `dateTime` desc).
2. Проверить `GET /whoop/cycle/:id` для `cycleId` последнего дня — если `end != null` и `score_state == SCORED`, цикл завершён → **нужен новый день**.
3. Если цикл не завершён и последний день — на «сегодня», и `forceRefresh != true` → **вернуть существующий день** (преобразовать в JSON ответа).
4. Если `forceRefresh == true` или нет дня на сегодня или цикл завершён → перейти к шагу 3.

### Шаг 3: Загрузка WHOOP данных

Вызвать proxy-эндпоинты (с `x-user-id`):

1. `GET /whoop/cycles` — список циклов
2. `GET /whoop/body` — тело (height_meter, weight_kilogram, max_heart_rate)
3. `GET /whoop/recovery` — recovery (найти запись с `cycle_id == первый цикл.id`, `score_state == SCORED`)
4. `GET /whoop/sleep` — сон (первый SCORED)
5. `GET /whoop/workouts` — тренировки. Фильтр: только `score_state == SCORED`; для цикла (первый из `cycles`): `workout.start >= cycle.start` И `workout.end < cycle.end` (cycle.end должен быть не null — используем завершённый цикл)

### Шаг 4: Проверка достаточности данных

Нужны все:

- `cycles` не пусто
- Первый цикл имеет `score` с `strain`, `kilojoule`
- `body` (height_meter, weight_kilogram)
- `recovery` с `score.recovery_score`
- `sleep` с `score.sleep_performance_percentage`

Если чего-то нет → **fallback**: вернуть последний сохранённый день из Directus, если есть. Иначе 503.

### Шаг 5: Recomp-логика (опционально, перед расчётом)

Если `userGoal.goal == recomp` и `needsCreateNewDay`:

- `daysSinceUpdate = now - userGoal.updatedAt` (в днях)
- Если `daysSinceUpdate >= 14`: обновить `modificator`:
  - `newModifier = (modificator > 0) ? -0.05 : 0.05`
  - Сохранить обновлённый `userGoal` (Directus/User Service)
  - Использовать `newModifier` в расчётах

### Шаг 6: Расчёт TDEE и Calorie Goal

**Константы:**
```text
KJ_TO_KCAL = 0.239006
```

**TDEE Average:**
```text
scoredCycles = циклы с score_state == "SCORED" и end != null (взять до 8 штук)
sumKj = sum(cycle.score.kilojoule for cycle in scoredCycles)
sumKcal = sumKj * KJ_TO_KCAL
tdeeAverage = sumKcal / scoredCycles.length
```

**Calorie Goal:**
```text
modificator = userGoal.modificator  // например 0.05, -0.05, 0
calorieGoal = (1 + modificator) * tdeeAverage
calorieGoal = round(calorieGoal)
```

### Шаг 7: Расчёт Health Metrics

**BMI:**
```text
bmi = round(weight_kg / (height_m * height_m))
```

**BMR (Mifflin-St Jeor):**
```text
s = (gender == "male") ? 5 : -161
bmr = round(10 * weight_kg + 6.25 * (height_m * 100) - 5 * age + s)
```

**lastTdee:**
```text
lastTdee = round(cycleScore.kilojoule * KJ_TO_KCAL)  // из первого (текущего/завершённого) цикла
```

**bodyFatPerc:** всегда `0`.

### Шаг 8: Расчёт макросов

Выбор алгоритма по диете:
```text
userDiets = user.foodPreferences.diets  // массив строк
needsKetoCarnivore = any(diet in ["keto", "carnivore"] for diet in userDiets, case-insensitive)
specialDietType = "carnivore" if "carnivore" in userDiets else ("keto" if "keto" in userDiets else null)
```

Данные для расчёта:
```text
strainValue = cycleScore.strain
recoveryScore = round(recovery.score.recovery_score)
sleepPerformance = round(sleep.score.sleep_performance_percentage)
userWeightLbs = weight_kg * 2.205
```

---

#### 8.1 Стандартный алгоритм (`calcMacros`)

**Белки (calcProteins):**

- Без тренировок:
  ```text
  proteins = (0.6 * strainProtein + 0.3 * recoveryProtein + 0.1 * sleepProtein) * userWeightLbs
  ```
- 1 тренировка:
  ```text
  proteins = (0.5 * activityProtein + 0.3 * strainProtein + 0.1 * recoveryProtein + 0.1 * sleepProtein) * userWeightLbs
  ```
- Несколько тренировок:
  ```text
  total = sum по каждой тренировке: (0.5 * activityProtein + 0.3 * strainProtein + 0.1 * recoveryProtein + 0.1 * sleepProtein) * userWeightLbs
  proteins = round(total / count(workouts))
  ```

**Жиры (clacFats):**
```text
fats = (0.5 * strainFats + 0.5 * recoveryFats) * userWeightLbs
fats = round(fats)
```
*sleepPerformance в CalculateWhoopData для fats = 0*

**Углеводы (calcCarbs):**
```text
proteinsInKcal = protein * 4
fatsInKcal = fats * 9
carbsInKcal = calorieGoal - proteinsInKcal - fatsInKcal
carbs = round(carbsInKcal / 4)
```

**Таблицы для Strain / Recovery / Sleep / Activity** — см. раздел 5.

**Fallback при нулевом весе:**
```text
protein = round(0.3 * calorieGoal / 4)
fat = round(0.2 * calorieGoal / 9)
carbs = round(0.5 * calorieGoal / 4)
```

**Валидация:** если protein, fats или carbs <= 0, подставить fallback-значения как выше.

---

#### 8.2 Carnivore алгоритм (`calcMacrosForCarnivore`)

**Углеводы:** всегда 1%.
```text
carbsKcal = calorieGoal * 0.01
carbs = round(carbsKcal / 4)
```

**Белки (процент):** комбинация Strain и Recovery (50/50).
```text
proteinPercentFromStrain = strainToProteinCarnivore(strainValue)
proteinPercentFromRecovery = recoveryToProteinCarnivore(recoveryScore)
proteinPercent = 0.5 * proteinPercentFromStrain + 0.5 * proteinPercentFromRecovery
```

**Жиры:**
```text
fatPercent = 100 - 1 - proteinPercent
```

**Граммы:**
```text
proteinKcal = calorieGoal * (proteinPercent / 100)
fatKcal = calorieGoal * (fatPercent / 100)
protein = round(proteinKcal / 4)
fat = round(fatKcal / 9)
```

**Strain → Protein% (Carnivore):**

| Strain | Protein% |
|--------|----------|
| 0-5    | 30       |
| 6-9    | 31       |
| 10-13  | 32       |
| 14-16  | 33       |
| 17-18  | 34       |
| 19+    | 35       |
| иначе  | 32.5     |

**Recovery → Protein% (Carnivore):**

| Recovery | Protein% |
|----------|----------|
| 0-19     | 35       |
| 20-39    | 34       |
| 40-59    | 33       |
| 60-79    | 32       |
| 80-89    | 31       |
| 90-100   | 30       |
| иначе    | 32.5     |

**Fallback при нулевом весе:**
```text
carbs = round(0.01 * calorieGoal / 4)
protein = round(0.325 * calorieGoal / 4)
fat = round(0.665 * calorieGoal / 9)
```

---

#### 8.3 Keto алгоритм (`calcMacrosForKeto`)

**Strain + Recovery (50/50) для protein% и carbs%:**
```text
strainMacros = strainToKetoMacros(strainValue)   // (protein%, carbs%)
recoveryMacros = recoveryToKetoMacros(recoveryScore)
proteinPercent = 0.5 * strainMacros.protein + 0.5 * recoveryMacros.protein
carbsPercent = 0.5 * strainMacros.carbs + 0.5 * recoveryMacros.carbs
fatPercent = 100 - proteinPercent - carbsPercent
```

**Strain → Keto (protein%, carbs%):**

| Strain | Protein% | Carbs% |
|--------|----------|--------|
| 0-5    | 20       | 5      |
| 6-9    | 21       | 6      |
| 10-13  | 22       | 7      |
| 14-16  | 23       | 8      |
| 17-18  | 24       | 9      |
| 19+    | 25       | 10     |
| иначе  | 22.5     | 7.5    |

**Recovery → Keto (protein%, carbs%):**

| Recovery | Protein% | Carbs% |
|----------|----------|--------|
| 0-19     | 25       | 10     |
| 20-39    | 24       | 9      |
| 40-59    | 23       | 8      |
| 60-79    | 22       | 7      |
| 80-89    | 21       | 6      |
| 90-100   | 20       | 5      |
| иначе    | 22.5     | 7.5    |

**Граммы:**
```text
protein = round(calorieGoal * (proteinPercent/100) / 4)
carbs = round(calorieGoal * (carbsPercent/100) / 4)
fat = round(calorieGoal * (fatPercent/100) / 9)
```

**Fallback при нулевом весе:**
```text
protein = round(0.225 * calorieGoal / 4)
carbs = round(0.075 * calorieGoal / 4)
fat = round(0.7 * calorieGoal / 9)
```

---

### Шаг 9: Сборка Day Entity и сохранение в Directus

**Структура для Directus (create/update):**
```json
{
  "userId": "{directusUserId}",
  "dateTime": "{milliseconds}",
  "weekTdeeAverage": 2100,
  "macros": { "kcal": 2200, "protein": 150, "carbs": 180, "fat": 80 },
  "healthMetrics": { "bmi": 22, "lastTdee": 2100, "bmr": 1600, "bodyFatPerc": 0 },
  "cycleId": "650800430",
  "mealPlan": null,
  "chatSnap": {
    "dateTime": 1742797257888,
    "requestsLeft": 13,
    "threadId": null
  },
  "welnessEntity": null
}
```

Для **нового дня**:
- `mealPlan`, `chatSnap`, `welnessEntity` — null или пустые значения по умолчанию
- `chatSnap.requestsLeft` — брать из профиля пользователя/подписки (если есть), иначе дефолт, например 13

Для **существующего дня** (если обновляем при forceRefresh):
- Сохранять существующие `mealPlan`, `chatSnap`, `welnessEntity` из Directus, менять только `macros`, `healthMetrics`, `weekTdeeAverage`, `cycleId`.

### Шаг 10: Ответ клиенту

Вернуть созданную/обновлённую запись в формате из раздела 3.2. Поле `dateTime` — строка с миллисекундами. `cycleId` — строка.

---

## 5. Таблицы для стандартного алгоритма макросов

### 5.1 Strain → (protein, fats) — коэффициенты на фунт веса

**Male:**

| Strain    | protein | fats |
|-----------|---------|------|
| > 17.5    | 1.2     | 0.5  |
| 15 - 17.4 | 1.1     | 0.47 |
| 12.5-14.9 | 1.0     | 0.44 |
| 10-12.4   | 0.9     | 0.41 |
| 7.5-9.9   | 0.8     | 0.38 |
| ≤ 7.4     | 0.7     | 0.35 |

**Female:**

| Strain    | protein | fats |
|-----------|---------|------|
| > 17.5    | 1.0     | 0.5  |
| 15 - 17.4 | 0.9     | 0.47 |
| 12.5-14.9 | 0.8     | 0.44 |
| 10-12.4   | 0.7     | 0.41 |
| 7.5-9.9   | 0.6     | 0.38 |
| ≤ 7.4     | 0.5     | 0.35 |

### 5.2 Recovery → (protein, fats)

**Male:**

| Recovery | protein | fats |
|----------|---------|------|
| 85-100   | 0.7     | 0.35 |
| 60-84    | 0.8     | 0.38 |
| 45-59    | 0.9     | 0.41 |
| 30-44    | 1.0     | 0.44 |
| 15-29    | 1.1     | 0.47 |
| 1-14     | 1.2     | 0.5  |

**Female:**

| Recovery | protein | fats |
|----------|---------|------|
| 85-100   | 0.5     | 0.35 |
| 60-84    | 0.6     | 0.38 |
| 45-59    | 0.7     | 0.41 |
| 30-44    | 0.8     | 0.44 |
| 15-29    | 0.9     | 0.47 |
| 1-14     | 1.0     | 0.5  |

### 5.3 Sleep Performance → (protein)

**Male:**

| Sleep %  | protein |
|----------|---------|
| 85-100   | 0.7     |
| 60-84    | 0.8     |
| 45-59    | 0.9     |
| 30-44    | 1.0     |
| 15-29    | 1.1     |
| 0-14     | 1.2     |

**Female:**

| Sleep %  | protein |
|----------|---------|
| 85-100   | 0.5     |
| 60-84    | 0.6     |
| 45-59    | 0.7     |
| 30-44    | 0.8     |
| 15-29    | 0.9     |
| 0-14     | 1.0     |

### 5.4 Activity → (protein, fats) — по sportId

Сначала маппинг `sportId` → тип активности:

| sportId | Activity   |
|---------|------------|
| 45, 51, 59, 83, 99, 105, 107, 112, 113, 123, 235 | strength |
| 0, 1, 16-34, 36-37, 42, 49, 57, 61-66, 71, 73-76, 82, 84-86, 89, 91-93, 95, 97, 100-102, 106, 126, 230-232, 234, 238-240 | cardio |
| 35, 38-39, 47-48, 52-53, 55-56, 60, 94, 96, 98, 103, 110, 127 | hiit |
| 43-44, 70, 87-88, 90, 108-109, 121, 125, 128, 233, 236-237 | activeRest |
| -1, остальные | hiit (fallback) |

**Activity → (protein, fats)** — коэффициенты на фунт:

| Activity    | Male protein | Male fats | Female protein | Female fats |
|-------------|--------------|-----------|----------------|-------------|
| strength    | 1.1          | 0         | 0.9            | 0           |
| cardio      | 0.9          | 0         | 0.7            | 0           |
| hiit        | 1.0          | 0         | 0.8            | 0           |
| activeRest  | 0.8          | 0         | 0.6            | 0           |

---

## 6. Схема Directus `days`

Ожидаемые поля (JSON/типы могут отличаться в зависимости от вашей настройки Directus):

| Поле           | Тип        | Описание                              |
|----------------|------------|---------------------------------------|
| id             | int        | PK                                    |
| userId         | string/int | ID пользователя                       |
| dateTime       | string     | миллисекунды с эпохи                   |
| weekTdeeAverage| int        | средний TDEE за неделю                 |
| macros         | JSON       | `{ kcal, protein, carbs, fat }`       |
| healthMetrics  | JSON       | `{ bmi, lastTdee, bmr, bodyFatPerc }`  |
| cycleId        | string     | ID цикла WHOOP                        |
| mealPlan       | JSON       | объект или null                       |
| chatSnap       | JSON       | `{ dateTime, requestsLeft, threadId }`  |
| welnessEntity  | JSON       | объект или null                       |

---

## 7. Референсы в Flutter

| Логика                    | Файл                                                      |
|---------------------------|-----------------------------------------------------------|
| Общий поток getData       | `lib/features/whoop/data/repository/whoop_repository_impl.dart` → `_fetchFreshData` |
| TDEE, Calorie Goal       | `whoop_repository_impl.dart` → `calculateTDEEAverage`, `calculateCalorieGoal` |
| Health Metrics           | `whoop_repository_impl.dart` → `calcHealthMetrics`         |
| Стандартные макросы      | `lib/features/whoop/domain/entities/user_data_entity.dart` → `calcMacros`, `calcProteins`, `clacFats`, `calcCarbs` |
| Keto/Carnivore макросы    | `user_data_entity.dart` → `calcMacrosForKeto`, `calcMacrosForCarnivore` |
| Strain/Recovery/Sleep    | `lib/features/whoop/presentation/calculate.dart` → `CalculateWhoopData` |
| Activity mapping         | `lib/features/whoop/domain/entities/activity.dart`        |
| Константы                | `lib/core/constants/constants.dart` → `kjToKcal`, `kgToLbs` |
| Recomp                   | `lib/features/user/presentation/bloc/user_bloc.dart` → `checkRecompForNewDay` |
| DayEntity / toDirectus   | `lib/features/whoop/domain/entities/day_entity.dart`      |
| ChatSnapshot toDirectus  | `lib/features/chat/domain/entities/chat_snapshot_entity.dart` |

---

## 8. Чек-лист для разработчика

- [ ] Эндпоинт `GET /days/current` с `x-user-id`
- [ ] Загрузка пользователя (body, gender, age, goal, diets)
- [ ] Проверка WHOOP status
- [ ] Логика «цикл завершён» vs «вернуть существующий день»
- [ ] Вызов WHOOP proxy: cycles, body, recovery, sleep, workouts
- [ ] Фильтрация workouts по циклу
- [ ] Recomp: смена modificator раз в 14 дней
- [ ] Формулы TDEE, Calorie Goal, Health Metrics
- [ ] Три алгоритма макросов: standard, keto, carnivore
- [ ] Таблицы Strain, Recovery, Sleep, Activity без ошибок
- [ ] Fallback при неполных WHOOP данных
- [ ] CRUD Directus для дней
- [ ] Ответ в формате, совместимом с `DayEntity.fromMap()`

---

## 9. Примечания

1. **Точность:** Округление — через `round()` к целому. Килокалории: 4 ккал/г белка, 4 ккал/г углеводов, 9 ккал/г жира.
2. **Часовой пояс:** Использовать UTC или согласованный timezone для «сегодня». На фронте сейчас `DateTime.now()` локально.
3. **requestsLeft:** Источник — подписка/лимиты пользователя. Если нет — использовать разумный дефолт (например, 13).
4. **Первая реализация:** Можно опустить recomp-логику и сложные edge cases, реализовав базовый путь: WHOOP → расчёт → Directus → ответ. Расширить в итерации 2.
