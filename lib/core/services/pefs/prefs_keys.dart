const String onboardWatched = 'watchedOnboard';
const String shouldRedirectAfterPaywallKey = 'shouldRedirectAfterPaywall';
const String isLoggedIn = 'isLoggedIn';
const String whoopAccessToken = 'whoopAccessToken';
const String whoopRefreshToken = 'whoopRefreshToken';
const String calibrating = 'calibratingCompleteDate';
const String notesTime = 'notesTime';
const String acceptedWhoopDisclaimer = 'acceptedWhoopDisclaimer';
const String whoopExpiresAt = 'whoopExpiresAt';

/// [wellnessTooltipViewed] Ключ для хранения состояния просмотра подсказки на wellness score
const String wellnessTooltipViewed = 'wellnessTooltipViewed';

/// Ключ для хранения версии схемы данных Hive
/// При изменении схемы данных (добавление/изменение HiveType/HiveField)
/// эта версия должна увеличиваться для автоматического сброса локальных данных
const String hiveSchemaVersion = 'hiveSchemaVersion';

/// [lastFreeUserPhotoUploadTime] Ключ для хранения времени последней загрузки фотографии
/// бесплатным пользователем (в миллисекундах с эпохи Unix)
const String lastFreeUserPhotoUploadTime = 'lastFreeUserPhotoUploadTime';

/// [freePaywallViewed] Ключ для хранения флага просмотра бесплатной версии paywall
/// Если флаг установлен, при следующих вызовах paywall будет показываться премиум версия
const String freePaywallViewed = 'freePaywallViewed';
