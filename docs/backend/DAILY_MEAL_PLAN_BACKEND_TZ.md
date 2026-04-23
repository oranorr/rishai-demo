# ТЗ: перенос генерации плана питания на **один день** на бэкенд (Pivot)

**Версия:** 1.3  
**Скоуп:** только **дневной** план (`mealPlan` у текущего дня). **Недельные** планы (`weekPlans`), регенерация отдельного блюда (`replaceMealV2`) — **вне** этого документа.  
**Аудитория:** backend / AI-агент. Референс по паритету — Flutter-репозиторий `rishai`.

**Асинхронная инфраструктура (уже в коде pivot-backend):**  
см. репозиторий **`pivot-backend`**, файл **`docs/TASKS_ASYNC_API_REFERENCE.md`** (контракт **`POST /tasks/enqueue`**, **`POST /tasks/process`**, коллекция Directus **`tasks`**, Cloud Tasks, OIDC). Это ТЗ описывает **продуктовый сценарий** поверх этого каркаса.

---

## 1. Зачем

**Сейчас:** приложение вызывает **`POST /llm-proxy-meal`** до трёх раз **параллельно**, склеивает ответы, **подменяет** макросы блюд на целевые из запроса, парсит JSON, затем сохраняет день через **`PATCH /days/current`** (`mealPlan`, `chatSnap`, `welnessEntity`).

**Проблема:** обрыв сети или закрытие приложения во время сборки → план часто не доходит до БД, плохой UX.

**Цель:** оркестрация LLM, валидация и **запись `mealPlan`** выполняются **на сервере** в воркере **`POST /tasks/process`** (Cloud Tasks). Клиент вызывает **`POST /tasks/enqueue`** (202), дальше **поллит статус** через рекомендуемый **`GET /tasks/:id`** (§4.4) и при **`done`** подтягивает день через **`GET /days/current`** (источник правды для экрана дня — §4.4, §6).

---

## 2. Модель данных (только день)

- Коллекция **`days`** (Directus), текущий день пользователя.
- Поле **`mealPlan`**: JSON **одного** объекта в формате **`MealPlanEntity.toMap()`** (см. §6).
- **`cycleId`** внутри `mealPlan`: на клиенте подставляется из текущего дня (`whoopBloc.state.day.cycleId`). На бэкенде брать из **той же** загруженной сущности дня, что используется для `/days/current`, **не** из произвольного поля клиентского запроса (если не передаёте доверенный snapshot).

**Паритет с текущим сохранением после генерации в чате:**  
`DayManagerImpl.createOrUpdateDay` шлёт в **`PATCH /days/current`** три ключа: **`mealPlan`**, **`chatSnap`**, **`welnessEntity`**. При переносе генерации на сервер минимальный вариант — бэкенд пишет **только** обновлённый **`mealPlan`**, не затирая чат: **GET** текущего дня → слить новый `mealPlan` в объект дня → **PATCH** с прежними `chatSnap` / `welnessEntity` из ответа GET (или эквивалентная логика на сервисном слое). Иначе явно описать в контракте, что клиент после `job: completed` сам один раз патчит `chatSnap`.

---

## 3. Аутентификация

Как у существующих ручек User Service:

- Заголовок **`pivot-identity-key`**
- **`x-user-id`**: Directus id пользователя
- **`Content-Type: application/json`** для POST

---

## 4. API: универсальные задачи (факт) + сценарий «день»

Инфраструктура **уже реализована** в `pivot-backend` (детали, IAM, переменные окружения — в **`docs/TASKS_ASYNC_API_REFERENCE.md`**).

### 4.0 Публичный вход: **`POST /tasks/enqueue`**

| Аспект | Значение |
|--------|----------|
| Метод / путь | **`POST /tasks/enqueue`** |
| Ответ | **`202 Accepted`**, тело: **`taskId`** (UUID записи в Directus), **`status`**, опционально **`deduplicated`** |
| Заголовки | **`pivot-identity-key`**, **`x-user-id`** (обязателен), `Content-Type: application/json` |
| Тело (общее) | **`type`** — строка типа задачи; **`input`** — JSON (сохраняется в Directus целиком); опционально **`idempotencyClientKey`** |

**Идемпотентность:** сервер строит **`idempotency_key`** (например SHA-256); при повторном enqueue с тем же ключом и статусе **`pending`** / **`failed`** возможен **re-enqueue** в Cloud Tasks (см. референс бэкенда).

### 4.1 Воркер: **`POST /tasks/process`**

| Аспект | Значение |
|--------|----------|
| Вызывает | **только Cloud Tasks** с OIDC |
| Аутентификация | **`Authorization: Bearer <OIDC JWT>`**, audience **`CLOUD_TASKS_AUDIENCE`** (без `pivot-identity-key`) |
| Успех | **`200 OK`**, `{ ok: true, taskId }` |
| Идемпотентность | если задача уже **`done`** → **`{ skipped: true, taskId }`**, LLM не вызывается (важно при retry очереди на 5xx) |

URL воркера в очереди: **`{PUBLIC_API_BASE_URL}/tasks/process`** (очередь **`pivot-queue`**, регион **`us-central1`** — по текущему референсу).

### 4.2 Directus: коллекция **`tasks`** (не отдельная `meal_plan_jobs`)

Запись создаётся **до** постановки в Cloud Tasks. Поля и статусы (`pending` → `processing` → `done` / `failed`) — **как в** `TASKS_ASYNC_API_REFERENCE.md`.  
Продуктовый сценарий дневного плана хранит в **`input`** всё нужное для §6 (например массив **`requests`**).

### 4.3 Тип задачи для дневного плана

В коде добавить новый **`type`** (имя согласовать с `task-types.constants.ts`, условно **`daily_meal_plan`**). Сейчас в воркере реализован только **`echo`** — реализация **`daily_meal_plan`** = §6 этого ТЗ.

### 4.4 Статус задачи для клиента (обязательное решение для v1)

В **`TASKS_ASYNC_API_REFERENCE.md`** на момент написания **нет** публичного **`GET /tasks/:id`**. Для дневного плана **недостаточно** одного поллинга **`GET /days/current`**: пока воркер не записал день, день не меняется, и клиент **не отличит** «задача в очереди» от «задача упала» / «задача ещё не поставлена в Cloud Tasks».

#### 4.4.1 Рекомендуемый контракт: **`GET /tasks/:taskId`**

Добавить в User Service / `pivot-backend` **одну** лёгкую ручку под теми же заголовками, что **`POST /tasks/enqueue`**:

| Аспект | Значение |
|--------|----------|
| Метод / путь | **`GET /tasks/:taskId`** (`taskId` = UUID из ответа **enqueue**) |
| Заголовки | **`pivot-identity-key`**, **`x-user-id`** (обязателен) |
| Авторизация записи | отдавать задачу **только** если **`tasks.user_id`** совпадает с **`x-user-id`**; иначе **`404`** (не раскрывать чужие id) |
| Успех **`200`** | тело — срез полей, нужных клиенту (без лишнего `input`, если не нужен отладочный флаг): **`taskId`**, **`type`**, **`status`** (`pending` \| `processing` \| `done` \| `failed`), опционально **`deduplicated`**, при **`failed`** — **`error`** (код/сообщение для UI), при **`done`** — **`output`** (см. §4.4.4) |

**Поллинг UX:** разумный интервал (например 2–5 с) с backoff до таймаута; при **`failed`** показать ошибку и предложить повтор (**enqueue** с новым или тем же **`idempotencyClientKey`** — по политике §4.4.3). При **`done`** — один раз **`GET /days/current`** и обновить локальное состояние дня.

#### 4.4.2 Дополнение: поллинг **`GET /days/current`**

Имеет смысл **после** перехода в **`done`**: подтвердить, что **`mealPlan`** на дне совпадает с ожиданием (и не было гонки с другим клиентом). Для «ждём только план» основной индикатор прогресса — **`GET /tasks/:taskId`**, не смена дня.

#### 4.4.3 Запись в Directus **до** Cloud Tasks и «зависший» **`pending`**

По референсу запись **`tasks`** создаётся **до** постановки в очередь; если Cloud Tasks / IAM не сработали, задача может остаться **`pending`** без вызова воркера.

**Норма для клиента:** если долго **`pending`** (порог по продукту, напр. 30–60 с) и **`GET /days/current`** без нового плана — **повторить `POST /tasks/enqueue`** с тем же **`idempotencyClientKey`**: на бэкенде сработает **re-enqueue** (см. референс для статусов **`pending`** / **`failed`**). Не спамить: backoff между повторами.

#### 4.4.4 Поле **`tasks.output` и `mealPlan`**

**Да — в `output` должен попадать итоговый `mealPlan`** (тот же JSON, что уходит в **`days.mealPlan`**: корень **`{ "meals": [...], "cycleId": ... }`**, формат §7), после успешной **валидации** и **успешного `PATCH /days/current`** (см. §6).

- **Зачем клиенту:** лёгкий превью/отладка, возможность показать план из ответа статуса без второго запроса к дню (опционально); главное — **явная связка** «задача завершена» ↔ «вот результат».
- **Источник правды для приложения:** по-прежнему **`GET /days/current`** после **`done`** — один экран с днём, один контракт с остальным приложением; **`output.mealPlan`** должен **совпадать** с записанным в дне (или запись в день — часть одной бизнес-операции «успех», иначе задача не **`done`**).

Прямой доступ мобильного клиента к коллекции **`tasks`** в Directus **не** считается целевым решением (права, утечки схемы, обход бизнес-правил).

### 4.5 Обратная совместимость

Эндпоинт **`POST /llm-proxy-meal`** **не удалять** до перевода всех клиентов: старые билды продолжают работать. Новый путь — для обновлённого приложения.

---

## 5. Тело **`POST /tasks/enqueue`** для дневного плана

Клиент сегодня строит **`List<LlmMealRequest>`** в **`RequestPlanParams.generateMealRequests()`** при **`isWeekPlan: false`** (исключения — **`DayEntity.getMealHistory(days)`**). Это же можно положить в **`input.requests`** после сериализации на клиенте.

**Минимальный контракт (вариант A — зеркало клиента):** в **`input`** лежит массив **`requests`**, идентичный трём вызовам `llm-proxy-meal` (см. `LlmMealRequest.toJson()` в Flutter).

Пример тела **`POST /tasks/enqueue`** (имя **`type`** согласовать в константах бэкенда, ниже — условное **`daily_meal_plan`**):

```json
{
  "type": "daily_meal_plan",
  "input": {
    "requests": [
      {
        "type": "breakfast",
        "message": "string",
        "diet": "keto | carnivore | all",
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
    ]
  },
  "idempotencyClientKey": "optional-uuid-from-client"
}
```

- Элементы **`requests`**: только те типы, которые реально нужны (пустые группы не слать).
- **Вариант B (второй этап):** вместо готовых `message` передавать «сырьё» и воспроизводить `generateMealRequests()` на сервере — для v1 проще **вариант A**.

---

## 6. Алгоритм воркера **`POST /tasks/process`** (тип `daily_meal_plan`, паритет с `requestMealPlanV2`)

В **`task-execution.service.ts`** (или аналоге) для **`type === 'daily_meal_plan'`** читать **`input.requests`**. Дальше:

1. **Параллельно** (как `Future.wait` на клиенте) вызвать внутреннюю реализацию, эквивалентную **`POST /llm-proxy-meal`** для каждого элемента `requests`. Ретраи при 502/таймаутах — как в **`LlmProxyClient.generateMeals`** (на клиенте до 3 попыток).
2. Сохранить **порядок** склейки `meals`: тот же, что порядок обхода успешных ответов в **порядке массива `requests`** (сначала все блюда из breakfast-запроса, затем meal, затем snack) — см. цикл в **`remote_data_source_impl.requestMealPlanV2`**.
3. **Подмена макросов:** для каждого типа запроса для i-го блюда в ответе подставить **`macros`** из i-го **`LlmMealDto`** в соответствующем `request.meals` (поля `kcal`, `protein`, `carbs`, `fat`).
4. **Валидация:** каждый элемент `meals[]` должен удовлетворять §7; иначе запись **`tasks`** → **`failed`** (и осмысленный **`error`**), в **`days.mealPlan`** не писать частичный мусор (если не включена явная политика partial success).
5. Собрать **`mealPlan`** = **`{ "meals": [...], "cycleId": <int|null> }`** (`cycleId` с текущего дня пользователя).
6. **Запись и финализация задачи (порядок важен):**
   - **6a.** См. §2: merge с существующим днём → **`PATCH /days/current`** с новым **`mealPlan`**, не затирая **`chatSnap`** / **`welnessEntity`**.
   - **6b.** Только если **PATCH** успешен: выставить **`tasks.status = done`**, записать **`tasks.output`** = **`{ "mealPlan": <тот же объект> }`** (дополнительные ключи в `output` — по необходимости, но **`mealPlan`** обязателен для типа **`daily_meal_plan`**).
   - Если **PATCH** не удался после валидного плана: **`tasks.status = failed`**, **`error`** с причиной, **`days`** не менять частично «левым» планом; при повторной доставке Cloud Tasks идемпотентность по **`done`** не сработала — воркер может **повторить** PATCH или вернуть **5xx** по политике ретраев (§8).
7. **Побочный эффект «чат»** (сейчас только для однодневного плана, `!isWeekPlan`): после успешной сборки клиент вызывает **`/llm-proxy-chat`** с промптом `{'meals': ...}`. Варианты: **(а)** повторить на сервере fire-and-forget после шага 6a; **(б)** оставить на mobile после **`GET /days/current`**. **Рекомендация для v1:** **(а)** на сервере сразу после успешного PATCH — **паритет** со старым клиентским потоком и меньше рассинхрона «план есть, чат пустой»; **(б)** допустимо, если сознательно урезаете скоуп бэка и готовы обновить Flutter в том же релизе.

### 6.1 Два уровня ретраев (Cloud Tasks и LLM внутри воркера)

- **Внутри одного вызова `process`:** ретраи отдельных вызовов к **`llm-proxy-meal`** (как **`LlmProxyClient`**, до нескольких попыток на транзиенты) — **оставляем**; это снижает шум **5xx** наружу.
- **Повторная доставка всего `process`:** при **5xx** после части работы Cloud Tasks вызовет воркер снова. Идемпотентность **`done` → skipped** защищает от **повторного LLM** после успеха. Если воркер упал **до** **`done`** (например после части LLM, но до PATCH), повторный прогон **может снова вызвать LLM** — для **v1 это приемлемо** (проще, чем кэшировать частичные ответы в **`tasks`**). Улучшение «этап 2»: сохранять сырые ответы LLM во временное поле и дочитывать при retry.

---

## 7. JSON `mealPlan` (совместимость с Flutter)

Парсинг: **`MealPlanEntity.fromMap`** → **`Meal.fromMap`**.

Каждый элемент **`meals[]`**:

| Поле | Тип |
|------|-----|
| `title` | string |
| `type` | string (должен проходить эвристику `Meal.servingType`: Breakfast, Lunch, …) |
| `description` | string |
| `macros` | `{ "kcal", "protein", "carbs", "fat" }` |
| `ingredients` | array (новый формат с `name`/`quantity`/`unit` или legacy `title`/`amount` — см. **`Ingredient.fromMap`**) |
| `cooking_instructions` | array of string |
| `isRegenerated` | bool, по умолчанию `false` |

Корень **`mealPlan`:** `{ "meals": [...], "cycleId": ... }`.

---

## 8. Ошибки

- **`POST /tasks/enqueue`:** как принято в User Service (`{ "success": false, "error": { "code", "message" } }` при ошибках). **`202`** при успешной постановке.
- **`POST /tasks/process`:** при **5xx** Cloud Tasks **повторит** доставку (см. `TASKS_ASYNC_API_REFERENCE.md`); идемпотентность на стороне воркера обязательна (**`done`** → `skipped`), иначе LLM вызовут повторно.
- **`GET /tasks/:taskId`:** **`401`** без ключа / пользователя; **`404`** — нет задачи или не тот **`x-user-id`**; **`200`** — см. §4.4.1.

Примеры: `400` валидация, `401` на enqueue без ключа, OIDC-ошибки на `process`.

---

## 9. Критерии приёмки

1. Для эквивалентного **`input.requests`** итоговый **`mealPlan`** в БД совпадает по структуре и порядку блюд с текущим клиентским пайплайном; макросы слотов = целевые из `requests`.
2. После **`GET /tasks/:taskId`** со статусом **`done`**: **`GET /days/current`** отдаёт тот же **`mealPlan`**, что в **`tasks.output.mealPlan`** (§4.4.4, §6).
3. **`GET /tasks/:taskId`** для чужого пользователя / несуществующего id — **`404`**; поллинг статуса работает для сценариев **`pending`** / **`failed`** / **`done`**.
4. Закрытие приложения после **`POST /tasks/enqueue`** не отменяет выполнение: Cloud Tasks доводит **`POST /tasks/process`** (с учётом ретраев и идемпотентности).
5. Старый клиент, вызывающий только **`llm-proxy-meal`**, продолжает работать до отдельного deprecation.
6. Тип **`daily_meal_plan`** задокументирован (расширение `TASKS_ASYNC_API_REFERENCE.md` или отдельный фрагмент) + тест с моком LLM на запись в Directus; контракт **`GET /tasks/:taskId`** описан там же или в этом ТЗ со ссылкой на имплементацию.

---

## 10. Вне скоупа (следующие тикеты)

- Недельный план (`weekPlans`, пять дней, `GenerateWeekPlanUsecaseV2`).
- Регенерация одного блюда (`replaceMealV2` / `LlmRegenerateMealRequest`).
- Перевод мобильного приложения на **`POST /tasks/enqueue`** + поллинг **`GET /tasks/:taskId`** + **`GET /days/current`** после **`done`** (отдельный PR после стабилизации API).

---

*Документ согласован с обсуждением: поэтапно сначала день, затем неделя; статусы в Directus **`tasks`**; публичный **`GET /tasks/:taskId`** для клиента; Cloud Tasks + **`/tasks/process`**; обратная совместимость со старым прокси.*

---

## 11. Референсные файлы

### 11.1 Репозиторий **`pivot-backend`**

| Путь | Зачем |
|------|--------|
| `docs/TASKS_ASYNC_API_REFERENCE.md` | Актуальный контракт **`/tasks/enqueue`**, **`/tasks/process`**, Directus **`tasks`**, OIDC, очередь. После имплементации §4.4 — дополнить **`GET /tasks/:taskId`**. |

### 11.2 Flutter **`rishai`** (паритет генерации)

Пути относительно корня репозитория `rishai`.

| Путь | Зачем |
|------|--------|
| `lib/features/chat/data/remote_data_source/remote_data_source_impl.dart` | **`requestMealPlanV2`**: параллельные вызовы, подмена макросов, склейка `allMeals`, вызов чата для одного дня. |
| `lib/features/chat/data/remote_data_source/llm_proxy_client.dart` | **`LlmMealRequest`**, **`LlmMealDto`**, **`generateMeals`** → **`POST /llm-proxy-meal`**; ретраи; чат **`/llm-proxy-chat`**. |
| `lib/features/chat/domain/usecases/request_plan_usecase.dart` | **`RequestPlanParams`**, **`generateMealRequests()`**: распределение КБЖУ, тексты **`message`**, **`diet`**, группировка слотов; при **`isWeekPlan: false`** — **`DayEntity.getMealHistory`**. |
| `lib/features/chat/data/chat_repository_impl.dart` | **`requestMealPlanV2`**: вызов remote, **`MealPlanEntity.fromMap`**, **`cycleId`**. |
| `lib/features/chat/domain/entities/meal_plan_entity.dart` | **`MealPlanEntity`**, **`Meal`**, **`Ingredient`**, **`MacrosBreakdown`** — контракт JSON. |
| `lib/features/chat/domain/entities/chat_snapshot_entity.dart` | **`ChatSnapshotEntity.toDirectus()`** — формат **`chatSnap`** в PATCH. |
| `lib/core/services/user_service/user_service_client.dart` | **`getCurrentDay`**, **`patchDaysCurrent`**. |
| `lib/core/services/day_manager/day_manager_impl.dart` | **`createOrUpdateDay`**: состав **`payload`** для PATCH (`mealPlan`, `chatSnap`, `welnessEntity`). |
| `lib/features/whoop/domain/entities/day_entity.dart` | **`DayEntity.fromMap`**, **`getMealHistory`**. |
| `lib/features/chat/presentation/bloc/chat_bloc.dart` | **`_createMealPlan`**: откуда берутся макросы дня, **`isWeekPlan: false`**, цепочка сохранения. |
| `docs/backend/DAY_ENTITY_BACKEND_SPEC.md` | Контракт **`GET /days/current`** и полей дня. |
