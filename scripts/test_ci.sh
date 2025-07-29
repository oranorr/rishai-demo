#!/bin/bash

# Скрипт для локального тестирования CI процесса

set -e

echo "🧪 Локальное тестирование CI процесса..."

# Очистка
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
if ! dart format --output=none --set-exit-if-changed .; then
    echo "❌ Код не отформатирован. Запустите: dart format ."
    exit 1
fi
echo "✅ Форматирование прошло проверку"

# Анализ кода
echo "🔍 Анализ кода..."
if ! flutter analyze --fatal-warnings; then
    echo "❌ Найдены ошибки анализа кода"
    exit 1
fi
echo "✅ Анализ кода прошел проверку"

# Запуск тестов
echo "🧪 Запуск тестов..."
if ! flutter test; then
    echo "❌ Тесты не прошли"
    exit 1
fi
echo "✅ Все тесты прошли"

# Проверка сборки Android
echo "📱 Проверка сборки Android..."
if ! flutter build apk --release --target-platform android-arm64; then
    echo "❌ Сборка Android не удалась"
    exit 1
fi
echo "✅ Сборка Android успешна"

# Проверка сборки iOS (только на macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Проверка сборки iOS..."
    if ! flutter build ios --release --no-codesign; then
        echo "❌ Сборка iOS не удалась"
        exit 1
    fi
    echo "✅ Сборка iOS успешна"
fi

echo "🎉 Все проверки CI прошли успешно!"
echo "📝 Ваш код готов для push в репозиторий" 