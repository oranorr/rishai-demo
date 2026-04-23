# Техническое задание: WHOOP Service на бэкенде

**Версия:** 1.0  
**Дата:** 17.03.2025  
**Цель:** Перенос полной работы с WHOOP API и токенами на бэкенд. Подготовка к созданию сущности дня на бэкенде.

---

## 1. Обзор

### 1.1 Текущая архитектура (клиент)

- **Flutter-приложение** самостоятельно:
  - выполняет OAuth flow с WHOOP;
  - хранит access/refresh токены (SharedPreferences + синхронизация в User Service);
  - обновляет токены по расписанию;
  - вызывает WHOOP Data API для получения cycles, body, sleep, recovery, workouts;
  - рассчитывает macros, TDEE, health metrics;
  - создаёт/обновляет дни в Directus.

### 1.2 Целевая архитектура

- **Бэкенд (Pivot)**:
  - управляет OAuth flow (инициирует, принимает callback);
  - хранит и обновляет токены;
  - проксирует запросы к WHOOP Data API;
  - в будущем: создаёт сущность дня, рассчитывает macros, пишет в Directus.

- **Клиент**:
  - вызывает бэкенд для connect/disconnect WHOOP;
  - получает данные дня одной ручкой (будущий этап).

---

## 2. WHOOP API — учётные данные

### 2.1 OAuth credentials

| Параметр | Описание | Где хранить |
|----------|----------|-------------|
| `client_id` | WHOOP OAuth Client ID | Env бэкенда |
| `client_secret` | WHOOP OAuth Client Secret | Env бэкенда (секретно) |

**Важно:** Сейчас `client_id` и `client_secret` хранятся в `.env` приложения (Envied). Бэкенд должен получить эти значения и хранить их в переменных окружения.

### 2.2 Redirect URI

- **Production:** `com.rishai://redirect` (custom URL scheme приложения)
- **Staging:** аналогично 

Для OAuth на бэкенде потребуется:
- либо **Universal Link / App Link** (HTTPS), который редиректит в приложение;
- либо **веб-страница** на бэкенде, которая после успешной авторизации редиректит в `com.rishai://redirect?code=...` (или передаёт code иным способом).

---

## 3. OAuth Flow

### 3.1 Текущий flow (клиент)

1. Пользователь нажимает «Connect WHOOP».
2. Открывается `FlutterWebAuth2` с URL:
   ```
   https://api.prod.whoop.com/oauth/oauth2/auth
     ?response_type=code
     &client_id={client_id}
     &redirect_uri=com.rishai://redirect
     &scope=read:recovery read:cycles read:sleep read:workout read:profile read:body_measurement offline
     &state=secureRandomState
   ```
3. Пользователь логинится в WHOOP, даёт разрешения.
4. WHOOP редиректит на `com.rishai://redirect?code=...&state=...`.
5. Приложение извлекает `code`, делает POST на `https://api.prod.whoop.com/oauth/oauth2/token`:
   ```
   Content-Type: application/x-www-form-urlencoded
   grant_type=authorization_code
   code={code}
   redirect_uri=com.rishai://redirect
   client_id={client_id}
   client_secret={client_secret}
   state=randomGeneratedState
   ```
6. Ответ WHOOP:
   ```json
   {
     "access_token": "...",
     "refresh_token": "...",
     "expires_in": 3600,
     "token_type": "Bearer"
   }
   ```
7. Токены сохраняются локально и отправляются на бэкенд (`updateUser` с `whoopRefreshToken`).

### 3.2 Scopes

```
read:recovery
read:cycles
read:sleep
read:workout
read:profile
read:body_measurement
offline
```

---

## 4. Token Management

### 4.1 Хранение на бэкенде

Рекомендуемая модель (привязана к пользователю):

| Поле | Тип | Описание |
|------|-----|----------|
| `whoopRefreshToken` | string \| null | Refresh token (долгоживущий) |
| `whoopAccessToken` | string \| null | Текущий access token (опционально, для кэша) |
| `whoopTokenExpiresAt` | datetime \| null | Время истечения access token |
| `lastSuccessfulSync` | number (ms) \| null | Время последней успешной синхронизации |

**Текущее состояние:** User Service уже принимает `whoopRefreshToken` и `lastSuccessfulSync` через `PUT /users/:id`. Бэкенд должен расширить хранение и логику.

### 4.2 Refresh Token Flow

WHOOP endpoint: `POST https://api.prod.whoop.com/oauth/oauth2/token`

```
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token
refresh_token={refresh_token}
client_id={client_id}
client_secret={client_secret}
scope=offline
```

Ответ: тот же формат, что и при authorization_code.

### 4.3 Логика обновления токена

- Access token живёт **1 час** (`expires_in: 3600` в ответе WHOOP).
- Обновлять за **1–2 минуты до истечения** (при 1 час токене — примерно каждые 58 минут).
- При любом запросе к WHOOP Data API: если токен истёк или истекает в течение 2 минут — сначала refresh.
- Retry: до 3 попыток с задержкой 2 секунды при ошибке refresh.
- После 3 неудачных попыток подряд — не пытаться 24 часа (сбрасывать счётчик через 24ч).

### 4.4 Disconnect

- Очистить `whoopRefreshToken`, `whoopAccessToken`, `whoopTokenExpiresAt`, `lastSuccessfulSync` у пользователя.
- Клиент при disconnect вызывает `updateUser` с `whoopRefreshToken: null`.

---

## 5. WHOOP Data API — эндпоинты

Base URL: `https://api.prod.whoop.com/developer/v2`

Все запросы: `Authorization: Bearer {access_token}`

### 5.1 Список эндпоинтов

| # | Метод | Путь | Описание |
|---|-------|------|----------|
| 1 | GET | `/cycle` | Список циклов (включая текущий с `end: null`) |
| 2 | GET | `/cycle/{cycleId}` | Конкретный цикл (для проверки завершения) |
| 3 | GET | `/cycle/{cycleId}/recovery` | Recovery по циклу *(не используется, recovery из общего списка)* |
| 4 | GET | `/recovery` | Список recovery (фильтрация по `cycle_id`) |
| 5 | GET | `/user/measurement/body` | Body: height_meter, weight_kilogram, max_heart_rate |
| 6 | GET | `/activity/workout` | Список тренировок |
| 7 | GET | `/activity/sleep` | Список снов |

### 5.2 Формат ответов (ключевые поля)

**Cycle:**
```json
{
  "records": [
    {
      "id": 650800430,
      "end": null,
      "score_state": "SCORED",
      "score": {
        "strain": 16.43,
        "kilojoule": 9811.74,
        "average_heart_rate": 73,
        "max_heart_rate": 172
      }
    }
  ]
}
```

**Body:**
```json
{
  "height_meter": 1.75,
  "weight_kilogram": 70,
  "max_heart_rate": 190
}
```

**Sleep:**
```json
{
  "records": [
    {
      "score_state": "SCORED",
      "score": {
        "sleep_performance_percentage": 64.0
      }
    }
  ]
}
```

**Recovery:**
```json
{
  "records": [
    {
      "cycle_id": 650800430,
      "score_state": "SCORED",
      "score": {
        "recovery_score": 52.0
      }
    }
  ]
}
```

**Workout:**
```json
{
  "records": [
    {
      "id": 1206115357,
      "sport_id": 44,
      "start": "2024-08-30T05:30:00.875Z",
      "end": "2024-08-30T06:10:29.061Z",
      "score_state": "SCORED",
      "score": {
        "strain": 11.61,
        "kilojoule": 1272.53
      }
    }
  ]
}
```

---

## 6. Требования к бэкенду

### 6.1 Обязательные эндпоинты (фаза 1 — токены)

#### 6.1.1 Инициация OAuth (connect)

**`GET /whoop/connect`**

- **Auth:** требуется аутентификация пользователя (pivot-identity-key или JWT).
- **Поведение:**
  - Генерирует `state` (CSRF protection).
  - Сохраняет `state` в сессию/Redis/БД, привязанную к `userId`.
  - Редиректит 302 на WHOOP auth URL с `redirect_uri` на бэкенд (см. п. 6.1.2).
- **Response:** 302 Redirect.

**Альтернатива:** если приложение продолжит открывать WHOOP в WebView, бэкенд может отдавать только URL для connect, а callback обрабатывать отдельно.

#### 6.1.2 OAuth Callback

**`GET /whoop/callback`**

- **Query params:** `code`, `state`.
- **Поведение:**
  - Проверить `state`.
  - Обменять `code` на токены (POST на WHOOP token URL).
  - Сохранить `refresh_token`, `access_token`, `expires_at` для пользователя.
  - Редиректит в приложение: `com.rishai://redirect?success=true` (или deep link с токенами, если нужна обратная совместимость).
- **Response:** 302 Redirect.

#### 6.1.3 Disconnect

**`POST /whoop/disconnect`**

- **Auth:** требуется аутентификация пользователя.
- **Поведение:** очистить все WHOOP-поля у пользователя.
- **Response:** `200 OK` или `204 No Content`.

#### 6.1.4 Refresh token (внутренний)

Не публичный эндпоинт. Вызывается перед каждым запросом к WHOOP Data API, если access token истёк или истекает.

### 6.2 Проксирование WHOOP Data API (фаза 2)

**`GET /whoop/proxy/*`** или отдельные эндпоинты:

| Эндпоинт бэкенда | WHOOP API | Назначение |
|------------------|-----------|------------|
| `GET /whoop/cycles` | `GET /cycle` | Список циклов |
| `GET /whoop/cycle/:id` | `GET /cycle/:id` | Проверка цикла |
| `GET /whoop/body` | `GET /user/measurement/body` | Body measurements |
| `GET /whoop/workouts` | `GET /activity/workout` | Тренировки |
| `GET /whoop/sleep` | `GET /activity/sleep` | Сон |
| `GET /whoop/recovery` | `GET /recovery` | Recovery |

- **Auth:** pivot-identity-key + userId (из токена или заголовка).
- **Поведение:**
  - Получить access token пользователя (при необходимости — refresh).
  - Выполнить запрос к WHOOP с `Authorization: Bearer {token}`.
  - Вернуть ответ WHOOP клиенту (или нормализованный JSON).

**Альтернатива:** один эндпоинт `GET /whoop/data` или `GET /days/current`, который внутри собирает все нужные данные WHOOP и возвращает агрегированный результат (подготовка к созданию дня).

### 6.3 Создание сущности дня (фаза 3 — будущая)

**`GET /days/current`** или **`POST /days/current`**

- Получить/обновить токены.
- Вызвать cycles, body, sleep, recovery, workouts.
- Рассчитать TDEE, calorie goal, macros, health metrics.
- Создать/обновить запись в Directus.
- Вернуть JSON дня.

Детализация — в отдельном ТЗ после реализации фазы 1–2.

---

## 7. Контракт API бэкенда (рекомендуемый)

### 7.1 Connect — варианты

**Вариант A: Бэкенд инициирует OAuth**

```
GET /whoop/connect
  → 302 to WHOOP auth (redirect_uri = https://api.pivot.xxx/whoop/callback)

GET /whoop/callback?code=...&state=...
  → обмен code на токены, сохранение, 302 to com.rishai://redirect?success=true
```

**Вариант B: Клиент инициирует, бэкенд только обменивает code**

```
POST /whoop/exchange-code
Body: { "code": "..." }
  → обмен code на токены, сохранение
  → 200 { "success": true }
```

Клиент по-прежнему открывает WHOOP auth в WebView, получает `code` в redirect, отправляет его на бэкенд.

### 7.2 Disconnect

```
POST /whoop/disconnect
Headers: pivot-identity-key, userId (или из JWT)
  → 200 / 204
```

### 7.3 Проверка статуса подключения

```
GET /whoop/status
  → 200 {
      "connected": true,
      "lastSuccessfulSync": 1710700000000
    }
  или
  → 200 { "connected": false }
```

---

## 8. Обработка ошибок

### 8.1 WHOOP API

- `401 Unauthorized` — refresh token и повторить запрос (1 раз).
- `403 Forbidden` — пользователь отозвал доступ или scope недостаточен.
- После 3 неудачных refresh — считать WHOOP отключённым, вернуть `connected: false`.

### 8.2 Коды ответов бэкенда

| Код | Ситуация |
|-----|----------|
| 200 | Успех |
| 401 | Пользователь не аутентифицирован |
| 403 | WHOOP не подключен или токены невалидны |
| 502 | WHOOP API недоступен |

---

## 9. Безопасность

- `client_secret` — только на бэкенде, никогда не передавать клиенту.
- `state` в OAuth — обязателен, хранить и проверять.
- Refresh token — хранить зашифрованно (или в защищённом хранилище).
- Rate limiting на эндпоинты WHOOP proxy.

---

## 10. Миграция клиента

### 10.1 Текущие вызовы User Service

- `GET /users/:id` — возвращает `whoopRefreshToken`, `lastSuccessfulSync`.
- `PUT /users/:id` — принимает `whoopRefreshToken`, `lastSuccessfulSync`.

Бэкенд должен продолжать поддерживать эти поля для обратной совместимости.

### 10.2 После реализации фазы 1

1. Клиент при connect вызывает `GET /whoop/connect` (редирект) или отправляет `code` на `POST /whoop/exchange-code`.
2. Клиент при disconnect вызывает `POST /whoop/disconnect`.
3. Клиент удаляет локальное хранение токенов (SharedPreferences).
4. Клиент перестаёт вызывать WHOOP Data API напрямую — переходит на бэкенд proxy (фаза 2).

---

## 11. Референсы в кодовой базе

| Компонент | Путь |
|-----------|------|
| OAuth flow | `lib/features/whoop/data/repository/whoop_repository_impl.dart` (authenticateUser, refreshToken) |
| Token service | `lib/core/services/whoop_token_service.dart/token_service_impl.dart` |
| WHOOP endpoints | `lib/features/whoop/data/data_sources/remote/endpoints.dart` |
| Remote data source | `lib/features/whoop/data/data_sources/remote/remote_data_source_impl.dart` |
| User Service (updateUser) | `lib/core/services/user_service/user_service_client.dart` |

---

## 12. Чек-лист для разработчика

- [ ] Настроить WHOOP OAuth credentials в env бэкенда
- [ ] Реализовать OAuth flow (connect + callback или exchange-code)
- [ ] Хранить refresh_token, access_token, expires_at на пользователя
- [ ] Реализовать refresh token с retry и backoff
- [ ] Эндпоинт disconnect
- [ ] Эндпоинт status (опционально)
- [ ] Проксирование WHOOP Data API (фаза 2)
- [ ] Подготовка к созданию дня (фаза 3)
