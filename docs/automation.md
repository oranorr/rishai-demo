# 🚀 Автоматизация разработки и деплоймента

Этот документ описывает систему автоматизации для Flutter приложения RishAI.

## 📋 Обзор

Система автоматизации включает:

- **CI/CD pipelines** с GitHub Actions
- **Автоматическое тестирование** и анализ кода
- **Автоматическая сборка** для Android и iOS
- **Автоматический деплоймент** в магазины приложений
- **Управление версиями** с помощью скриптов
- **Firebase App Distribution** для тестирования

## 🛠️ Структура файлов

```
.github/workflows/
├── ci.yml              # CI pipeline (тесты, анализ, сборка)
└── deploy.yml          # Деплоймент в магазины

android/
├── Gemfile             # Ruby зависимости для Fastlane
└── fastlane/
    └── Fastfile        # Автоматизация Android деплоймента

ios/
├── Gemfile             # Ruby зависимости для Fastlane
└── fastlane/
    └── Fastfile        # Автоматизация iOS деплоймента

scripts/
├── setup_automation.sh # Первоначальная настройка
├── version_bump.sh     # Обновление версии
├── build_local.sh      # Локальная сборка
├── deploy_firebase.sh  # Деплоймент в Firebase
└── test_ci.sh          # Локальное тестирование CI
```

## 🔧 Настройка

### 1. Первоначальная настройка

```bash
./scripts/setup_automation.sh
```

Этот скрипт:
- Устанавливает Fastlane для Android и iOS
- Создает необходимые директории
- Генерирует .env.example
- Обновляет .gitignore

### 2. Настройка GitHub Secrets

Добавьте следующие секреты в GitHub Settings > Secrets and variables > Actions:

#### Android
- `ANDROID_KEYSTORE_BASE64` - keystore в base64
- `ANDROID_KEYSTORE_PASSWORD` - пароль от keystore
- `ANDROID_KEY_PASSWORD` - пароль от ключа
- `ANDROID_KEY_ALIAS` - алиас ключа
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` - JSON service account

#### iOS
- `IOS_CERTIFICATES_P12_BASE64` - сертификаты в base64
- `IOS_CERTIFICATES_P12_PASSWORD` - пароль от сертификатов
- `APPSTORE_ISSUER_ID` - App Store Connect Issuer ID
- `APPSTORE_KEY_ID` - App Store Connect Key ID
- `APPSTORE_PRIVATE_KEY` - App Store Connect Private Key
- `MATCH_PASSWORD` - пароль для match (опционально)
- `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` - app-specific password

### 3. Создание .env файла

```bash
cp .env.example .env
# Заполните реальными значениями
```

## 🔄 Workflow'ы

### CI Pipeline (.github/workflows/ci.yml)

Запускается при:
- Push в ветки `main`, `develop`, `staging`
- Pull requests в `main`, `develop`

Включает:
1. **Тестирование** - форматирование, анализ, unit тесты
2. **Сборка Android** - APK и AAB
3. **Сборка iOS** - без подписи

### Deploy Pipeline (.github/workflows/deploy.yml)

Запускается при:
- Push тегов `v*` (например, `v1.2.3`)
- Ручной запуск через GitHub UI

Включает:
- Деплоймент в Google Play Internal Testing
- Деплоймент в TestFlight

## 📱 Локальная разработка

### Сборка проекта

```bash
# Все платформы
./scripts/build_local.sh

# Только Android
./scripts/build_local.sh android

# Только iOS
./scripts/build_local.sh ios
```

### Тестирование CI локально

```bash
./scripts/test_ci.sh
```

### Обновление версии

```bash
# Патч версия (1.0.0 -> 1.0.1)
./scripts/version_bump.sh patch

# Минорная версия (1.0.0 -> 1.1.0)
./scripts/version_bump.sh minor

# Мажорная версия (1.0.0 -> 2.0.0)
./scripts/version_bump.sh major

# Только номер сборки
./scripts/version_bump.sh build
```

### Деплоймент в Firebase

```bash
# Android
./scripts/deploy_firebase.sh android

# iOS
./scripts/deploy_firebase.sh ios
```

## 🏪 Деплоймент в магазины

### Автоматический деплоймент

1. Обновите версию:
   ```bash
   ./scripts/version_bump.sh patch
   ```

2. Отправьте изменения:
   ```bash
   git push && git push --tags
   ```

3. GitHub Actions автоматически:
   - Соберет приложение
   - Загрузит в Google Play Internal Testing
   - Загрузит в TestFlight

### Ручной деплоймент

#### Android
```bash
cd android
bundle exec fastlane deploy_internal    # Internal Testing
bundle exec fastlane deploy_beta        # Beta
bundle exec fastlane deploy_production  # Production
```

#### iOS
```bash
cd ios
bundle exec fastlane deploy_testflight  # TestFlight
bundle exec fastlane deploy_appstore    # App Store
```

## 🔍 Мониторинг и отладка

### Логи сборки
- GitHub Actions: вкладка "Actions" в репозитории
- Fastlane: файлы `report.xml` в директориях ios/fastlane и android/fastlane

### Sentry
Приложение настроено для отправки ошибок в Sentry:
- Проект: `flutter`
- Организация: `mvplab-wm`

### Firebase Analytics
Аналитика событий автоматически отправляется в Firebase.

## 🛡️ Безопасность

### Секреты
- Все ключи и сертификаты хранятся в GitHub Secrets
- Локальные файлы с секретами исключены из git
- Используется base64 кодирование для бинарных файлов

### Подписание
- Android: использует keystore из GitHub Secrets
- iOS: использует certificates и provisioning profiles

## 🚀 Оптимизация

### Кэширование
- Flutter SDK кэшируется в GitHub Actions
- Gem dependencies кэшируются для Ruby
- Docker layers кэшируются при использовании

### Параллельная сборка
- Android и iOS собираются параллельно
- Тесты запускаются до сборки для быстрой обратной связи

## 📊 Метрики

### Покрытие кода
- Результаты тестов загружаются в Codecov
- Отчет доступен в pull requests

### Время сборки
- CI: ~10-15 минут
- Деплоймент: ~20-30 минут

## 🆘 Troubleshooting

### Частые проблемы

1. **Ошибка сборки Android**
   - Проверьте keystore secrets
   - Убедитесь, что key.properties создается корректно

2. **Ошибка сборки iOS**
   - Проверьте certificates и provisioning profiles
   - Убедитесь, что bundle ID совпадает

3. **Ошибка тестов**
   - Запустите `./scripts/test_ci.sh` локально
   - Проверьте форматирование кода

4. **Ошибка деплоймента**
   - Проверьте версию в pubspec.yaml
   - Убедитесь, что версия уникальна для платформы

### Полезные команды

```bash
# Очистка проекта
flutter clean && flutter pub get

# Генерация кода
dart run build_runner build --delete-conflicting-outputs

# Форматирование кода
dart format .

# Анализ кода
flutter analyze

# Установка Fastlane зависимостей
cd android && bundle install
cd ios && bundle install
``` 