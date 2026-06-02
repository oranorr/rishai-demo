const String onboardWatched = 'watchedOnboard';
const String shouldRedirectAfterPaywallKey = 'shouldRedirectAfterPaywall';
const String isLoggedIn = 'isLoggedIn';
const String whoopAccessToken = 'whoopAccessToken';
const String whoopRefreshToken = 'whoopRefreshToken';
const String calibrating = 'calibratingCompleteDate';
const String notesTime = 'notesTime';
const String acceptedWhoopDisclaimer = 'acceptedWhoopDisclaimer';
const String whoopExpiresAt = 'whoopExpiresAt';

/// JWT Pivot User API (после `/auth/verify-otp`), отдельно от WHOOP-токенов.
const String appAccessToken = 'appAccessToken';
const String appRefreshToken = 'appRefreshToken';

/// ISO8601 или ms — время истечения access (клиентский расчёт: now + expires_in).
const String appAccessTokenExpiresAt = 'appAccessTokenExpiresAt';

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

/// [daysSyncUserId] userId, для которого сохранён [daysServerTotal].
const String daysSyncUserId = 'daysSyncUserId';

/// [daysServerTotal] Кол-во дней на сервере при последнем успешном sync.
const String daysServerTotal = 'daysServerTotal';
