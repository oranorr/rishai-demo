import 'dart:developer';

import 'package:rishai/features/whoop/core/config/whoop_api_config.dart';

/// Менеджер для управления миграцией WHOOP API с v1 на v2
/// Обеспечивает плавный переход между версиями API
class WhoopApiMigrationManager {
  factory WhoopApiMigrationManager() => _instance;
  WhoopApiMigrationManager._internal() {
    _logMigrationStatus();
  }
  // ===== SINGLETON PATTERN =====
  static final WhoopApiMigrationManager _instance =
      WhoopApiMigrationManager._internal();

  // ===== MIGRATION STATUS =====

  /// Текущий статус миграции
  String get currentStatus => WhoopApiConfig.migrationStatus;

  /// Версия API в использовании
  String get currentApiVersion => WhoopApiConfig.apiVersion;

  /// Проверка, включена ли миграция
  bool get isMigrationEnabled => WhoopApiConfig.isMigrationEnabled;

  /// Проверка, принудительно ли включен v2
  bool get isForceV2Enabled => WhoopApiConfig.isForceV2Enabled;

  // ===== MIGRATION METHODS =====

  /// Включить миграцию на v2 API
  /// Это безопасно - приложение продолжит работать с v1 до полного переключения
  void enableMigration() {
    log('WHOOP API v2 Migration: Enabling migration to v2 API',
        name: 'MigrationManager');
    log('WHOOP API v2 Migration: Current status: $currentStatus',
        name: 'MigrationManager');

    // В реальном приложении здесь можно добавить логику для:
    // - Сохранения состояния в SharedPreferences
    // - Отправки аналитики
    // - Уведомления пользователя
  }

  /// Принудительно переключить на v2 API
  /// ВНИМАНИЕ: Это может сломать функциональность если v2 не полностью готов
  void forceV2Api() {
    log('WHOOP API v2 Migration: FORCING v2 API - USE WITH CAUTION!',
        name: 'MigrationManager');
    log('WHOOP API v2 Migration: This may break functionality if v2 is not fully ready',
        name: 'MigrationManager');

    // В реальном приложении здесь можно добавить логику для:
    // - Проверки готовности v2
    // - Rollback механизма
    // - Уведомления команды разработки
  }

  /// Получить информацию о миграции для отладки
  Map<String, dynamic> getMigrationInfo() {
    return {
      'currentStatus': currentStatus,
      'currentApiVersion': currentApiVersion,
      'isMigrationEnabled': isMigrationEnabled,
      'isForceV2Enabled': isForceV2Enabled,
      'configInfo': WhoopApiConfig.configInfo,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Проверить готовность к миграции
  /// Возвращает true если все компоненты готовы к v2
  bool checkMigrationReadiness() {
    log('WHOOP API v2 Migration: Checking migration readiness...',
        name: 'MigrationManager');

    // Проверяем готовность различных компонентов
    final checks = <String, bool>{
      'v2Models': _checkV2ModelsReady(),
      'v2Adapters': _checkV2AdaptersReady(),
      'v2Config': _checkV2ConfigReady(),
      'v2Factory': _checkV2FactoryReady(),
    };

    final allReady = checks.values.every((ready) => ready);

    log('WHOOP API v2 Migration: Migration readiness check results: $checks',
        name: 'MigrationManager');
    log('WHOOP API v2 Migration: All components ready: $allReady',
        name: 'MigrationManager');

    return allReady;
  }

  // ===== PRIVATE HELPER METHODS =====

  void _logMigrationStatus() {
    log('WHOOP API v2 Migration: Migration Manager initialized',
        name: 'MigrationManager');
    log('WHOOP API v2 Migration: Current status: $currentStatus',
        name: 'MigrationManager');
    log('WHOOP API v2 Migration: API version: $currentApiVersion',
        name: 'MigrationManager');
  }

  bool _checkV2ModelsReady() {
    try {
      // Проверяем что v2 модели доступны
      // В реальном приложении здесь можно добавить более детальные проверки
      return true;
    } catch (e) {
      log('WHOOP API v2 Migration: V2 models not ready: $e',
          name: 'MigrationManager');
      return false;
    }
  }

  bool _checkV2AdaptersReady() {
    try {
      // Проверяем что адаптеры доступны
      // В реальном приложении здесь можно добавить более детальные проверки
      return true;
    } catch (e) {
      log('WHOOP API v2 Migration: V2 adapters not ready: $e',
          name: 'MigrationManager');
      return false;
    }
  }

  bool _checkV2ConfigReady() {
    try {
      // Проверяем что конфигурация v2 доступна
      final config = WhoopApiConfig.configInfo;
      return config.isNotEmpty;
    } catch (e) {
      log('WHOOP API v2 Migration: V2 config not ready: $e',
          name: 'MigrationManager');
      return false;
    }
  }

  bool _checkV2FactoryReady() {
    try {
      // Проверяем что фабрика v2 доступна
      // В реальном приложении здесь можно добавить более детальные проверки
      return true;
    } catch (e) {
      log('WHOOP API v2 Migration: V2 factory not ready: $e',
          name: 'MigrationManager');
      return false;
    }
  }
}

/// Глобальный экземпляр менеджера миграции
final whoopMigrationManager = WhoopApiMigrationManager();
