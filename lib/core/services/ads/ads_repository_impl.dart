import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/services/ads/ads_repository.dart';

/// Реализация репозитория для работы с Google Mobile Ads
/// 
/// Использует тестовые идентификаторы рекламных блоков для проверки работы:
/// - Android Banner: ca-app-pub-3940256099942544/6300978111
/// - iOS Banner: ca-app-pub-3940256099942544/2934735716
/// - Android Interstitial: ca-app-pub-3940256099942544/1033173712
/// - iOS Interstitial: ca-app-pub-3940256099942544/4411468910
/// - Android Rewarded: ca-app-pub-3940256099942544/5224354917
/// - iOS Rewarded: ca-app-pub-3940256099942544/1712485313
@Singleton(as: AdsRepository)
class AdsRepositoryImpl implements AdsRepository {
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialAdLoaded = false;
  bool _isRewardedAdLoaded = false;

  @override
  Future<void> init() async {
    try {
      // Инициализируем Mobile Ads SDK
      await MobileAds.instance.initialize();
      
      if (kDebugMode) {
        print('[AdsRepository] Mobile Ads SDK инициализирован');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AdsRepository] Ошибка инициализации Mobile Ads SDK: $e');
      }
      rethrow;
    }
  }

  @override
  Future<bool> loadInterstitialAd(String adUnitId) async {
    try {
      if (kDebugMode) {
        print('[AdsRepository] Загрузка межстраничной рекламы: $adUnitId');
      }

      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            _isInterstitialAdLoaded = true;
            
            if (kDebugMode) {
              print('[AdsRepository] Межстраничная реклама загружена');
            }

            // ┌─────────────────────────────────────────────────────────┐
            // │ Устанавливаем базовый callback для закрытия рекламы     │
            // │ Пользовательский callback будет добавлен при показе     │
            // └─────────────────────────────────────────────────────────┘
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (InterstitialAd ad) {
                if (kDebugMode) {
                  print('[AdsRepository] Межстраничная реклама закрыта');
                }
                ad.dispose();
                _interstitialAd = null;
                _isInterstitialAdLoaded = false;
              },
              onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
                if (kDebugMode) {
                  print('[AdsRepository] Ошибка показа межстраничной рекламы: ${error.message}');
                }
                ad.dispose();
                _interstitialAd = null;
                _isInterstitialAdLoaded = false;
              },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            if (kDebugMode) {
              print('[AdsRepository] Ошибка загрузки межстраничной рекламы: ${error.message}');
            }
            _isInterstitialAdLoaded = false;
          },
        ),
      );

      // Ждем немного, чтобы реклама успела загрузиться
      await Future.delayed(const Duration(milliseconds: 500));
      
      return _isInterstitialAdLoaded;
    } catch (e) {
      if (kDebugMode) {
        print('[AdsRepository] Исключение при загрузке межстраничной рекламы: $e');
      }
      _isInterstitialAdLoaded = false;
      return false;
    }
  }

  /// Callback для закрытия рекламы (устанавливается при показе)
  VoidCallback? _onAdClosedCallback;

  @override
  Future<bool> showInterstitialAd({VoidCallback? onAdClosed}) async {
    if (!_isInterstitialAdLoaded || _interstitialAd == null) {
      if (kDebugMode) {
        print('[AdsRepository] Межстраничная реклама не загружена');
      }
      return false;
    }

    try {
      // ┌─────────────────────────────────────────────────────────┐
      // │ Сохраняем callback для вызова при закрытии рекламы      │
      // └─────────────────────────────────────────────────────────┘
      _onAdClosedCallback = onAdClosed;

      // ┌─────────────────────────────────────────────────────────┐
      // │ Обновляем callback для закрытия рекламы, если он был   │
      // │ передан. Сохраняем оригинальный callback и добавляем   │
      // │ вызов пользовательского callback                        │
      // └─────────────────────────────────────────────────────────┘
      if (_interstitialAd != null) {
        final originalCallback = _interstitialAd!.fullScreenContentCallback;
        
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (InterstitialAd ad) {
            // Вызываем оригинальный callback, если он был
            originalCallback?.onAdDismissedFullScreenContent?.call(ad);
            // Вызываем пользовательский callback
            _onAdClosedCallback?.call();
            _onAdClosedCallback = null;
            // Очищаем рекламу
            ad.dispose();
            _interstitialAd = null;
            _isInterstitialAdLoaded = false;
          },
          onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
            // Вызываем оригинальный callback, если он был
            originalCallback?.onAdFailedToShowFullScreenContent?.call(ad, error);
            // Очищаем callback
            _onAdClosedCallback = null;
            // Очищаем рекламу
            ad.dispose();
            _interstitialAd = null;
            _isInterstitialAdLoaded = false;
          },
          onAdShowedFullScreenContent:
              originalCallback?.onAdShowedFullScreenContent,
          onAdImpression: originalCallback?.onAdImpression,
          onAdClicked: originalCallback?.onAdClicked,
        );
      }

      await _interstitialAd!.show();
      if (kDebugMode) {
        print('[AdsRepository] Межстраничная реклама показана');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[AdsRepository] Ошибка показа межстраничной рекламы: $e');
      }
      _onAdClosedCallback = null;
      return false;
    }
  }

  @override
  Future<bool> loadRewardedAd(String adUnitId) async {
    try {
      // ┌─────────────────────────────────────────────────────────┐
      // │ Проверяем, не загружена ли уже реклама                   │
      // │ Если загружена, возвращаем true без повторной загрузки  │
      // └─────────────────────────────────────────────────────────┘
      if (_isRewardedAdLoaded && _rewardedAd != null) {
        if (kDebugMode) {
          print('[AdsRepository] Реклама за вознаграждение уже загружена');
        }
        return true;
      }

      if (kDebugMode) {
        print('[AdsRepository] Загрузка рекламы за вознаграждение: $adUnitId');
      }

      // ┌─────────────────────────────────────────────────────────┐
      // │ Используем Completer для правильного ожидания загрузки  │
      // │ Реклама загружается асинхронно через callback, поэтому  │
      // │ нужно дождаться его вызова                               │
      // └─────────────────────────────────────────────────────────┘
      final completer = Completer<bool>();

      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
            
            if (kDebugMode) {
              print('[AdsRepository] Реклама за вознаграждение загружена');
            }

            // ┌─────────────────────────────────────────────────────────┐
            // │ Устанавливаем callback для закрытия рекламы            │
            // └─────────────────────────────────────────────────────────┘
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (RewardedAd ad) {
                if (kDebugMode) {
                  print('[AdsRepository] Реклама за вознаграждение закрыта');
                }
                ad.dispose();
                _rewardedAd = null;
                _isRewardedAdLoaded = false;
              },
              onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
                if (kDebugMode) {
                  print('[AdsRepository] Ошибка показа рекламы за вознаграждение: ${error.message}');
                }
                ad.dispose();
                _rewardedAd = null;
                _isRewardedAdLoaded = false;
              },
            );

            // ┌─────────────────────────────────────────────────────────┐
            // │ Завершаем Completer с успешным результатом             │
            // └─────────────────────────────────────────────────────────┘
            if (!completer.isCompleted) {
              completer.complete(true);
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            if (kDebugMode) {
              print('[AdsRepository] Ошибка загрузки рекламы за вознаграждение: ${error.message}');
            }
            _isRewardedAdLoaded = false;
            
            // ┌─────────────────────────────────────────────────────────┐
            // │ Завершаем Completer с ошибкой                            │
            // └─────────────────────────────────────────────────────────┘
            if (!completer.isCompleted) {
              completer.complete(false);
            }
          },
        ),
      );

      // ┌─────────────────────────────────────────────────────────┐
      // │ Ждем завершения загрузки через Completer                 │
      // │ Устанавливаем таймаут на случай, если загрузка зависнет │
      // └─────────────────────────────────────────────────────────┘
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (kDebugMode) {
            print('[AdsRepository] Таймаут загрузки рекламы за вознаграждение');
          }
          _isRewardedAdLoaded = false;
          return false;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('[AdsRepository] Исключение при загрузке рекламы за вознаграждение: $e');
      }
      _isRewardedAdLoaded = false;
      return false;
    }
  }

  @override
  Future<bool> showRewardedAd({
    required Function(String rewardType, int rewardAmount) onRewarded,
  }) async {
    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      if (kDebugMode) {
        print('[AdsRepository] Реклама за вознаграждение не загружена');
      }
      return false;
    }

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          if (kDebugMode) {
            print('[AdsRepository] Пользователь получил награду: ${reward.type}, ${reward.amount}');
          }
          onRewarded(reward.type, reward.amount.toInt());
        },
      );
      
      if (kDebugMode) {
        print('[AdsRepository] Реклама за вознаграждение показана');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[AdsRepository] Ошибка показа рекламы за вознаграждение: $e');
      }
      return false;
    }
  }

  @override
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;

  @override
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
}

