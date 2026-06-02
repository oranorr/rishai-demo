# Copy user prod → staging

Скрипт копирует пользователя с **prod Directus** на **staging Directus** по **integer user id**.

## Что тебе нужно в `.env.copy-user`

Минимум **4 строки + URL staging Directus**:

```env
PROD_DIRECTUS_URL=https://rishai-directus-app-54tcs.ondigitalocean.app
PROD_DIRECTUS_TOKEN=...

STAGING_DIRECTUS_URL=http://35.208.24.80:8855
STAGING_DIRECTUS_TOKEN=...
```

> **Важно:** нужны URL **Directus**, не `pivot-backend-...`.

Файл `.env.copy-user` лежит в **корне репо** и **не коммитится**.

## Запуск

```bash
# dry-run
node scripts/copy-user-to-staging/copy-user.mjs --user-id 456 --staging-user-id 20 --dry-run

# копирование (рекомендуется — в существующего staging user)
node scripts/copy-user-to-staging/copy-user.mjs --user-id 456 --staging-user-id 20 --overwrite
```

`--staging-user-id` — id юзера **из staging Directus admin**, которого token «видит».
Без этого флага скрипт создаёт ghost-user (email+name только), профиль и days не копируются.

Подставь **свой prod user id** (integer из Directus admin).

## После копирования

1. Переключи приложение на **staging** backend.
2. Залогинься email'ом staging user (профиль перезапишется prod email'ом).
3. Данные должны быть на месте.

## Если ошибка

| Ошибка | Что сделать |
|--------|-------------|
| `403` на PATCH user | Исправлено: `weekPlanIds` не копируем. Обнови скрипт. |
| ghost user / days FK | Используй `--staging-user-id` или admin token |
| `staging user не найден` | Укажи `--staging-user-id` из staging admin |
| `STAGING_DIRECTUS_URL` | URL staging Directus (не pivot-backend) |
| `403` / `401` на Directus | Token без прав read/write |
| `User not found` | Неверный `--user-id` на prod |
| Коллекция не найдена | `USERS_COLLECTION=user`, `DAYS_COLLECTION=day` |
