/// Конфигурация для WHOOP API версий
/// Поддерживает плавное переключение между v1 и v2 для миграции
class WhoopApiConfig {
  // ===== WHOOP API v2 MIGRATION CONFIGURATION =====

  /// Feature flag для включения v2 API
  // TODO(dev): Изменить на true когда будете готовы к миграции
  static const bool _enableV2Api = false;

  /// Принудительное использование v2 API (переопределяет feature flag)
  // TODO(dev): Установить в true для полной миграции на v2
  static const bool _forceV2Api = false;

  /// Версия API по умолчанию
  static const String _defaultApiVersion = 'v1';

  /// Текущая версия API
  static String get apiVersion {
    if (_forceV2Api) return 'v2';
    if (_enableV2Api) return 'v2';
    return _defaultApiVersion;
  }

  /// Проверка версии API
  static bool get isV2 => apiVersion == 'v2';
  static bool get isV1 => apiVersion == 'v1';

  /// Проверка статуса миграции
  static bool get isMigrationEnabled => _enableV2Api;
  static bool get isForceV2Enabled => _forceV2Api;

  /// Информация о текущей конфигурации
  static String get migrationStatus {
    if (_forceV2Api) return 'FORCED_V2';
    if (_enableV2Api) return 'MIGRATION_ENABLED';
    return 'V1_ONLY';
  }

  // ===== END WHOOP API v2 MIGRATION CONFIGURATION =====

  /// Базовый URL для API
  static String get baseUrl => 'https://api.prod.whoop.com/developer';

  /// Получить полный URL для эндпоинта
  static String getEndpoint(String path) {
    return '$baseUrl/$apiVersion/$path';
  }

  /// Получить URL для mock сервера
  static String getMockEndpoint(String path) {
    return 'http://localhost:3000/$apiVersion/$path';
  }

  /// Получить информацию о конфигурации для логирования
  static Map<String, dynamic> get configInfo => {
        'apiVersion': apiVersion,
        'isV2': isV2,
        'isV1': isV1,
        'migrationEnabled': isMigrationEnabled,
        'forceV2Enabled': isForceV2Enabled,
        'migrationStatus': migrationStatus,
        'baseUrl': baseUrl,
      };
}
