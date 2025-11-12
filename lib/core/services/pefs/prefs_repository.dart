import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/pefs/prefs_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

final prefsRepo = getIt.get<PrefsRepository>();

@Singleton()
class PrefsRepository {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> watchedOnboard() async {
    await _prefs.setBool(onboardWatched, true);
  }

  Future<void> setLogin(result) async {
    await _prefs.setBool(isLoggedIn, result);
  }

  bool checkIsLoggedIn() {
    return _prefs.getBool(onboardWatched) ?? false;
  }

  bool checkForWatchedOnboard() {
    return _prefs.getBool(onboardWatched) ?? false;
  }

  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
    required String expiresAt,
  }) async {
    await _prefs.setString(whoopAccessToken, accessToken);
    await _prefs.setString(whoopRefreshToken, refreshToken);
    await _prefs.setString(whoopExpiresAt, expiresAt);
  }

  String fetchSavedRefreshToken() {
    return _prefs.getString(whoopRefreshToken) ?? '';
  }

  String fetchSavedAccessToken() {
    return _prefs.getString(whoopAccessToken) ?? '';
  }

  Future<void> flush() async {
    await _prefs.clear();
  }

  Future<DateTime?> calibratingDate() async {
    final remaining = _prefs.getInt(calibrating);
    if (remaining != null) {
      final remainingDate = DateTime.fromMillisecondsSinceEpoch(remaining);
      final diff = DateTime.now().difference(remainingDate);
      // print(diff);
      if (diff.isNegative) {
        return null;
      } else {
        return remainingDate;
      }
    }
    final DateTime week = DateTime.now().add(const Duration(days: 7));
    final int setDate = week.millisecondsSinceEpoch;
    await _prefs.setInt(calibrating, setDate);
    return week;
  }

  Future<void> setNotifcationTime(String? time) async {
    if (time != null) {
      await _prefs.setString(notesTime, time);
    } else {
      await _prefs.remove(notesTime);
    }
  }

  String? getNoteTime() {
    return _prefs.getString(notesTime);
  }

  /// [setWellnessTooltipViewed] Устанавливает флаг, что пользователь видел подсказку wellness score
  Future<void> setWellnessTooltipViewed() async {
    await _prefs.setBool(wellnessTooltipViewed, true);
  }

  /// [hasViewedWellnessTooltip] Проверяет, видел ли пользователь подсказку wellness score
  bool hasViewedWellnessTooltip() {
    return _prefs.getBool(wellnessTooltipViewed) ?? false;
  }

  Future<void> clearTokens() async {
    await _prefs.setString(whoopAccessToken, '');
    await _prefs.setString(whoopRefreshToken, '');
    await _prefs.setString(whoopExpiresAt, '');
  }

  Future<bool> checkForWhoopDisclaimerAccpeted() async {
    return _prefs.getBool(acceptedWhoopDisclaimer) ?? false;
  }

  Future<void> disclaimerAccpeted() async {
    await _prefs.setBool(acceptedWhoopDisclaimer, true);
  }

  Future<DateTime?> getTokenExpiryDate() async {
    final expiresAt = _prefs.getString(whoopExpiresAt);
    if (expiresAt != null) {
      return DateTime.parse(expiresAt);
    } else {
      return null;
    }
  }

  /// Проверяет, совпадает ли сохраненная версия схемы с ожидаемой
  ///
  /// Возвращает true если:
  /// - Сохраненная версия совпадает с ожидаемой
  /// Возвращает false если:
  /// - Версия не была сохранена ранее (старые данные без версионирования)
  /// - Сохраненная версия отличается от ожидаемой
  bool isHiveSchemaVersionCompatible(int expectedVersion) {
    final savedVersion = getHiveSchemaVersion();

    // Если версия не сохранена (null), это может быть:
    // 1. Первый запуск приложения (данных нет)
    // 2. Обновление со старой версии, где версионирование не использовалось (данные есть)
    //
    // Поскольку мы не можем точно определить это здесь, возвращаем false
    // Логика Hive сама определит есть ли данные при открытии боксов
    if (savedVersion == null) {
      return false; // Принудительно сбрасываем данные для безопасности
    }

    return savedVersion == expectedVersion;
  }

  /// Безопасная проверка инициализации SharedPreferences
  ///
  /// Бросает исключение если _prefs не инициализирован
  void _ensureInitialized() {
    try {
      // Проверяем доступность _prefs через простой вызов
      _prefs.getString('_test_key');
    } catch (e) {
      throw StateError(
        'PrefsRepository не инициализирован. Вызовите await prefsRepo.init() перед использованием.',
      );
    }
  }

  /// Получает сохраненную версию схемы данных Hive
  ///
  /// Возвращает null, если версия не была сохранена ранее (первый запуск)
  int? getHiveSchemaVersion() {
    _ensureInitialized();
    return _prefs.getInt(hiveSchemaVersion);
  }

  /// Сохраняет текущую версию схемы данных Hive
  ///
  /// Вызывается после успешной инициализации или сброса Hive
  Future<void> setHiveSchemaVersion(int version) async {
    _ensureInitialized();
    await _prefs.setInt(hiveSchemaVersion, version);
  }

  /// [setLastFreeUserPhotoUploadTime] Сохраняет время последней загрузки фотографии
  /// бесплатным пользователем
  ///
  /// **Параметры:**
  /// - time: Время загрузки фотографии
  ///
  /// Сохраняет время в миллисекундах с эпохи Unix для последующей проверки
  /// 24-часового лимита загрузки фотографий.
  Future<void> setLastFreeUserPhotoUploadTime(DateTime time) async {
    _ensureInitialized();
    await _prefs.setInt(
      lastFreeUserPhotoUploadTime,
      time.millisecondsSinceEpoch,
    );
  }

  /// [getLastFreeUserPhotoUploadTime] Получает время последней загрузки фотографии
  /// бесплатным пользователем
  ///
  /// **Возвращает:**
  /// - `DateTime?` - время последней загрузки или `null`, если загрузок не было
  DateTime? getLastFreeUserPhotoUploadTime() {
    _ensureInitialized();
    final timestamp = _prefs.getInt(lastFreeUserPhotoUploadTime);
    if (timestamp == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// [canFreeUserUploadPhoto] Проверяет, может ли бесплатный пользователь
  /// загрузить фотографию (прошло ли 24 часа с последней загрузки)
  ///
  /// **Логика проверки:**
  /// - Если загрузок не было (время не сохранено) - возвращает `true`
  /// - Если прошло 24+ часа с последней загрузки - возвращает `true`
  /// - Если прошло менее 24 часов - возвращает `false`
  ///
  /// **Возвращает:**
  /// - `bool` - `true` если можно загрузить, `false` если лимит не истек
  bool canFreeUserUploadPhoto() {
    _ensureInitialized();
    final lastUploadTime = getLastFreeUserPhotoUploadTime();

    // Если загрузок не было - разрешаем загрузку
    if (lastUploadTime == null) {
      return true;
    }

    // Проверяем, прошло ли 24 часа с последней загрузки
    final now = DateTime.now();
    final timeDifference = now.difference(lastUploadTime);

    // Если прошло 24+ часа - разрешаем загрузку
    return timeDifference >= const Duration(hours: 24);
  }

  /// [setFreePaywallViewed] Устанавливает флаг, что пользователь видел бесплатную версию paywall
  ///
  /// После установки этого флага все последующие вызовы paywall будут показывать
  /// премиум версию вместо бесплатной
  Future<void> setFreePaywallViewed() async {
    _ensureInitialized();
    await _prefs.setBool(freePaywallViewed, true);
  }

  /// [hasViewedFreePaywall] Проверяет, видел ли пользователь бесплатную версию paywall
  ///
  /// **Возвращает:**
  /// - `bool` - `true` если пользователь уже видел бесплатную версию, `false` если нет
  bool hasViewedFreePaywall() {
    _ensureInitialized();
    return _prefs.getBool(freePaywallViewed) ?? false;
  }
}
