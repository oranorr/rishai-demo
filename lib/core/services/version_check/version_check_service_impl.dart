import 'dart:developer';
import 'dart:io' show Platform;

import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rishai/core/services/user_service/user_service_client.dart';
import 'package:rishai/core/services/version_check/version_check_service.dart';
import 'package:version/version.dart';

@Singleton(as: VersionCheckService)
class VersionCheckServiceImpl implements VersionCheckService {
  VersionCheckServiceImpl(this._userServiceClient);
  final UserServiceClient _userServiceClient;
  PackageInfo? _packageInfo;
  Map<String, dynamic>? _appConfig;

  Future<PackageInfo> _getPackageInfo() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    return _packageInfo!;
  }

  Future<Map<String, dynamic>?> _getAppConfig() async {
    try {
      _appConfig ??= await _userServiceClient.getAppConfigPublic();
      return _appConfig;
    } catch (e, stackTrace) {
      log('Error fetching app config: $e', error: e, stackTrace: stackTrace);
      // Можно добавить обработку ошибок через NetworkErrorHandler, если нужно
      return null;
    }
  }

  @override
  Future<bool> isUpdateRequired() async {
    final packageInfo = await _getPackageInfo();
    final appConfig = await _getAppConfig();

    if (appConfig == null) {
      log('App config is null, cannot check for update.');
      return false; // Не можем проверить, считаем, что обновление не нужно
    }

    // Проверяем, включена ли проверка версий
    final bool versionCheckOn = appConfig['versionCheckOn'] as bool? ?? true;
    if (!versionCheckOn) {
      log('Version check is disabled in app config.');
      return false; // Проверка версий отключена, считаем, что обновление не нужно
    }

    try {
      final currentVersionStr = packageInfo.version;
      final currentBuildNumber = packageInfo.buildNumber;
      final currentFullVersionStr = '$currentVersionStr+$currentBuildNumber';
      final currentVersion = Version.parse(currentFullVersionStr);

      String? requiredVersionStr;
      if (Platform.isAndroid) {
        requiredVersionStr = appConfig['androidVersion'] as String?;
      } else if (Platform.isIOS) {
        requiredVersionStr = appConfig['iosVersion'] as String?;
      }

      if (requiredVersionStr == null) {
        log('Required version for ${Platform.operatingSystem} not found in config.');
        return false; // Не указана требуемая версия для платформы
      }

      final requiredVersion = Version.parse(requiredVersionStr);
      // Извлекаем полный buildNumber из строки версии
      String? requiredBuildNumber;
      if (requiredVersionStr.contains('+')) {
        requiredBuildNumber = requiredVersionStr.split('+')[1];
      }

      log('Current version: $currentVersion, Required version: $requiredVersion');
      log('Current build number: $currentBuildNumber, Required build number: $requiredBuildNumber');

      // Проверяем основную версию (без build number)
      final currentMainVersion = Version(
        currentVersion.major,
        currentVersion.minor,
        currentVersion.patch,
      );
      final requiredMainVersion = Version(
        requiredVersion.major,
        requiredVersion.minor,
        requiredVersion.patch,
      );

      // Обновление требуется если основная версия меньше требуемой или разные build number
      return currentMainVersion < requiredMainVersion ||
          (requiredBuildNumber != null &&
              currentBuildNumber != requiredBuildNumber);
    } catch (e) {
      log('Error parsing versions: $e');
      return false; // Ошибка парсинга версий, считаем, что обновление не нужно
    }
  }

  @override
  Future<String?> getStoreUrl() async {
    final appConfig = await _getAppConfig();
    if (appConfig == null) {
      return null;
    }

    if (Platform.isAndroid) {
      return appConfig['androidStoreUrl'] as String?;
    } else if (Platform.isIOS) {
      return appConfig['iosStoreUrl'] as String?;
    }
    return null;
  }
}
