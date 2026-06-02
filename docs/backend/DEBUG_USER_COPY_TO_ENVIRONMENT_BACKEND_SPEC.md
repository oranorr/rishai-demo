# ТЗ: копирование пользователя из production в staging (debug)

**Версия:** 1.0  
**Дата:** 25.05.2026  
**Аудитория:** Backend developer  
**Контекст:** QA и разработка часто воспроизводят баги на реальных prod-данных. Сейчас для этого нужен ручной доступ к Directus или отдельные скрипты. Цель — одна защищённая ручка на **production** Pivot Backend: залогиненный пользователь нажимает кнопку в приложении → его профиль и связанные данные копируются в **staging**.

Связанные документы:
- `docs/backend/FRONTEND_AUTH_AND_OTP.md` — JWT, `/users/me`
- `docs/backend/DAY_ENTITY_BACKEND_SPEC.md` — модель `days`
- `docs/backend/WEEKLY_MEAL_PLAN_BACKEND_TZ.md` — модель `weekPlans`
- `docs/backend/WHOOP_SERVICE_SPEC.md` — WHOOP-токены на пользователе
- `docs/backend/PUBLIC_CONFIG_WHITELIST_FEEDBACK_DEBUG_BACKEND_SPEC.md` — паттерн debug-ручек (`POST /debug/days/seed-history`)

---

## 1. Цели

1. Реализовать **одностороннее** копирование: **production → staging** (обратное направление **не** требуется в v1).
2. Источник пользователя — **JWT `sub`** (только «себя», без копирования чужих аккаунтов).
3. Скопировать **минимально достаточный** набор данных, чтобы приложение на staging вело себя как на prod после логина тем же email.
4. Ручка **недоступна** на staging/production без явного флага окружения и allowlist.
5. Задокументировать контракт для Flutter-клиента (кнопка в debug/internal UI).

---

## 2. Сценарий использования

```text
1. Сборка приложения с base URL = production Pivot Backend.
2. Пользователь (из internal allowlist) логинится через OTP/OAuth.
3. В debug-меню нажимает «Copy my data to staging».
4. Клиент: POST /debug/users/copy-to-staging с Authorization: Bearer <access>.
5. Prod backend читает данные из prod Directus, пишет в staging Directus.
6. Ответ содержит staging userId — QA переключает приложение на staging и логинится тем же email.
```

**Важно:** клиент **не** может выполнить копирование сам — у него нет доступа к обеим базам. Вся cross-env логика — **только на бэкенде**.

---

## 3. Архитектура

```text
┌─────────────┐     JWT      ┌──────────────────────┐
│ Flutter app │ ───────────► │ Prod Pivot Backend   │
│ (prod URL)  │              │ POST /debug/users/…  │
└─────────────┘              └──────────┬───────────┘
                                        │
                          read          │          write
                            ▼           │           ▼
                   ┌────────────┐       │    ┌────────────┐
                   │ Prod       │       │    │ Staging    │
                   │ Directus   │       └──► │ Directus   │
                   └────────────┘            └────────────┘
```

### 3.1 Где живёт ручка

| Окружение Pivot Backend | Ручка |
|-------------------------|-------|
| **Production**          | ✅ `POST /debug/users/copy-to-staging` |
| Staging                 | ❌ **404 или 403 всегда** (даже с валидным JWT) |
| Local dev               | ✅ опционально, если настроены оба Directus |

### 3.2 Доступ к staging Directus

Рекомендуемый вариант v1: **service token staging Directus** в env production-бэкенда:

| Env | Описание |
|-----|----------|
| `STAGING_DIRECTUS_URL` | Base URL staging Directus |
| `STAGING_DIRECTUS_TOKEN` | Static token / service account с правами create/update/delete на `users`, `days`, `weekPlans` |

Альтернатива (v2): prod backend вызывает **internal** endpoint staging Pivot (`POST /internal/users/import`), если не хотите давать prod доступ к Directus напрямую. В v1 достаточно Directus token.

---

## 4. API

Базовый URL — production Pivot Backend (тот же, что у `UserServiceClient._productionBaseUrl`).

### 4.1 `POST /debug/users/copy-to-staging`

**Назначение:** скопировать текущего пользователя (по JWT) и связанные сущности в staging.

#### Авторизация

| Требование | Обязательность |
|------------|----------------|
| `Authorization: Bearer <access_token>` | **да** |
| `pivot-identity-key` | **нет** (JWT достаточно) |
| `x-user-id` | **нет** (id из `sub`) |

Дополнительные проверки на сервере:

1. `NODE_ENV` / `APP_ENV` = `production` (или явный `ENABLE_DEBUG_USER_COPY=true`).
2. Email пользователя ∈ allowlist (см. раздел 7).
3. Rate limit: **не чаще 1 раза в 5 минут** на пару `(sourceUserId, targetEnvironment)`.

#### Тело запроса (JSON)

Все поля опциональны; defaults указаны ниже.

```json
{
  "overwrite": false,
  "includeWhoopTokens": true,
  "includeWeekPlans": true,
  "includeDays": true,
  "daysLimit": null
}
```

| Поле | Тип | Default | Описание |
|------|-----|---------|----------|
| `overwrite` | boolean | `false` | Если `true` — перед копированием **удалить** на staging все `days` и `weekPlans` пользователя с тем же email (профиль обновить, не удалять аккаунт целиком). |
| `includeWhoopTokens` | boolean | `true` | Копировать `whoopRefreshToken`, `whoopAccessToken`, `whoopTokenExpiresAt`, `lastSuccessfulSync`, `whoopId`. |
| `includeWeekPlans` | boolean | `true` | Копировать коллекцию `weekPlans`. |
| `includeDays` | boolean | `true` | Копировать коллекцию `days`. |
| `daysLimit` | int \| null | `null` | Если число — копировать только **N самых свежих** дней (sort `dateTime desc`). `null` = все дни пользователя. Max **500** (hard cap на бэке). |

#### Успешный ответ `200 OK`

Формат согласован с остальным API (`success` + `data`, см. `UserServiceClient.unwrapResponseData`):

```json
{
  "success": true,
  "data": {
    "sourceUserId": "a1b2c3",
    "sourceEmail": "qa@example.com",
    "targetUserId": "x9y8z7",
    "targetEnvironment": "staging",
    "overwriteApplied": false,
    "copied": {
      "userProfile": true,
      "whoopTokens": true,
      "weekPlans": {
        "created": 2,
        "updated": 1,
        "skipped": 0
      },
      "days": {
        "created": 187,
        "updated": 0,
        "skipped": 0
      }
    },
    "weekPlanIdMap": {
      "6": "14",
      "8": "15"
    },
    "durationMs": 4523
  }
}
```

| Поле | Описание |
|------|----------|
| `targetUserId` | Directus user id **на staging** (новый или существующий по email). |
| `weekPlanIdMap` | Маппинг prod `weekPlans.id` → staging `weekPlans.id` (строки). Нужен клиенту для отладки; на staging в профиле уже должны быть **новые** id в `weekPlanIds`. |
| `durationMs` | Время операции (для мониторинга). |

#### Коды ошибок

| HTTP | `error.code` | Ситуация |
|------|--------------|----------|
| 400 | `INVALID_REQUEST` | Невалидное тело, `daysLimit` > 500 или < 1 |
| 401 | `UNAUTHORIZED` | Нет/протухший access JWT |
| 403 | `FORBIDDEN` | Ручка выключена, email не в allowlist, вызов не с production |
| 404 | `USER_NOT_FOUND` | Пользователь из JWT не найден в prod Directus |
| 409 | `COPY_IN_PROGRESS` | Параллельный запрос для того же user (distributed lock) |
| 429 | `RATE_LIMITED` | Повтор раньше чем через 5 минут |
| 502 | `STAGING_DIRECTUS_ERROR` | Staging Directus недоступен или вернул ошибку |
| 503 | `COPY_DISABLED` | Не заданы `STAGING_DIRECTUS_*` env |

Стандартный формат ошибки — как в `FRONTEND_AUTH_AND_OTP.md` §7:

```json
{
  "success": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "Debug user copy is not enabled for this account"
  }
}
```

---

## 5. Данные для копирования

### 5.1 Коллекции Directus

| Коллекция | Копировать | Ключ upsert на staging |
|-----------|------------|-------------------------|
| `users` (или эквивалент профиля) | ✅ | **email** (unique) |
| `weekPlans` | ✅ (если `includeWeekPlans`) | `(userId, startDate)` |
| `days` | ✅ (если `includeDays`) | `(userId, dateTime)` |

Имена коллекций сверить с админкой; во Flutter/API используются пути `/users`, `/week-plans`, `/days`.

### 5.2 Поля пользователя (`users`)

**Копировать** (pass-through из prod, с remap где указано):

| Поле | Примечание |
|------|------------|
| `email` | ключ поиска на staging |
| `name` | |
| `age`, `gender` | |
| `bodyMeasurements` | JSON |
| `foodPreferences` / flat `diets`, `cuisines`, `restrictions` | как хранится в Directus |
| `userGoal` | `goalType`, `modificator`, `updatedAt` |
| `pivotLifeScore` | JSON |
| `weekPlanIds` | **remap** через `weekPlanIdMap` после копирования планов |
| `whoopId` | если `includeWhoopTokens` |
| `whoopRefreshToken` | если `includeWhoopTokens` |
| `whoopAccessToken` | если `includeWhoopTokens` |
| `whoopTokenExpiresAt` | если `includeWhoopTokens` |
| `lastSuccessfulSync` | если `includeWhoopTokens` |

**Не копировать** (явно обнулить / не передавать):

| Поле | Причина |
|------|---------|
| `id` | на staging будет свой PK |
| `adaptyId` | привязка к store / Adapty sandbox vs prod |
| Firebase / auth provider ids | если есть отдельные поля — staging auth создаёт свои |
| `password`, OTP hashes | не трогать staging credentials |

Если пользователя с таким **email на staging нет** — **создать** запись (минимальный профиль + скопированные поля). Если есть — **update** существующего (merge по правилам overwrite).

### 5.3 Недельные планы (`weekPlans`)

Поля по контракту Flutter `WeekPlanEntity.fromMap()` / `docs/backend/WEEKLY_MEAL_PLAN_BACKEND_TZ.md` §3.1:

| Поле | Примечание |
|------|------------|
| `userId` | **staging** `targetUserId` |
| `startDate`, `endDate` | string ms epoch |
| `mealPlans` | JSON array (5 дней) |
| `fitnessGoal`, `dietaryPreferences` | |
| `cuisines`, `mealsTypes` | arrays |

**Не копировать:** `id` (новый на staging).  
После insert/update сохранить маппинг `prodId → stagingId` для `weekPlanIds` пользователя.

**Upsert:** найти на staging по `userId + startDate`. Если найден и `overwrite=false` — **update** содержимое; если `overwrite=true` — предварительно удалены все планы пользователя (см. алгоритм).

### 5.4 Дни (`days`)

Поля по `docs/backend/DAY_ENTITY_BACKEND_SPEC.md` §6:

| Поле | Примечание |
|------|------------|
| `userId` | **staging** `targetUserId` |
| `dateTime` | string ms epoch (**как на prod**) |
| `weekTdeeAverage` | |
| `macros`, `healthMetrics` | JSON |
| `cycleId` | string |
| `mealPlan`, `chatSnap`, `welnessEntity` | JSON as-is |

**Не копировать:** `id`.

**Upsert:** `(userId, dateTime)` — при совпадении **replace** JSON-полей (full document replace, не partial merge v1).

**Пагинация чтения с prod:** batch по 100 записей, sort `dateTime desc`, пока не исчерпаны или не достигнут `daysLimit`.

### 5.5 WHOOP

При `includeWhoopTokens: true` копировать токены **как есть**. WHOOP OAuth один на prod API (`api.prod.whoop.com`); refresh token должен работать и при запросах со staging backend (проверить на QA).

Если refresh на staging не работает (политика WHOOP / revoked) — копирование профиля и дней всё равно считается успешным; в ответе `copied.whoopTokens: false` + warning в логах (не error).

### 5.6 Что **не** входит в v1

| Данные | Комментарий |
|--------|-------------|
| Cloud Tasks / `/tasks/*` | очереди не переносятся |
| Feedback, OTP codes | не нужны для воспроизведения UX |
| Adapty subscription state | отдельная sandbox-подписка на staging |
| OpenAI / LLM thread history вне `days.chatSnap` | только то, что уже в `chatSnap` |
| Файлы Directus (`directus_files`) | нет file fields в scope |
| App config / whitelist | окружения и так разные |

---

## 6. Алгоритм (пошагово)

```text
1. GUARD
   - Проверить ENABLE_DEBUG_USER_COPY и production env.
   - Распарсить JWT → sourceUserId, email.
   - Проверить email ∈ allowlist.
   - Acquire lock (sourceUserId, TTL ~10 min). Иначе 409.

2. LOAD SOURCE (prod Directus)
   - user by sourceUserId
   - weekPlans: all for userId (if includeWeekPlans)
   - days: paginated (if includeDays), apply daysLimit

3. RESOLVE TARGET USER (staging Directus)
   - FIND user WHERE email = source.email
   - IF NOT FOUND → CREATE minimal user
   - targetUserId = staging user.id

4. OVERWRITE (if overwrite=true)
   - DELETE staging days WHERE userId = targetUserId
   - DELETE staging weekPlans WHERE userId = targetUserId

5. COPY WEEK PLANS (if includeWeekPlans)
   - FOR EACH plan (sort startDate asc):
       upsert on staging by (targetUserId, startDate)
       record weekPlanIdMap[prodId] = stagingId

6. COPY USER PROFILE
   - Build payload from prod user
   - Remap weekPlanIds through weekPlanIdMap
   - Apply includeWhoopTokens filter
   - Strip forbidden fields (§5.2)
   - UPDATE staging user targetUserId

7. COPY DAYS (if includeDays)
   - FOR EACH day batch:
       SET userId = targetUserId, DROP id
       upsert by (targetUserId, dateTime)
       increment created/updated/skipped counters

8. RELEASE LOCK
   - Return 200 + summary

9. AUDIT LOG (structured)
   - sourceUserId, targetUserId, email, counts, durationMs, requestId
```

### 6.1 Идемпотентность

| `overwrite` | Повторный вызов |
|-------------|-----------------|
| `false` | Upsert: существующие days/plans **обновляются**, новые **добавляются**. Дубликатов по `(userId, dateTime)` быть не должно. |
| `true` | Staging data пользователя **сначала очищается**, затем полная копия с prod. |

Рекомендация для QA: первый раз `overwrite: false`, при «сломанном» staging — `overwrite: true`.

### 6.2 Транзакции

Directus не гарантирует cross-collection transaction в v1. Допустимо:

- week plans → user profile → days (порядок выше).
- При падении на шаге 7 — вернуть **502** с partial `copied` в теле ошибки (optional) или откатить через compensating deletes (optional v1.1).

Минимум v1: best-effort + подробный log; клиент показывает «частично скопировано» по counters.

---

## 7. Безопасность

### 7.1 Env-переменные (production backend)

| Переменная | Обязательность | Описание |
|------------|----------------|----------|
| `ENABLE_DEBUG_USER_COPY` | да | `true` только там, где ручка разрешена |
| `DEBUG_USER_COPY_ALLOWED_EMAILS` | да* | CSV emails, например `qa@rish.ai,dev@rish.ai` |
| `STAGING_DIRECTUS_URL` | да | |
| `STAGING_DIRECTUS_TOKEN` | да | service token, **не** логировать |
| `DEBUG_USER_COPY_RATE_LIMIT_SEC` | нет | default `300` |

\* Альтернатива: переиспользовать коллекцию `accountsWhiteList` из Directus (как для регистрации). Зафиксировать один источник в OpenAPI.

### 7.2 Жёсткие запреты

- ❌ Не регистрировать симметричную ручку `copy-to-production`.
- ❌ Не принимать `sourceUserId` / `email` в теле запроса — **только JWT `sub`**.
- ❌ Не включать ручку на публичном staging без IP allowlist (лучше — не включать вообще).
- ❌ Не возвращать в ответе `whoopRefreshToken` / секреты (только факт `whoopTokens: true/false`).

### 7.3 Observability

- Structured log: `[debug.user-copy]` + `requestId`.
- Metric: `debug_user_copy_total`, `debug_user_copy_duration_ms`, `debug_user_copy_errors`.
- Sentry: только ошибки 5xx, без PII в message.

---

## 8. Контракт для Flutter (после реализации)

Клиент добавит (отдельная задача):

```dart
// UserServiceClient — вызов только когда _baseUrl = production
Future<DebugUserCopyResult> copyCurrentUserToStaging({
  bool overwrite = false,
  bool includeWhoopTokens = true,
  int? daysLimit,
});
```

- UI: кнопка только при `kDebugMode` **или** email ∈ local feature flag.
- После успеха: snackbar «Скопировано на staging. userId: …».
- Переключение на staging — **ручное** (смена base URL / flavor); автologin на staging JWT **не** выдаётся этой ручкой.

---

## 9. Критерии приёмки

1. `POST /debug/users/copy-to-staging` на **production** с валидным JWT allowlisted-пользователя возвращает `200` и `targetUserId`.
2. На staging после копирования тот же email видит:
   - совпадающий профиль (goal, preferences, body measurements);
   - те же week plans (по `startDate`);
   - те же days (по `dateTime`), включая `welnessEntity` / `mealPlan` / `chatSnap`.
3. `weekPlanIds` на staging user указывают на **staging** ids, не prod.
4. Повторный вызов с `overwrite: false` не создаёт дубликатов days.
5. Вызов с `overwrite: true` удаляет старые days/plans на staging и заменяет актуальными с prod.
6. Запрос без JWT → `401`; email не из allowlist → `403`; вызов на staging backend → `403/404`.
7. Rate limit → `429` при повторе < 5 мин.
8. OpenAPI / internal doc с примером curl.

### 9.1 Пример curl (production)

```bash
curl -sS -X POST \
  'https://pivot-backend-production-676768388165.us-central1.run.app/debug/users/copy-to-staging' \
  -H 'Authorization: Bearer <ACCESS_TOKEN>' \
  -H 'Content-Type: application/json' \
  -d '{"overwrite":false,"includeWhoopTokens":true,"daysLimit":null}'
```

---

## 10. Чек-лист для разработчика

- [ ] Feature flag `ENABLE_DEBUG_USER_COPY`
- [ ] Allowlist emails
- [ ] Staging Directus client (read/write)
- [ ] JWT → source user load
- [ ] Target user resolve by email
- [ ] Week plans copy + id map
- [ ] User profile copy + weekPlanIds remap
- [ ] Days batch copy + upsert
- [ ] WHOOP tokens optional copy
- [ ] Overwrite mode (delete staging days/plans)
- [ ] Rate limit + distributed lock
- [ ] Audit logging
- [ ] OpenAPI
- [ ] Ручка **отключена** на staging deployment

---

## 11. Возможные расширения (v2, вне scope)

- `GET /debug/users/copy-to-staging/status` — async job для пользователей с >500 days.
- Copy prod → **local dev** Directus.
- Selective copy: только последние 30 days + current week plan.
- Выдача одноразового deep link для автологина на staging (без передачи refresh token клиенту).
