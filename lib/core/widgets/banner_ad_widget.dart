import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Виджет для отображения баннерной рекламы Google AdMob
///
/// Автоматически определяет платформу и использует соответствующий
/// тестовый идентификатор рекламного блока:
/// - Android: ca-app-pub-3940256099942544/6300978111
/// - iOS: ca-app-pub-3940256099942544/2934735716
///
/// Пример использования:
/// ```dart
/// BannerAdWidget(
///   adSize: AdSize.banner,
///   alignment: Alignment.bottomCenter,
/// )
/// ```
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({
    super.key,
    this.adSize = AdSize.banner,
    this.alignment = Alignment.center,
    this.androidAdUnitId,
    this.iosAdUnitId,
  });

  /// Размер рекламного баннера
  ///
  /// По умолчанию используется стандартный баннер (320x50)
  final AdSize adSize;

  /// Выравнивание баннера
  ///
  /// По умолчанию баннер выравнивается по центру
  final Alignment alignment;

  /// Тестовый Ad Unit ID для Android
  ///
  /// По умолчанию используется тестовый ID от Google
  final String? androidAdUnitId;

  /// Тестовый Ad Unit ID для iOS
  ///
  /// По умолчанию используется тестовый ID от Google
  final String? iosAdUnitId;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  /// Получает Ad Unit ID в зависимости от платформы
  String get _adUnitId {
    // Используем переданные ID, если они есть
    if (Platform.isAndroid && widget.androidAdUnitId != null) {
      return widget.androidAdUnitId!;
    }
    if (Platform.isIOS && widget.iosAdUnitId != null) {
      return widget.iosAdUnitId!;
    }

    // Иначе используем тестовые ID от Google
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Android тестовый баннер
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // iOS тестовый баннер
    } else {
      // Для других платформ (web, desktop) используем Android тестовый ID
      return 'ca-app-pub-3940256099942544/6300978111';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  /// Загружает баннерную рекламу
  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (kDebugMode) {
            print('[BannerAdWidget] Баннерная реклама загружена');
          }
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            print(
              '[BannerAdWidget] Ошибка загрузки баннерной рекламы: ${error.message}',
            );
          }
          ad.dispose();
          setState(() {
            _isAdLoaded = false;
          });
        },
        onAdOpened: (_) {
          if (kDebugMode) {
            print('[BannerAdWidget] Баннерная реклама открыта');
          }
        },
        onAdClosed: (_) {
          if (kDebugMode) {
            print('[BannerAdWidget] Баннерная реклама закрыта');
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      // Показываем пустой контейнер, пока реклама загружается
      return const SizedBox.shrink();
    }

    return Align(
      alignment: widget.alignment,
      child: SizedBox(
        width: widget.adSize.width.toDouble(),
        height: widget.adSize.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
