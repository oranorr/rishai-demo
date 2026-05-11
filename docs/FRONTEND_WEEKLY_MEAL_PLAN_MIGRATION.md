# Миграция недельного плана: с клиентского цикла на `tasks` (для фронтенда)

**Цель:** вместо цикла из 5× дневных генераций на устройстве + `directus.createOne(weekPlans)` — одна асинхронная задача на сервере: генерация/валидация/запись недели выполняются на бэке, клиент получает результат через поллинг `GET /tasks/:taskId`.

Полный контракт инфраструктуры: [TASKS_ASYNC_API_REFERENCE.md](TASKS_ASYNC_API_REFERENCE.md).

---

## 1. Предусловия и заголовки

- **`pivot-identity-key`** — как у всех User API.
- **`x-user-id`** — Directus id пользователя.
- `Content-Type: application/json` — для `POST /tasks/enqueue`.

---

## 2. Старт задачи: `POST /tasks/enqueue`

- **Код:** `202 Accepted`
- **Ответ:** `{ taskId, status }` (при идемпотентности — ещё `deduplicated: true`)

### Тело

```json
{
  "type": "weekly_meal_plan",
  "input": {
    "startDateMs": 0,
    "days": [
      { "dayIndex": 0, "requests": [] },
      { "dayIndex": 1, "requests": [] },
      { "dayIndex": 2, "requests": [] },
      { "dayIndex": 3, "requests": [] },
      { "dayIndex": 4, "requests": [] }
    ],
    "meta": {
      "dietary": ["string"],
      "cuisines": ["string"],
      "servings": ["Breakfast|Lunch|Dinner|Supper|Snack"]
    }
  },
  "idempotencyClientKey": "optional-uuid"
}
```

**Важно:** `days[].requests[]` — это сериализация текущих `LlmMealRequest.toJson()` (объекты совместимы с `LlmProxyMealRequestDto` бэка).

---

## 3. Поллинг: `GET /tasks/:taskId`

- **`pending|processing|done|failed`**
- при `done`: `output.weekPlanId`
- при `failed`: `error` (сообщение для UI)

Рекомендуемый интервал: 2–5s с backoff.

---

## 4. Что меняется на клиенте

- Клиент **перестаёт** выполнять 5× `RequestPlanUsecaseV2` синхронно и перестаёт писать `directus.createOne(weekPlans, ...)` после генерации.
- Клиент **продолжает** считать распределение макросов и строить `requests[]` (v1), но теперь отправляет их в `POST /tasks/enqueue`.

