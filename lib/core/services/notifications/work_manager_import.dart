// Условный импорт для WorkManager
// На Android импортирует реальный WorkManager, на iOS - заглушку

export 'package:rishai/core/services/notifications/android_work_manager_service.dart'
    if (dart.library.html) 'package:rishai/core/services/notifications/stub_work_manager_service.dart';
