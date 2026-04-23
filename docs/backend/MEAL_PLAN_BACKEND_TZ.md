# ТЗ: серверная генерация и хранение планов питания (миграция пункта 1 — Gemini / meal plans)

**Аудитория:** backend-разработчик / AI-агент на сервисе Pivot (User Service, Cloud Run).  
**Репозиторий приложения (контекст паритета):** Flutter-клиент `rishai`.

---

## 1. Роль и контекст

В мобильном приложении Flutter уже есть:

- Вызов **`POST …/llm-proxy-meal`** с телом, совместимым с `LlmMealRequest` (тип `breakfast` | `meal` | `snack`, поля `message`, `diet`, массив `meals` с целевыми макросами на слот).
- На клиенте **несколько параллельных** запросов к прокси, **склейка** ответов в один массив `meals`, **подмена макросов** на целевые из запроса, парсинг в `MealPlanEntity`, затем сохранение дня через **`PATCH /days/current`** с полем `mealPlan`.

**Проблема:** при обрыве сети/приложения сборка рвётся, пользователь получает ошибки; логика дублируется и завязана на стабильность клиента.

**Цель:** вся **оркестрация вызовов LLM, валидация, склейка плана и запись в БД** выполняются **только на сервере**. Клиент в итоге только **инициирует** генерацию и **читает** готовый результат из API (для дня — **`GET /days/current`**, для недели — см. ниже).

### 1.1 Модель данных (Directus) — важно для паритета

Продуктовая схема **разделяет** два кейса (см. код `lib/features/week_plan` и `GenerateWeekPlanUsecaseV2`).

| Тип | Где живёт результат в Directus |
|-----|--------------------------------|
| **План на день** | Коллекция **`days`**: поле **`mealPlan`** — один объект в формате раздела 6. Обновление как сейчас через **`PATCH /days/current`** с `mealPlan`. |
| **Недельный план** | Отдельная коллекция **`weekPlans`** (константа в клиенте: `weekPlanCollection`, файл `lib/core/services/directus/directus_collections.dart`). Одна запись = одна «неделя» пользователя. |

**Поля записи `weekPlans` (как ожидает клиент `WeekPlanEntity`):**

| Поле | Тип / формат | Примечание |
|------|----------------|------------|
| `id` | number (Directus) | Первичный ключ, на клиенте при чтении может приходить в map — учитывать при паритете |
| `userId` | string | Directus id пользователя (как `user.directusId`) |
| `startDate` | **string**, миллисекунды эпохи | В `WeekPlanEntity.fromMap` парсится как `int.parse(map['startDate'] as String)` |
| `endDate` | **string**, миллисекунды эпохи | Аналогично; период недели в коде: `endDate = startDate + 4` суток (5 календарных дней включительно от логики `WeekPlanEntity.create`) |
| `mealPlans` | **массив JSON** | Ровно **5 элементов** — каждый объект в том же формате, что **`MealPlanEntity.toMap()`** (корень: `meals`, опционально `cycleId`). Это пять дневных планов подряд, не один сплющенный список. |
| `fitnessGoal` | string | На клиенте после генерации подставляется из цели пользователя |
| `dietaryPreferences` | string | Упрощённо: часто первая диета из профиля |
| `cuisines` | array of string | |
| `mealsTypes` | array of string | Подписи приёмов пищи из порций (см. `WeekPlanBloc._onGenerate`) |

**Семантика `five_day` на клиенте сегодня (обязательный паритет для бэкенда):**

- В `GenerateWeekPlanUsecaseV2` неделя собирается как **5 последовательных** прогонов того же пайплайна, что и дневной план (`RequestPlanParams` + `requestPlanUsecaseV2`), с **`isWeekPlan: true`** и накопительным **`excludedMeals`** (`breakfasts` / `mains` / `snacks` — заголовки уже сгенерированных блюд).
- Между днями **2 секунды** задержки (`Future.delayed`) — при переносе на сервер либо сохранить, либо осознанно убрать с согласования продуктом (влияет на rate limit LLM).
- После 5 проходов вызывается **`_completeIncompletePlansV2`** — добивка неполных дней повторной генерацией при нехватке блюд относительно `servings.length`.

**Следствие для бэкенда:** `planKind: single_day` → запись в **`days.mealPlan`**. `planKind: five_day` → **`directus.createOne(collection: 'weekPlans', data: weekPlanEntity.toMap())`** (или серверный эквивалент): **одна** строка в **`weekPlans`** с **`mealPlans`: [день1…день5]**; не путать с пятью PATCH в `days`, если текущий продукт так не хранит неделю.

---

## 2. Конечный результат (Definition of Done)

1. Новый **доменный** API (не «сырой» LLM-прокси для сценария «создать план»), например:
   - **`POST /meal-plans/jobs`** — создать задачу генерации (рекомендуется для 1-day и обязательно для 5-day из-за длительности).
   - **`GET /meal-plans/jobs/:jobId`** — статус: `queued` | `running` | `completed` | `failed`, по `completed` — ссылка на результат или встроенный `mealPlan`.
   - Альтернатива/дополнение: **`POST /meal-plans/sync`** — только для короткого 1-day с жёстким таймаутом на сервере (если продукт готов ждать в одном HTTP); для 5-day — **только async job**.

2. По успешному завершению job сервер:
   - Формирует JSON плана блюд **в формате раздела 6** (совместимость с **`MealPlanEntity` / `Meal`** на клиенте), отдельно для каждого логического результата (один день vs структура недели — по полю **`mealPlans`** недельной коллекции).
   - **`single_day`:** **пишет** в текущий день пользователя (**`PATCH /days/current`** с `mealPlan` или эквивалентный внутренний сервисный вызов).
   - **`five_day`:** **пишет** в коллекцию **недельного плана** (создание/обновление записи: даты, пользователь, `mealPlans`, цели/предпочтения — по контракту Directus и клиента). Не смешивать с записью только в «сегодняшний» день, если так не устроена схема данных.
   - Опционально (если сейчас это критично для продукта): побочный эффект «сообщение в чат» **только для однодневного** сценария — см. раздел 7. Если нет — явно зафиксировать в релиз-нотах и согласовать с mobile.

3. Клиент **не обязан** вызывать `llm-proxy-meal` для сценария «создать дневной/недельный план» (прокси может остаться для других сценариев или быть внутренней реализацией).

4. Ошибки — **структурированные** (как в остальном API: `success: false`, `error: { code, message }`), не «голый» stack trace наружу.

---

## 3. Аутентификация и заголовки

Как у существующих ручек (`/days/current`, `/whoop/...`):

- **`pivot-identity-key`**: сервисный ключ (как сейчас).
- **`x-user-id`**: Directus user id (обязателен).
- **`Content-Type: application/json`** для POST.

Проверка прав: только свой пользователь; job привязан к `userId` из заголовка.

---

## 4. Входные данные генерации (контракт с клиентом)

Клиент сегодня собирает **`List<LlmMealRequest>`** из `RequestPlanParams`. На бэкенде нужно принять **эквивалентный** payload **одним** телом, чтобы клиент не дублировал оркестрацию.

**Рекомендуемое тело `POST /meal-plans/jobs`:**

```json
{
  "planKind": "single_day | five_day",
  "requests": [
    {
      "type": "breakfast",
      "message": "string",
      "diet": "string",
      "meals": [
        { "type": "Savoury Breakfast", "kcal": 0, "protein": 0, "carbs": 0, "fat": 0 }
      ]
    },
    {
      "type": "meal",
      "message": "string",
      "diet": "string",
      "meals": []
    },
    {
      "type": "snack",
      "message": "string",
      "diet": "string",
      "meals": []
    }
  ],
  "options": {
    "replacePartialOnFailure": false,
    "maxTotalRuntimeSeconds": 300
  }
}
```

- **`planKind`**: соответствует `isWeekPlan` на клиенте (`false` → `single_day`, `true` → `five_day`). **Цель записи в БД разная** (см. §1.1): день → `days.mealPlan`; неделя → отдельная коллекция. Набор LLM-запросов (`requests`) на клиенте для недели **может совпадать** с однодневным (те же breakfast/meal/snack + исключения в `message`) — это не отменяет **другую** целевую сущность для `five_day`. Поведение промптов переносить 1:1 со `RequestPlanParams` / `generateMealRequests` в репозитории `rishai`.
- **`requests`**: семантика **как у текущего** `POST /llm-proxy-meal`: те же `type.name`, `diet`, `message`, массив `meals` с целевыми КБЖУ.

**Идемпотентность (желательно):** заголовок **`Idempotency-Key`** или поле `clientRequestId` (UUID) — при повторе с тем же ключом возвращать тот же `jobId`, если job ещё не `failed`.

---

## 5. Алгоритм сервера (оркестрация)

1. **Валидация** тела: типы, непустые `requests` для выбранного `planKind`, лимиты на размер (защита от abuse).
2. **Загрузка контекста пользователя** (если нужно для промптов): цели, ограничения, язык — из Directus / User Service так же, как сейчас это неявно заложено в `message` на клиенте. Если вся строка уже в `message` — можно не тянуть профиль; иначе — явно документировать, что сервер дополняет контекст.
3. Для **каждого** элемента `requests` (как сейчас на клиенте **параллельно**):
   - Вызвать **существующий внутренний** обработчик, эквивалентный `POST /llm-proxy-meal` (не обязательно HTTP loopback — достаточно общей функции).
   - Ретраи при 502/таймаутах — как у клиента (например до 3 попыток с backoff).
4. **Склейка ответов** в один массив **`meals`**:
   - Порядок: как на клиенте после `Future.wait` — зафиксировать порядок в реализации (например: breakfast → meal → snack, внутри типа — порядок элементов в `requests` и порядок слотов в `meals`).
5. **Подмена макросов** (критично для паритета с текущим приложением):
   - Для i-го блюда в ответе по каждому типу подставить **`macros`** из i-го элемента **`meals`** в исходном запросе (как в `remote_data_source_impl`: замена `meal['macros']` на целевые kcal/protein/carbs/fat).
6. **Валидация плана:**
   - Каждое блюдо должно парситься в структуру раздела 6 (обязательные поля, типы).
   - При `replacePartialOnFailure: false` — если **любой** подзапрос упал или валидация не прошла → job `failed`, **не** коммитить частичный результат в целевую сущность (ни день, ни недельную запись — по умолчанию).
7. **Сохранение (ветвление по `planKind`):**
   - Собрать объект(ы) плана с полем **`meals`** (и при необходимости **`cycleId`**) в формате раздела 6.
   - **`cycleId` (для `single_day`)**: как у клиента при сборке `MealPlanEntity` — брать с **текущего дня** пользователя (источник истины тот же, что для `GET /days/current`), не с клиентского запроса.
   - **`single_day`:** записать **`mealPlan`** в текущий день — эквивалент **`PATCH /days/current`** с `{ "mealPlan": { ... } }`.
   - **`five_day`:** выполнить **5 последовательных** прогонов дневного пайплайна с накоплением `excludedMeals` и (по паритету) логикой добивки как **`_completeIncompletePlansV2`** в `generate_week_plan_usecase.dart`; собрать **`WeekPlanEntity.toMap()`** и записать **одну** запись в коллекцию **`weekPlans`** (`mealPlans` = массив из 5 `MealPlanEntity`).
8. Завершить job со статусом `completed`:
   - для **`single_day`** — в ответе job и/или через **`GET /days/current`** отдать актуальный `mealPlan`;
   - для **`five_day`** — в ответе job отдать **id записи недельного плана** и/или ссылку на **GET**-ручку недели (если есть в API; иначе добавить в скоуп бэкенда).

---

## 6. JSON `mealPlan` (совместимость с Flutter)

Клиент парсит через **`MealPlanEntity.fromMap` → `Meal.fromMap`**. Минимальные требования к каждому элементу `meals[]`:

| Поле | Тип | Примечание |
|------|-----|------------|
| `title` | string | |
| `type` | string | Должен быть согласован с эвристикой `Meal.servingType` (содержит Breakfast/Lunch/Dinner/Supper/Snack и т.д.) |
| `description` | string | |
| `macros` | object | `kcal`, `protein`, `carbs`, `fat` (числа, совместимые с `MacrosBreakdown.fromMap`) |
| `ingredients` | array | Элементы: либо новый формат (`id`, `name`, `quantity`, `unit`, опционально `emoji`, `category`), либо legacy `title` + `amount` — клиент поддерживает оба в `Ingredient.fromMap` |
| `cooking_instructions` | array of string | Может быть `[]` |
| `isRegenerated` | bool | По умолчанию `false` |

Корневой объект `mealPlan`:

```json
{
  "meals": [],
  "cycleId": 123456789
}
```

`cycleId` — **int или null**, как ожидает клиент после маппинга.

---

## 7. Побочный эффект «чат» (1-day)

Сейчас после сборки **однодневного** плана клиент вызывает чат с промптом вида `{'meals': ...}` (`requestAssistant` с `isChat: true`).

**Требование к бэкенду:** либо

- **A)** Повторить это **на сервере** после успешной записи `mealPlan` (вызов внутренней логики `/llm-proxy-chat`), **без** блокировки UI (fire-and-forget в job), **или**
- **B)** Явно отключить и завести отдельную задачу на mobile.

По умолчанию для паритета поведения — **вариант A**, если чат-история важна для аналитики/UX.

---

## 8. Регенерация одного блюда

Сейчас: **`replaceMealV2`** → `POST /llm-proxy-meal` с `LlmRegenerateMealRequest`.

**Требование:** отдельная ручка, например **`POST /meal-plans/regenerate-slot`**, тело: тип запроса (`breakfast|meal|snack`), `message`, `targetMeal` (как в `LlmRegenerateMealRequest`), плюс при необходимости список заголовков уже существующих блюд для исключений (клиент сейчас передаёт это в `message`).

Результат: **обновлённый полный план** в целевой сущности в БД: для **дневного** сценария — **`GET /days/current`** с обновлённым `mealPlan`; для **недельного** — обновление записи **недельной** коллекции (и согласованный GET, если он есть в продукте).

---

## 9. Ошибки и коды

Единый стиль с существующими эндпоинтами User Service:

- `400` — валидация, неверный `planKind`, пустые `requests`.
- `401` — неверный `pivot-identity-key`.
- `403` — user mismatch.
- `404` — пользователь/день не найдены (если применимо).
- `409` — уже есть активный job на генерацию (опционально).
- `502/503` — недоступен LLM.

В теле: `{ "success": false, "error": { "code": "MEAL_PLAN_JOB_FAILED", "message": "..." } }`.

Для async job детали ошибки — в **`GET /meal-plans/jobs/:id`** (`failed` + `error`).

---

## 10. Нефункциональные требования

- **Логи:** `jobId`, `userId`, `planKind`, длительность, число LLM-вызовов, успех/фейл по каждому подзапросу.
- **Метрики:** счётчики job completed/failed, latency, rate limit per user.
- **Лимиты:** максимум параллельных LLM-вызовов на job, таймаут всего job.
- **Безопасность:** не логировать полные промпты с PII в production или маскировать email.

---

## 11. Критерии приёмки (чеклист)

1. **Паритет LLM-части:** для одинакового входного `requests` сгенерированные блюда (после подмены макросов) эквивалентны текущему клиентскому пайплайну (порядок, структура полей раздела 6).
2. **Паритет записи:** после `completed` job при **`single_day`** в **`GET /days/current`** виден актуальный **`mealPlan`**; при **`five_day`** в Directus создана/обновлена запись **недельного плана** (коллекция из §1.1), а не только «случайно» обновлён текущий день, если так не задумано продуктом.
3. Обрыв мобильного приложения **после** `POST /job` **не отменяет** job: генерация доходит до конца или до `failed` на сервере.
4. При падении одного из параллельных LLM-запросов поведение соответствует флагу `replacePartialOnFailure` (по умолчанию — полный отказ без записи).
5. Документация OpenAPI/Swagger или markdown в репозитории бэкенда с примерами тел и ответов.
6. E2E-тест или интеграционный тест с моком LLM, проверяющий запись в Directus.

---

## 12. Вне скоупа (отдельные задачи / mobile)

- Удаление вызовов `llm-proxy-meal` / `requestMealPlanV2` из Flutter и переключение на новый API — **отдельный PR** на клиенте после стабилизации контракта.
- Полный перенос **чата** на сервер — не обязателен в этой задаче, кроме пункта 7 если выбран A.

---

## 13. Файлы клиента (rishai) для сверки паритета — передать бэкенд-разработчику

Ниже пути **относительно корня репозитория** `rishai`. Их нужно открыть при реализации и **не выдумывать** поля JSON — сверять с парсером клиента.

| Файл | Зачем |
|------|--------|
| `lib/features/chat/data/remote_data_source/remote_data_source_impl.dart` | Метод **`requestMealPlanV2`**: параллельные вызовы LLM, подмена макросов на целевые, склейка `allMeals`, побочный вызов чата для 1-day. Метод **`replaceMealV2`**: регенерация слота. |
| `lib/features/chat/data/remote_data_source/llm_proxy_client.dart` | Модели **`LlmMealRequest`**, **`LlmMealDto`**, **`LlmRegenerateMealRequest`**, enum **`LlmMealRequestType`**, метод **`generateMeals`** / **`regenerateMeal`**, URL **`/llm-proxy-meal`**, чат **`/llm-proxy-chat`**. |
| `lib/features/chat/domain/usecases/request_plan_usecase.dart` | Класс **`RequestPlanParams`**, методы **`generateMealRequests`** / **`generateMealRequestsV2`**: какие запросы и в каком порядке формируются для 1-day vs week plan, тексты `message`, `diet`, типы блюд (`_formatMealType`). |
| `lib/features/chat/data/chat_repository_impl.dart` | Метод **`requestMealPlanV2`**: вызов remote, **`MealPlanEntity.fromMap`**, подстановка **`cycleId`** из `whoopBloc.state.day`. |
| `lib/features/chat/domain/entities/meal_plan_entity.dart` | **`MealPlanEntity.fromMap` / `toMap`**, **`Meal.fromMap` / `toMap`**, **`Ingredient.fromMap`**, **`MacrosBreakdown`** — канонический контракт JSON. |
| `lib/core/services/user_service/user_service_client.dart` | **`patchDaysCurrent`** (поле `mealPlan`), **`getCurrentDay`** — как клиент читает/пишет день после генерации. |
| `lib/core/services/directus/directus_collections.dart` | Константа **`weekPlanCollection`** → имя коллекции Directus **`weekPlans`**. |
| `lib/features/week_plan/domain/entities/week_plan_entity.dart` | **`WeekPlanEntity.fromMap` / `toMap`**, поля **`mealPlans`**, формат дат **`startDate`/`endDate`** (строки-миллисекунды). |
| `lib/features/chat/domain/usecases/generate_week_plan_usecase.dart` | **`GenerateWeekPlanUsecaseV2`**: цикл из **5** дней, **`excludedMeals`**, задержка 2 с, **`_completeIncompletePlansV2`**. |
| `lib/features/week_plan/presentation/bloc/week_plan_bloc.dart` | **`saveWeek`**: Hive + **`directus.createOne(collection: weekPlanCollection, data: week.toMap())`**; **`_syncAndLoadWeeks`**: **`directus.readMany`** по `userId`. |

Дополнительно (смежная доменная логика дня):

| Файл | Зачем |
|------|--------|
| `docs/backend/DAY_ENTITY_BACKEND_SPEC.md` | Контракт **`GET /days/current`**, поле **`mealPlan`** в ответе дня. |
| `lib/features/whoop/domain/entities/day_entity.dart` | Поле **`mealPlanEntity`**, **`DayEntity.fromMap`** — как план встраивается в день. |

---

*Версия документа: 1.0. Создано для передачи backend-команде и AI-агентам разработки сервера.*
