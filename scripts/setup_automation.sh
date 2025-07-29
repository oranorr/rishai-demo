#!/bin/bash

# Скрипт для настройки автоматизации разработки

set -e

echo "🚀 Настройка автоматизации для Flutter проекта..."

# Проверяем наличие необходимых инструментов
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ $1 не найден. Установите его перед продолжением."
        exit 1
    else
        echo "✅ $1 найден"
    fi
}

echo "📋 Проверка зависимостей..."
check_tool "flutter"
check_tool "ruby"
check_tool "bundler"

# Устанавливаем Fastlane для Android
echo "📱 Настройка Fastlane для Android..."
cd android
if [ ! -f "Gemfile.lock" ]; then
    bundle install
fi
bundle exec fastlane init
cd ..

# Устанавливаем Fastlane для iOS
echo "🍎 Настройка Fastlane для iOS..."
cd ios
if [ ! -f "Gemfile.lock" ]; then
    bundle install
fi
bundle exec fastlane init
cd ..

# Создаем директории для сертификатов и ключей
echo "🔐 Создание директорий для сертификатов..."
mkdir -p .secrets/android
mkdir -p .secrets/ios

# Создаем файл .env.example
echo "📝 Создание примера .env файла..."
cat > .env.example << 'EOF'
# Firebase
FIREBASE_PROJECT_ID=rishai
FIREBASE_API_KEY=your_api_key_here

# OpenAI
OPENAI_API_KEY=your_openai_api_key_here

# Directus
DIRECTUS_URL=your_directus_url_here
DIRECTUS_TOKEN=your_directus_token_here

# Sentry
SENTRY_DSN=your_sentry_dsn_here

# Build Configuration
BUILD_MODE=release
FLUTTER_CHANNEL=stable
EOF

# Обновляем .gitignore
echo "📂 Обновление .gitignore..."
cat >> .gitignore << 'EOF'

# Automation secrets
.secrets/
android/service-account.json
android/keystore.jks
android/key.properties
ios/AuthKey*.p8
ios/build/
android/build/

# Fastlane
ios/fastlane/report.xml
ios/fastlane/Preview.html
ios/fastlane/screenshots
ios/fastlane/test_output
android/fastlane/report.xml
android/fastlane/Preview.html
android/fastlane/screenshots
android/fastlane/test_output

# Environment files
.env.local
.env.staging
.env.production
EOF

echo "✅ Автоматизация настроена!"
echo ""
echo "📋 Следующие шаги:"
echo "1. Настройте секреты в GitHub:"
echo "   - ANDROID_KEYSTORE_BASE64"
echo "   - ANDROID_KEYSTORE_PASSWORD"
echo "   - ANDROID_KEY_PASSWORD"
echo "   - ANDROID_KEY_ALIAS"
echo "   - GOOGLE_PLAY_SERVICE_ACCOUNT_JSON"
echo "   - IOS_CERTIFICATES_P12_BASE64"
echo "   - IOS_CERTIFICATES_P12_PASSWORD"
echo "   - APPSTORE_ISSUER_ID"
echo "   - APPSTORE_KEY_ID"
echo "   - APPSTORE_PRIVATE_KEY"
echo ""
echo "2. Создайте .env файл на основе .env.example"
echo "3. Настройте подписание для Android и iOS"
echo "4. Протестируйте локальную сборку: ./scripts/build_local.sh"
echo "5. Обновите версию: ./scripts/version_bump.sh patch" 