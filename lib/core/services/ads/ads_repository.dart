import 'package:flutter/material.dart';

/// Абстрактный репозиторий для работы с рекламой Google AdMob
/// 
/// Предоставляет интерфейс для управления различными типами рекламы:
/// - Баннерная реклама (Banner Ad)
/// - Межстраничная реклама (Interstitial Ad)
/// - Рекламная реклама за вознаграждение (Rewarded Ad)
abstract class AdsRepository {
  /// Инициализация рекламного SDK
  /// 
  /// Должен быть вызван при запуске приложения, до использования
  /// любых рекламных виджетов
  Future<void> init();

  /// Загружает межстраничную рекламу
  /// 
  /// [adUnitId] - идентификатор рекламного блока
  /// Возвращает true, если реклама успешно загружена
  Future<bool> loadInterstitialAd(String adUnitId);

  /// Показывает межстраничную рекламу
  /// 
  /// [onAdClosed] - опциональный callback, вызываемый при закрытии рекламы
  /// Возвращает true, если реклама была показана
  Future<bool> showInterstitialAd({VoidCallback? onAdClosed});

  /// Загружает рекламу за вознаграждение
  /// 
  /// [adUnitId] - идентификатор рекламного блока
  /// Возвращает true, если реклама успешно загружена
  Future<bool> loadRewardedAd(String adUnitId);

  /// Показывает рекламу за вознаграждение
  /// 
  /// [onRewarded] - callback, вызываемый при получении награды
  /// Возвращает true, если реклама была показана
  Future<bool> showRewardedAd({
    required Function(String rewardType, int rewardAmount) onRewarded,
  });

  /// Проверяет, загружена ли межстраничная реклама
  bool get isInterstitialAdLoaded;

  /// Проверяет, загружена ли реклама за вознаграждение
  bool get isRewardedAdLoaded;
}

