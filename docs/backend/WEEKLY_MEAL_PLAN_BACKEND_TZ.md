# ТЗ: перенос генерации **недельного** плана питания (5 дней) на бэкенд (Pivot)

**Версия:** 0.1 (draft)  
**Скоуп:** только недельный план (коллекция Directus **`weekPlans`**).  
**Вне скоупа:** дневной план (`days.mealPlan`) — см. `docs/backend/DAILY_MEAL_PLAN_BACKEND_TZ.md`. Регенерация одного блюда/ингредиентов.  
**Предпочтение v1:** расчёт распределения КБЖУ по слотам остаётся на **клиенте**; бэкенд делает оркестрацию/валидацию/запись.

---

## 1. Зачем

**Сейчас:** клиент синхронно генерирует 5 дневных планов (5× вызов пайплайна дневного плана), затем сохраняет одну запись в Directus `weekPlans`. При обрыве сети/закрытии приложения неделя часто не доходит до БД.

**Цель:** после постановки задачи пользователь **не обязан держать приложение открытым** — генерация/валидация/запись выполняются на сервере через Cloud Tasks.

---

## 2. Фактическое поведение фронта (как есть в `rishai`)

### 2.1 Где генерируется неделя

Файл: `lib/features/chat/domain/usecases/generate_week_plan_usecase.dart` (`GenerateWeekPlanUsecaseV2`)

- Генерируется **5 дней** в цикле `for (i=0..4)` через `RequestPlanUsecaseV2` с `RequestPlanParams(isWeekPlan: true)`.
- Поддерживается глобальный `excludedMeals` (карта строковых списков) для избежания повторов между днями:
  - `breakfasts`, `mains`, `snacks`
- После каждого успешного дня заголовки блюд `meal.title` добавляются в соответствующий список по `meal.servingType`.
- Между днями стоит `Future.delayed(Duration(seconds: 2))`.
- Есть пост-обработка “добивка” (`_completeIncompletePlansV2`): если `plan.meals.length < expectedMealsCount` (expected = `servings.length`), выполняется повторная генерация, и план заменяется.

### 2.2 Как формируется дневной `requests[]` (внутри недели)

Файл: `lib/features/chat/domain/usecases/request_plan_usecase.dart` (`RequestPlanParams.generateMealRequests()`).

- Клиент распределяет дневные макросы на слоты по процентам (зависит от: кол-ва приёмов, `snackForToday`, `trainingToday`).
- Создаёт `LlmMealDto` по каждому слоту (тип + целевые `kcal/protein/carbs/fat`).
- Группирует слоты в 2–3 `LlmMealRequest`:
  - отдельный запрос `breakfast` (если есть breakfast)
  - один общий запрос `meal` (lunch/dinner/supper в одном request)
  - отдельный запрос `snack` (если есть snack)
- Для недели вместо `DayEntity.getMealHistory(days)` используется `excludedMeals` как источник “что исключать”.

### 2.3 Как клиент “склеивает” ответы LLM в один дневной `mealPlan`

Файл: `lib/features/chat/data/remote_data_source/remote_data_source_impl.dart` (`requestMealPlanV2`)

- Параллельно вызывает `_llmProxyClient.generateMeals(request)` для каждого элемента `requests[]`.
- Из каждого ответа берёт массив `meals`.
- **Подменяет `meal['macros']`** на целевые макросы из исходного `requests[].meals[]` (порядок по индексу).
- Склеивает все `meals` в `allMeals` и возвращает `{ 'meals': allMeals }`, затем парсится `MealPlanEntity.fromMap`.

### 2.4 Куда клиент сохраняет неделю

Файл: `lib/features/week_plan/presentation/bloc/week_plan_bloc.dart`

- Локально: `HiveImpl.saveWeekPlan()` (`weekPlan_box`)
- Удалённо: `directus.createOne(collection: 'weekPlans', data: week.toMap())`

Файл: `lib/features/week_plan/domain/entities/week_plan_entity.dart`

`WeekPlanEntity.toMap()` пишет поля:
- `userId`: string
- `mealPlans`: array(JSON) из 5 объектов `MealPlanEntity.toMap()`
- `startDate`, `endDate`: string (ms epoch)
- `fitnessGoal`, `dietaryPreferences`: string
- `cuisines`, `mealsTypes`: array(string)

---

## 3. Модель данных на бэке (Directus): `weekPlans`

### 3.1 Ожидаемые поля (строго под текущий Flutter парсер)

Клиент читает через `WeekPlanEntity.fromMap()`:

- `id`: number (Directus)
- `userId`: string (Directus user id)
- `startDate`: string (ms epoch)
- `endDate`: string (ms epoch)
- `mealPlans`: list<object> — ровно 5 элементов
- `fitnessGoal`: string
- `dietaryPreferences`: string
- `cuisines`: list<string>
- `mealsTypes`: list<string>

### 3.2 Семантика дат

На клиенте `endDate = startDate + 4 дня` (5 календарных дней включая `startDate`).

### 3.3 Дедупликация/идемпотентность (требование v1)

Рекомендуется гарантировать уникальность недельного плана на уровне бизнес-логики:

- ключ дедупа: `(userId, startDate)` **и/или** `idempotency_key` задачи.
- при повторном запуске с тем же ключом — возвращать существующий `weekPlanId` и не генерировать заново.

### 3.4 Текущее поведение клиента по синхронизации `weekPlans` (важно не сломать)

Файл: `lib/features/week_plan/presentation/bloc/week_plan_bloc.dart` (`_syncAndLoadWeeks`)

Клиент сейчас:

- читает удалённые планы `directus.readMany(collection: 'weekPlans', filters: { userId == currentUserId })`
- сравнивает с локальными (Hive) по `startDate`
- если локально есть план, которого нет на сервере — пытается **дозалить его** через `directus.createOne(...)`

При переносе генерации на backend это поведение желательно сохранить как «страховку», но целевой сценарий v1:

- неделя создаётся на backend и **сразу** появляется в `weekPlans`,
- клиент при `load`/`sync` подтягивает её как обычную удалённую запись.

---

## 4. Инфраструктура async tasks (уже есть)

См. `pivot-backend/docs/TASKS_ASYNC_API_REFERENCE.md`:

- `POST /tasks/enqueue` (202)
- `POST /tasks/process` (Cloud Tasks + OIDC)
- Directus коллекция `tasks`
- статусы: `pending | processing | done | failed`
- идемпотентность при повторной доставке

Это ТЗ описывает новый тип задачи поверх этого каркаса.

---

## 5. Публичный контракт для клиента (v1)

### 5.1 Старт: `POST /tasks/enqueue`

**Headers:** `pivot-identity-key`, `x-user-id`, `Content-Type: application/json`

**Body:**

```json
{
  "type": "weekly_meal_plan",
  "input": {
    "startDateMs": 0,
    "days": [
      { "dayIndex": 0, "requests": [/* LlmMealRequest JSON */] },
      { "dayIndex": 1, "requests": [/* ... */] },
      { "dayIndex": 2, "requests": [/* ... */] },
      { "dayIndex": 3, "requests": [/* ... */] },
      { "dayIndex": 4, "requests": [/* ... */] }
    ],
    "meta": {
      "dietary": ["string"],
      "cuisines": ["string"],
      "restrictions": ["string"],
      "servings": ["Breakfast|Lunch|Dinner|Supper|Snack"], 
      "hasTraining": true,
      "hasSnack": true
    }
  },
  "idempotencyClientKey": "optional-uuid"
}
```

**Примечания:**
- `days[].requests[]` — это сериализация текущих `LlmMealRequest.toJson()` из Flutter (`type`, `message`, `diet`, `meals[]` с целевыми макросами).
- Расчёты КБЖУ и построение prompts — на клиенте (v1), как сейчас.
- `meta` опционален, только для логов/аналитики/отладки.

### 5.2 Статус: `GET /tasks/:taskId`

Backend должен возвращать:
- `pending|processing|done|failed`
- при `done`: `output.weekPlanId` (обязателен), опционально `output.weekPlan`
- при `failed`: `error.message` (для UI) + `error.code`

**Важно:** на клиенте уже наблюдалась нестабильность `GET /tasks/:id` (404 при существующей задаче). В релизе нужно либо починить ручку, либо явно задокументировать fallback чтения результата по `weekPlans` (см. §8).

---

## 6. Алгоритм воркера `weekly_meal_plan` (server-side)

### 6.1 Вход

- Валидировать, что `days.length == 5`.
- Валидировать, что каждый `days[i].requests` не пуст.

### 6.2 Генерация одного дня

Для каждого `requests[]` внутри дня:

1. Параллельно вызвать внутренний LLM proxy (эквивалент `POST /llm-proxy-meal`) по каждому request.
2. Слить ответы в `allMeals` в порядке `requests[]` (как на фронте).
3. Подменить `macros` каждого блюда на целевые из `request.meals[i]` (по индексу).
4. Валидировать `MealPlanEntity`-совместимость (структура `meals[]` соответствует `Meal.fromMap`).

### 6.3 Сборка и запись `weekPlans`

1. Собрать `mealPlans` как массив из **5** объектов `MealPlanEntity.toMap()` (корень `meals`, `cycleId` можно опустить/ставить `null`).
2. Записать одну строку в Directus `weekPlans`:
   - `userId` из `x-user-id`
   - `startDate` = `startDateMs` в строковом виде
   - `endDate` = `startDateMs + 4 дня` (ms epoch) в строковом виде
   - `mealPlans` = собранный массив
   - метаданные (`fitnessGoal`, `dietaryPreferences`, `cuisines`, `mealsTypes`) — либо из `input.meta`, либо вычислять/не заполнять (решение продукта; сейчас на клиенте они заполняются после генерации).
3. В `tasks.output` записать минимум:

```json
{ "weekPlanId": 123 }
```

Опционально:

```json
{ "weekPlanId": 123, "weekPlan": { /* то же, что записали в Directus */ } }
```

---

## 7. Ошибки, ретраи, идемпотентность

- Любой 5xx в воркере => Cloud Tasks повторит доставку. Поэтому воркер должен:
  - не дублировать запись `weekPlans` при повторе (см. §3.3).
  - быть идемпотентным по `taskId`/`idempotency_key`.
- При LLM/парсинг ошибках => `tasks.status = failed`, `error.message` пригоден для UI (без гигантских payload).

---

## 8. Чтение результата (UX/контракт)

Чтобы клиент не ходил в Directus SDK напрямую, рекомендуется добавить публичные ручки в User Service:

- `GET /week-plans/:id`
- `GET /week-plans?startDateMs=...` (или `GET /week-plans/current`)

Это также является fallback, если `GET /tasks/:id` недоступен/нестабилен.

---

## 9. Критерии приёмки

1. Неделя создаётся без необходимости держать приложение открытым после `enqueue`.
2. В Directus появляется одна запись `weekPlans` с корректными полями и `mealPlans.length == 5`.
3. Каждый дневной `mealPlans[i]` парсится в Flutter через `MealPlanEntity.fromMap`.
4. Макросы блюд в `mealPlans[i].meals[*].macros` равны целевым макросам из входных `requests[]`.
5. Идемпотентность: повторный enqueue с тем же `idempotencyClientKey` не создаёт дубль `weekPlans`.

---

## 10. Миграция клиента (второй этап, после готовности backend)

### 10.1 Что перестаёт делать клиент

Клиент перестаёт синхронно выполнять:

- 5× `RequestPlanUsecaseV2` в цикле
- `Future.delayed(2s)` между днями
- `_completeIncompletePlansV2` (добивка неполных дней)
- прямое `directus.createOne(weekPlans, ...)` после генерации

### 10.2 Что делает клиент вместо этого

1. Формирует 5 наборов `days[i].requests` используя **текущие** `generateMealRequests()` и `excludedMeals` (чтобы сохранить паритет разнообразия блюд между днями).
2. Вызывает `POST /tasks/enqueue` (`type: weekly_meal_plan`) и сохраняет `taskId`.
3. Поллит `GET /tasks/:taskId`.
4. На `done` — читает `weekPlans` с backend (см. §8) и кладёт в Hive + state.

### 10.3 Fallback, если `GET /tasks/:taskId` нестабилен (как уже наблюдали)

Если `GET /tasks/:taskId` даёт 404/нестабилен, клиенту нужен fallback:

- поллить `GET /week-plans?startDateMs=...` (или `GET /week-plans/current`) пока не появится запись,
- либо читать `weekPlans` по `weekPlanId` из `tasks.output` (если `GET /tasks/:id` возвращает `done`).

Это снижает риск «неделя готова, но UI не знает» и делает систему устойчивой к проблемам в ручке статуса задач.

