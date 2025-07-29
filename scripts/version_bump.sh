#!/bin/bash

# Скрипт для автоматического обновления версии приложения

set -e

# Получаем текущую версию из pubspec.yaml
CURRENT_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //')
echo "Текущая версия: $CURRENT_VERSION"

# Разделяем версию на компоненты
VERSION_NAME=$(echo $CURRENT_VERSION | cut -d'+' -f1)
BUILD_NUMBER=$(echo $CURRENT_VERSION | cut -d'+' -f2)

# Определяем тип обновления
case "$1" in
  "major")
    MAJOR=$(echo $VERSION_NAME | cut -d'.' -f1)
    MAJOR=$((MAJOR + 1))
    NEW_VERSION_NAME="$MAJOR.0.0"
    ;;
  "minor")
    MAJOR=$(echo $VERSION_NAME | cut -d'.' -f1)
    MINOR=$(echo $VERSION_NAME | cut -d'.' -f2)
    MINOR=$((MINOR + 1))
    NEW_VERSION_NAME="$MAJOR.$MINOR.0"
    ;;
  "patch")
    MAJOR=$(echo $VERSION_NAME | cut -d'.' -f1)
    MINOR=$(echo $VERSION_NAME | cut -d'.' -f2)
    PATCH=$(echo $VERSION_NAME | cut -d'.' -f3)
    PATCH=$((PATCH + 1))
    NEW_VERSION_NAME="$MAJOR.$MINOR.$PATCH"
    ;;
  "build")
    NEW_VERSION_NAME=$VERSION_NAME
    ;;
  *)
    echo "Использование: $0 {major|minor|patch|build}"
    echo "  major: увеличить мажорную версию (1.0.0 -> 2.0.0)"
    echo "  minor: увеличить минорную версию (1.0.0 -> 1.1.0)"
    echo "  patch: увеличить патч версию (1.0.0 -> 1.0.1)"
    echo "  build: увеличить только номер сборки"
    exit 1
    ;;
esac

# Увеличиваем номер сборки
NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
NEW_VERSION="$NEW_VERSION_NAME+$NEW_BUILD_NUMBER"

echo "Новая версия: $NEW_VERSION"

# Обновляем pubspec.yaml
sed -i.bak "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml
rm pubspec.yaml.bak

# Обновляем версию в iOS Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION_NAME" ios/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD_NUMBER" ios/Runner/Info.plist

# Обновляем версию в Android build.gradle
sed -i.bak "s/versionName .*/versionName \"$NEW_VERSION_NAME\"/" android/app/build.gradle
sed -i.bak "s/versionCode .*/versionCode $NEW_BUILD_NUMBER/" android/app/build.gradle
rm android/app/build.gradle.bak

echo "Версия успешно обновлена на $NEW_VERSION"

# Создаем git commit и tag
git add pubspec.yaml ios/Runner/Info.plist android/app/build.gradle
git commit -m "Bump version to $NEW_VERSION"
git tag "v$NEW_VERSION"

echo "Создан git tag: v$NEW_VERSION"
echo "Для отправки изменений выполните: git push && git push --tags" 