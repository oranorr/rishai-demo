# 🚀 Автоматизация RishAI

Система автоматизации разработки и деплоймента для Flutter приложения.

## ⚡ Быстрый старт

### 1. Настройка
```bash
./scripts/setup_automation.sh
```

### 2. Локальная сборка
```bash
./scripts/build_local.sh
```

### 3. Обновление версии и деплоймент
```bash
./scripts/version_bump.sh patch
git push && git push --tags
```

## 📋 Доступные команды

| Команда | Описание |
|---------|----------|
| `./scripts/setup_automation.sh` | Первоначальная настройка |
| `./scripts/build_local.sh [platform]` | Локальная сборка |
| `./scripts/test_ci.sh` | Тестирование CI локально |
| `./scripts/version_bump.sh [type]` | Обновление версии |
| `./scripts/deploy_firebase.sh [platform]` | Деплоймент в Firebase |

## 🔄 CI/CD Process

### При push в main/develop/staging:
1. ✅ Тесты и анализ кода
2. 📱 Сборка Android (APK + AAB)
3. 🍎 Сборка iOS (без подписи)

### При создании тега (v*):
1. 📱 Деплоймент в Google Play Internal
2. 🍎 Деплоймент в TestFlight

## 🔧 Настройка секретов

Добавьте в GitHub Settings > Secrets:

**Android:**
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`

**iOS:**
- `IOS_CERTIFICATES_P12_BASE64`
- `IOS_CERTIFICATES_P12_PASSWORD`
- `APPSTORE_ISSUER_ID`
- `APPSTORE_KEY_ID`
- `APPSTORE_PRIVATE_KEY`

## 📚 Подробная документация

См. [docs/automation.md](docs/automation.md) для детальной информации.

## 🆘 Поддержка

При проблемах:
1. Запустите `./scripts/test_ci.sh`
2. Проверьте логи в GitHub Actions
3. Обратитесь к [troubleshooting guide](docs/automation.md#-troubleshooting) 