# Google Mobile Ads Integration

Интеграция Google Mobile Ads (AdMob) в приложение для отображения рекламы.

## Архитектура

Интеграция реализована по паттерну Repository:
- **`AdsRepository`** - абстрактный интерфейс для работы с рекламой
- **`AdsRepositoryImpl`** - реализация с использованием Google Mobile Ads SDK
- Регистрация через **Injectable/GetIt** для dependency injection

## Типы рекламы

### 1. Баннерная реклама (Banner Ad)
Используйте виджет `BannerAdWidget` для отображения баннерной рекламы:

```dart
import 'package:rishai/core/widgets/banner_ad_widget.dart';

// В вашем виджете
BannerAdWidget(
  adSize: AdSize.banner, // или AdSize.largeBanner, AdSize.mediumRectangle
  alignment: Alignment.bottomCenter,
)
```

### 2. Межстраничная реклама (Interstitial Ad)
Используйте `AdsRepository` для загрузки и показа межстраничной рекламы:

```dart
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/ads/ads_repository.dart';

final adsRepository = getIt<AdsRepository>();

// Загрузка рекламы
await adsRepository.loadInterstitialAd('ca-app-pub-3940256099942544/1033173712');

// Показ рекламы (например, при переходе между экранами)
if (adsRepository.isInterstitialAdLoaded) {
  await adsRepository.showInterstitialAd();
}
```

### 3. Реклама за вознаграждение (Rewarded Ad)
Используйте `AdsRepository` для рекламы за вознаграждение:

```dart
final adsRepository = getIt<AdsRepository>();

// Загрузка рекламы
await adsRepository.loadRewardedAd('ca-app-pub-3940256099942544/5224354917');

// Показ рекламы с callback для награды
if (adsRepository.isRewardedAdLoaded) {
  await adsRepository.showRewardedAd(
    onRewarded: (String rewardType, int rewardAmount) {
      print('Пользователь получил награду: $rewardType, $rewardAmount');
      // Ваша логика обработки награды
    },
  );
}
```

## Тестовые Ad Unit ID

В данный момент используются тестовые идентификаторы от Google:

### Android
- **Banner**: `ca-app-pub-3940256099942544/6300978111`
- **Interstitial**: `ca-app-pub-3940256099942544/1033173712`
- **Rewarded**: `ca-app-pub-3940256099942544/5224354917`

### iOS
- **Banner**: `ca-app-pub-3940256099942544/2934735716`
- **Interstitial**: `ca-app-pub-3940256099942544/4411468910`
- **Rewarded**: `ca-app-pub-3940256099942544/1712485313`

## Переход на продакшн

Для использования реальных рекламных блоков:

1. Зарегистрируйтесь в [Google AdMob](https://admob.google.com/)
2. Создайте приложение для Android и iOS
3. Создайте рекламные блоки (Ad Units) для каждого типа рекламы
4. Замените тестовые App ID в:
   - `android/app/src/main/AndroidManifest.xml` (для Android)
   - `ios/Runner/Info.plist` (для iOS)
5. Замените тестовые Ad Unit ID в коде на реальные

## Инициализация

SDK автоматически инициализируется в `main.dart` при запуске приложения. 
Ручная инициализация не требуется.

## Логирование

В debug режиме все операции с рекламой логируются в консоль с префиксом `[AdsRepository]` или `[BannerAdWidget]`.

