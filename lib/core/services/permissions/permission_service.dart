import 'dart:io' show Platform;

import 'package:permission_handler/permission_handler.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PermissionResult Enum
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Результат запроса разрешения.
///
/// **Состояния:**
/// - granted: Разрешение предоставлено
/// - denied: Пользователь отказал в разрешении (можно запросить снова)
/// - permanentlyDenied: Разрешение постоянно запрещено (нужно открыть настройки)
enum PermissionResult {
  /// Разрешение предоставлено
  granted,

  /// Пользователь отказал в разрешении (можно запросить снова)
  denied,

  /// Разрешение постоянно запрещено (нужно открыть настройки)
  permanentlyDenied,
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PermissionService
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Сервис для работы с разрешениями камеры и галереи.
///
/// **Функциональность:**
/// - Единая точка для запроса разрешений камеры и галереи
/// - Упрощенная логика без различий платформ в основной логике
/// - Возвращает понятные результаты через enum PermissionResult
///
/// **Особенности платформ:**
/// - Android: Для галереи на Android 10+ может работать через scoped storage
/// - iOS: Разрешения запрашиваются системой, isLimited обрабатывается как granted
class PermissionService {
  /// [requestCameraPermission] Запрашивает разрешение на использование камеры
  ///
  /// Проверяет текущий статус разрешения и запрашивает его, если необходимо.
  /// Возвращает результат в виде enum PermissionResult.
  ///
  /// **Возвращает:**
  /// - PermissionResult.granted: Разрешение предоставлено
  /// - PermissionResult.denied: Пользователь отказал (можно запросить снова)
  /// - PermissionResult.permanentlyDenied: Разрешение постоянно запрещено
  ///
  /// **Логика работы:**
  /// 1. Проверяем текущий статус разрешения
  /// 2. Если уже granted или limited (iOS) - возвращаем granted
  /// 3. Если permanentlyDenied - возвращаем permanentlyDenied
  /// 4. Иначе запрашиваем разрешение и возвращаем результат
  Future<PermissionResult> requestCameraPermission() async {
    print('[PermissionService.requestCameraPermission] Запрос разрешения на камеру');

    // Проверяем текущий статус разрешения
    final PermissionStatus currentStatus = await Permission.camera.status;
    print('[PermissionService.requestCameraPermission] Текущий статус: $currentStatus');

    // Если разрешение уже предоставлено или ограничено (iOS) - возвращаем granted
    if (currentStatus.isGranted || currentStatus.isLimited) {
      print('[PermissionService.requestCameraPermission] ✅ Разрешение уже предоставлено');
      return PermissionResult.granted;
    }

    // Если разрешение постоянно запрещено - возвращаем permanentlyDenied
    if (currentStatus.isPermanentlyDenied) {
      print('[PermissionService.requestCameraPermission] ❌ Разрешение постоянно запрещено');
      return PermissionResult.permanentlyDenied;
    }

    // Запрашиваем разрешение
    print('[PermissionService.requestCameraPermission] Запрос разрешения у пользователя');
    final PermissionStatus requestedStatus = await Permission.camera.request();
    print('[PermissionService.requestCameraPermission] Результат запроса: $requestedStatus');

    // Обрабатываем результат запроса
    if (requestedStatus.isGranted || requestedStatus.isLimited) {
      print('[PermissionService.requestCameraPermission] ✅ Разрешение предоставлено');
      return PermissionResult.granted;
    } else if (requestedStatus.isPermanentlyDenied) {
      print('[PermissionService.requestCameraPermission] ❌ Разрешение постоянно запрещено');
      return PermissionResult.permanentlyDenied;
    } else {
      print('[PermissionService.requestCameraPermission] ⚠️ Пользователь отказал в разрешении');
      return PermissionResult.denied;
    }
  }

  /// [requestGalleryPermission] Запрашивает разрешение на доступ к галерее
  ///
  /// Проверяет текущий статус разрешения и запрашивает его, если необходимо.
  /// Возвращает результат в виде enum PermissionResult.
  ///
  /// **Особенности:**
  /// - На Android 10+ может работать через scoped storage без явного разрешения
  /// - На iOS isLimited обрабатывается как granted
  ///
  /// **Возвращает:**
  /// - PermissionResult.granted: Разрешение предоставлено
  /// - PermissionResult.denied: Пользователь отказал (можно запросить снова)
  /// - PermissionResult.permanentlyDenied: Разрешение постоянно запрещено
  ///
  /// **Логика работы:**
  /// 1. Проверяем текущий статус разрешения
  /// 2. Если уже granted или limited (iOS) - возвращаем granted
  /// 3. Если permanentlyDenied - возвращаем permanentlyDenied
  /// 4. Иначе запрашиваем разрешение и возвращаем результат
  Future<PermissionResult> requestGalleryPermission() async {
    print('[PermissionService.requestGalleryPermission] Запрос разрешения на галерею');

    // Проверяем текущий статус разрешения
    final PermissionStatus currentStatus = await Permission.photos.status;
    print('[PermissionService.requestGalleryPermission] Текущий статус: $currentStatus');

    // Если разрешение уже предоставлено или ограничено (iOS) - возвращаем granted
    if (currentStatus.isGranted || currentStatus.isLimited) {
      print('[PermissionService.requestGalleryPermission] ✅ Разрешение уже предоставлено');
      return PermissionResult.granted;
    }

    // Если разрешение постоянно запрещено - возвращаем permanentlyDenied
    if (currentStatus.isPermanentlyDenied) {
      print('[PermissionService.requestGalleryPermission] ❌ Разрешение постоянно запрещено');
      return PermissionResult.permanentlyDenied;
    }

    // На Android 10+ с scoped storage разрешение может быть denied,
    // но доступ все равно может работать через системный picker
    // Поэтому на Android мы не блокируем доступ, если разрешение denied
    // Но все равно запрашиваем его для консистентности
    if (Platform.isAndroid) {
      print('[PermissionService.requestGalleryPermission] Android: запрос разрешения');
      final PermissionStatus requestedStatus = await Permission.photos.request();
      print('[PermissionService.requestGalleryPermission] Результат запроса: $requestedStatus');

      // На Android если permanentlyDenied - возвращаем permanentlyDenied
      if (requestedStatus.isPermanentlyDenied) {
        print('[PermissionService.requestGalleryPermission] ❌ Разрешение постоянно запрещено');
        return PermissionResult.permanentlyDenied;
      }

      // На Android даже если denied, доступ может работать через scoped storage
      // Но для консистентности возвращаем denied, чтобы показать snackbar
      if (requestedStatus.isDenied) {
        print('[PermissionService.requestGalleryPermission] ⚠️ Пользователь отказал в разрешении');
        return PermissionResult.denied;
      }

      // Если granted или limited - возвращаем granted
      print('[PermissionService.requestGalleryPermission] ✅ Разрешение предоставлено');
      return PermissionResult.granted;
    }

    // На iOS запрашиваем разрешение
    print('[PermissionService.requestGalleryPermission] iOS: запрос разрешения');
    final PermissionStatus requestedStatus = await Permission.photos.request();
    print('[PermissionService.requestGalleryPermission] Результат запроса: $requestedStatus');

    // Обрабатываем результат запроса
    if (requestedStatus.isGranted || requestedStatus.isLimited) {
      print('[PermissionService.requestGalleryPermission] ✅ Разрешение предоставлено');
      return PermissionResult.granted;
    } else if (requestedStatus.isPermanentlyDenied) {
      print('[PermissionService.requestGalleryPermission] ❌ Разрешение постоянно запрещено');
      return PermissionResult.permanentlyDenied;
    } else {
      print('[PermissionService.requestGalleryPermission] ⚠️ Пользователь отказал в разрешении');
      return PermissionResult.denied;
    }
  }

  /// [getCameraStatus] Получает текущий статус разрешения на камеру
  ///
  /// Возвращает текущий статус разрешения без запроса.
  /// Используется для проверки статуса перед показом popup с настройками.
  ///
  /// **Возвращает:**
  /// PermissionStatus - текущий статус разрешения
  Future<PermissionStatus> getCameraStatus() async {
    return await Permission.camera.status;
  }

  /// [getGalleryStatus] Получает текущий статус разрешения на галерею
  ///
  /// Возвращает текущий статус разрешения без запроса.
  /// Используется для проверки статуса перед показом popup с настройками.
  ///
  /// **Возвращает:**
  /// PermissionStatus - текущий статус разрешения
  Future<PermissionStatus> getGalleryStatus() async {
    return await Permission.photos.status;
  }
}

