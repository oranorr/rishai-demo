# Flutter Backend Migration Release Plan

Дата сверки: 02.06.2026

Ветка: `backend-integration`

## Оценка присланного backend-плана

План backend-агента в целом корректный для релиза: он правильно держит фокус на совместимости старых клиентов через legacy `pivot-identity-key`, переводе новой Flutter-сборки на `Authorization: Bearer <access_token>`, переносе прямых Directus-вызовов за backend API и staged rollout.

Для Flutter самая важная часть плана — пункт 6 и smoke-проверки из пункта 7. По текущей ветке фронт действительно в большой степени подготовлен, но есть несколько релизных хвостов, которые нельзя игнорировать перед production rollout.

Главный вывод: Flutter находится в состоянии **почти готово к staging QA**, но **ещё не готово к production release без финальной зачистки auth/env/LLM-proxy стратегии**.

## Что уже сделано во Flutter

### Auth session / JWT

Сделано:

- Добавлены app JWT ключи отдельно от WHOOP токенов: `appAccessToken`, `appRefreshToken`, `appAccessTokenExpiresAt`.
- После `POST /auth/verify-otp` и `POST /auth/oauth` токены сохраняются через `PrefsRepository.writeAppJwtSession`.
- Для protected User API есть общий клиент `UserServiceClient`.
- Для `GET /users/me`, `PUT /users/me`, `DELETE /users/me` используется Bearer-only путь.
- Для user-scoped endpoints при наличии access token отправляется только `Authorization: Bearer ...`, без `x-user-id`.
- При отсутствии JWT сохранён legacy fallback на `pivot-identity-key` + `x-user-id`.

Осталось:

- Refresh token сейчас хранится в `SharedPreferences`. Это расходится с исходным backend-планом, но для текущего релиза принято как осознанный non-blocking риск.
- Нет отдельного DTO/модели сессии с полем `tokenType = Bearer`; фактически это не проблема для текущего клиента, потому что backend выдаёт Bearer-only JWT, а `UserServiceClient` централизованно формирует `Authorization: Bearer <access>`.
- Logout чистит JWT через `LoginBloc._logout`; session-expired/refresh failure теперь вызывает полноценный logout через `SessionManager` → `LogoutEvent`.

### HTTP interceptor / protected backend API

Сделано:

- В `UserServiceClient._userScopedHeaders` при наличии access JWT используется Bearer.
- `x-user-id` не отправляется вместе с Bearer.
- Реализован один retry после 401 через refresh.
- `GET /days`, `GET /days/current`, `PATCH /days/current`, WHOOP endpoints, week-plans и tasks идут через общий User API client.
- `LlmProxyClient` переведён на app `Authorization: Bearer <access>` для `/llm-proxy`, `/llm-proxy-meal`, `/llm-proxy-chat`, `/llm-proxy-food-photo/analyze`, `/recommend`; legacy `pivot-identity-key` и `x-user-id` там больше не используются.

Осталось:

- Это не настоящий глобальный interceptor: логика refresh/retry живёт внутри `UserServiceClient`. Это нормально для текущей архитектуры, но надо не допустить обходных HTTP-клиентов.
- `UserServiceClient._baseUrl` сейчас жёстко возвращает staging backend. Это блокер production release.
- `LlmProxyClient._baseUrl` сейчас жёстко возвращает production backend. Нужна единая env/build-flavor логика, иначе Flutter может ходить в разные окружения.

### Refresh flow

Сделано:

- Есть proactive refresh за 90 секунд до истечения access token.
- Есть refresh при первом 401.
- Есть защита от бесконечного refresh-loop: retry выполняется один раз.
- Если `/auth/refresh` неуспешен, запускается полноценный logout через общий `LogoutEvent`.

Осталось:

- Нужно QA-подтверждение refresh failure UX: клиент теперь запускает полный logout и уводит на `/login`.
- Нужен QA сценарий: истёкший access + валидный refresh, истёкший refresh, backend 401 на protected route.

### OTP flow

Сделано:

- Email login вызывает `POST /auth/request-otp`.
- OTP экран больше не проверяет код локально, кроме длины.
- Submit OTP вызывает `POST /auth/verify-otp`, сохраняет JWT и затем делает `GET /users/me`.
- Старый `login_via_email_usecase.dart` удалён.

Осталось:

- `POST /users/create` для регистрации всё ещё вызывается с legacy `pivot-identity-key`. Если backend оставляет этот endpoint legacy-compatible — ок. Если новая регистрация должна быть полностью public/JWT-free, нужно синхронизировать контракт.

### OAuth flow

Сделано:

- Google/Apple идут через native sign-in.
- После Firebase sign-in Flutter получает Firebase ID token.
- Затем вызывается `POST /auth/oauth`.
- После backend JWT вызывается `GET /users/me`.
- Новый путь в `LoginRepositoryImpl` не использует `POST /users/login-oauth`.

Осталось:

- В `UserServiceClient` legacy method `loginOAuth()` ещё существует, хотя новой сборкой не используется. Можно оставить как fallback, но лучше пометить deprecated или удалить после вымирания старого пути.
- Нужно QA: Google existing user, Google new user, Apple existing user, Apple new user, Apple first-login display name.

### Directus SDK removal

Сделано:

- Dependency `directus` удалён из `pubspec.yaml`.
- Старые Directus service files удалены.
- App config переведён на `GET /config/app`.
- Accounts whitelist переведён на `GET /config/accounts-whitelist` и ожидает канонический `{ "emails": [...] }`.
- Feedback переведён на `POST /feedback`.
- Feedback attachments отключены/no-op, так как backend их не поддерживает.
- Debug seed days переведён на `POST /debug/days/seed-history`.
- Days/week plans/chatSnap/mealPlan теперь сохраняются через backend User API, а не через Directus SDK.

Осталось:

- В коде осталось много комментариев/названий `Directus`, `directusId`, `toDirectus`. Это не обязательно блокер: часть терминологии всё ещё отражает server id / JSON format.
- Нужно проверить, что в release UI нет доступной debug seed кнопки. Сам endpoint должен быть backend-protected, но Flutter не должен случайно показывать этот сценарий пользователям.

### Recomp / modificator

Сделано:

- Старый WHOOP usecase `change_modificator_or_sex_usecase.dart` удалён.
- WHOOP/day refresh теперь тянет актуальный current day с backend.
- В profile settings после изменения profile fields запускается backend refresh текущего дня.

Осталось:

- Flutter всё ещё позволяет менять modificator для `aesthetics` и `performance`; для `recomp` UI выглядит закрытым, что соответствует плану.
- Нужно QA проверить конкретно recomp user: новый день должен приходить с backend-updated `userGoal.modificator`, без клиентского автопереключения.

### Data sync / release UX

Сделано:

- Добавлен умный sync days: cache first, backend pagination, dedupe, current day refresh.
- Добавлен Hive cache для week plans.
- Week plans перешли на stale-while-revalidate, чтобы не мигал пустой экран.
- Добавлен WHOOP sync banner на Home.
- WHOOP auth recovery теперь форсит reconnect при 401/403/token-refresh-blocked вместо бесконечных retry.

Осталось:

- Нужно прогнать real-user QA на аккаунтах с большой историей days/weekPlans.
- Нужно проверить upgrade path Hive v5: старые локальные данные, новый `weekPlan_box`, очистка/миграция, logout.

## Блокеры перед production Flutter release

1. Исправить backend environment selection:
   - `UserServiceClient` не должен в release ходить на staging.
   - `LlmProxyClient` и `UserServiceClient` должны выбирать одно и то же окружение.
   - Желательно вынести base URL в flavor/env, а не держать разные hardcoded return.

2. QA LLM Bearer auth:
   - chat, regenerate/replace meal, food photo analysis и recommendations должны проходить с app access token;
   - refresh 401 на LLM endpoints должен вести себя так же, как User API.

3. Проверить, что debug seed недоступен пользователю в production UI:
   - endpoint уже должен быть backend-protected;
   - Flutter UI должен быть только debug/internal.

## Flutter QA checklist для staging

### Auth

- Email existing user: request OTP, verify OTP, `GET /users/me`, Home opens.
- Email new user: create user, request OTP, verify OTP, onboarding/WHOOP path корректен.
- Wrong OTP: понятная ошибка, JWT не сохраняется.
- Expired OTP: понятная ошибка, можно запросить новый код.
- App restart after login: session восстанавливается и API идут через Bearer.

### Refresh / session

- Access expired, refresh valid: первый protected request обновляет access и повторяется.
- Access expired, refresh expired/invalid: JWT очищается, пользователь попадает на login.
- Protected request с Bearer не отправляет `x-user-id`.
- Protected request без JWT в legacy сценарии всё ещё работает только там, где backend это ожидает.

### OAuth

- Google existing email.
- Google new email.
- Apple existing email.
- Apple new email.
- Apple first login с display name и повторный login без display name.

### Backend API replacement

- App version check читает `GET /config/app`.
- Whitelist читает `GET /config/accounts-whitelist` и активирует subscription для email из списка.
- Feedback отправляется через `POST /feedback`; attachments не ломают UX.
- Debug seed days работает только в debug/internal окружении.

### User data / days / WHOOP

- `GET /days/current` работает после login.
- `GET /days` пагинирует историю и не создаёт дубликаты в Hive.
- `PATCH /days/current` сохраняет mealPlan/chatSnap/welnessEntity.
- WHOOP-connected user проходит sync.
- Invalid WHOOP backend token ведёт на reconnect, без бесконечных retry.
- Pull-to-sync на Home запускает sync только после сильного pull-down.

### Week plans / meal prep

- Existing preps показываются из Hive cache сразу после входа.
- Backend sync обновляет список без мигания `There are no preps yet`.
- Generate weekly meal plan создаёт prep, сохраняет backend state и Hive cache.
- Filters не показывают full-screen loading.

### Recomp / profile

- Recomp user не получает клиентского автопереключения modificator.
- После изменения diet/gender/modificator текущий день обновляется с backend.
- Existing wellness/food diary data не затирается пустым current day.

## Production rollout Flutter-only

1. До сборки:
   - выбрать production backend URL через flavor/env;
   - убрать staging hardcode;
   - подтвердить LLM auth strategy;
   - принять `SharedPreferences` для refresh token как осознанный риск текущего релиза.

2. Internal/TestFlight:
   - прогнать весь staging checklist на production-like backend;
   - проверить existing users с WHOOP и большой историей;
   - проверить new users через OTP/OAuth.

3. Gradual rollout:
   - начать с internal testers;
   - затем staged rollout 5% / 25% / 50% / 100%;
   - мониторить 401/403, refresh failures, `/auth/oauth`, `/auth/verify-otp`, `/days/current`, `/week-plans`, WHOOP reconnect.

4. После rollout:
   - не отключать `pivot-identity-key`, пока старые клиенты активны;
   - когда legacy traffic почти исчезнет, подготовить отдельную Flutter/backend зачистку legacy fallback.

## Итоговая оценка готовности

Flutter-подготовка функционально широкая и в правильном направлении: Directus SDK убран, OTP/OAuth/JWT подключены, User API покрывает основные домены, sync стал гораздо устойчивее.

Но перед релизом нельзя пропустить три вещи:

- production/staging base URL;
- QA Bearer auth для `LlmProxyClient`;
- QA refresh/session-expired сценариев.

После закрытия этих пунктов ветка выглядит готовой к полноценному staging regression pass и затем к осторожному staged rollout.
