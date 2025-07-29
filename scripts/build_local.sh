#!/bin/bash

# Скрипт для локальной сборки Flutter приложения

set -e

echo "🛠️ Локальная сборка Flutter приложения..."

# Проверяем наличие .env файла
if [ ! -f ".env" ]; then
    echo "❌ Файл .env не найден. Создайте его на основе .env.example"
    exit 1
fi

# Очистка проекта
echo "🧹 Очистка проекта..."
flutter clean

# Получение зависимостей
echo "📦 Получение зависимостей..."
flutter pub get

# Генерация кода
echo "⚡ Генерация кода..."
dart run build_runner build --delete-conflicting-outputs

# Проверка форматирования
echo "🎨 Проверка форматирования..."
dart format --set-exit-if-changed .

# Анализ кода
echo "🔍 Анализ кода..."
flutter analyze

# Запуск тестов
echo "🧪 Запуск тестов..."
flutter test

# Сборка для разных платформ
PLATFORM=${1:-"all"}

case $PLATFORM in
    "android"|"all")
        echo "📱 Сборка Android..."
        flutter build apk --release
        flutter build appbundle --release
        echo "✅ Android APK: build/app/outputs/flutter-apk/app-release.apk"
        echo "✅ Android AAB: build/app/outputs/bundle/release/app-release.aab"
        ;;
esac

case $PLATFORM in
    "ios"|"all")
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "🍎 Сборка iOS..."
            flutter build ios --release --no-codesign
            echo "✅ iOS build: build/ios/iphoneos/Runner.app"
        else
            echo "⚠️ iOS сборка доступна только на macOS"
        fi
        ;;
esac

case $PLATFORM in
    "web"|"all")
        echo "🌐 Сборка Web..."
        flutter build web --release
        echo "✅ Web build: build/web/"
        ;;
esac

echo "�� Сборка завершена!" 