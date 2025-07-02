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

  /// Получает сохраненную версию схемы данных Hive
  ///
  /// Возвращает null, если версия не была сохранена ранее (первый запуск)
  int? getHiveSchemaVersion() {
    return _prefs.getInt(hiveSchemaVersion);
  }

  /// Сохраняет текущую версию схемы данных Hive
  ///
  /// Вызывается после успешной инициализации или сброса Hive
  Future<void> setHiveSchemaVersion(int version) async {
    await _prefs.setInt(hiveSchemaVersion, version);
  }

  /// Проверяет, совпадает ли сохраненная версия схемы с ожидаемой
  ///
  /// Возвращает false если:
  /// - Версия не была сохранена ранее (первый запуск)
  /// - Сохраненная версия отличается от ожидаемой
  bool isHiveSchemaVersionCompatible(int expectedVersion) {
    final savedVersion = getHiveSchemaVersion();
    return savedVersion == expectedVersion;
  }
}
