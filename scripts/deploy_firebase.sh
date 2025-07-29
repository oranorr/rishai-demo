#!/bin/bash

# Скрипт для деплоймента в Firebase App Distribution

set -e

PLATFORM=${1:-"android"}
GROUPS=${2:-"internal-testers"}
NOTES=${3:-"Manual deployment from local"}

echo "🔥 Деплоймент в Firebase App Distribution..."

# Проверяем наличие Firebase CLI
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI не найден. Установите его: npm install -g firebase-tools"
    exit 1
fi

# Логин в Firebase (если нужно)
firebase login

case $PLATFORM in
    "android")
        echo "📱 Деплоймент Android в Firebase..."
        
        # Собираем APK если его нет
        if [ ! -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
            echo "📦 Сборка Android APK..."
            flutter build apk --release
        fi
        
        # Загружаем в Firebase App Distribution
        firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
            --app "1:922501061929:android:c4b5e8e0cd2503e5cb2b38" \
            --groups "$GROUPS" \
            --release-notes "$NOTES"
        ;;
        
    "ios")
        echo "🍎 Деплоймент iOS в Firebase..."
        
        # Проверяем, что мы на macOS
        if [[ "$OSTYPE" != "darwin"* ]]; then
            echo "❌ iOS деплоймент доступен только на macOS"
            exit 1
        fi
        
        # Собираем IPA с помощью Fastlane
        cd ios
        bundle exec fastlane deploy_firebase
        cd ..
        ;;
        
    *)
        echo "❌ Неподдерживаемая платформа: $PLATFORM"
        echo "Доступные платформы: android, ios"
        exit 1
        ;;
esac

echo "✅ Деплоймент завершен!"
echo "📱 Проверьте Firebase Console для статуса распространения" 