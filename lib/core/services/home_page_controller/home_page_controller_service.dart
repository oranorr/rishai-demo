import 'package:flutter/material.dart';

/// [HomePageControllerService]
/// Абстрактный интерфейс для управления контроллерами HomePage
/// Позволяет регистрировать и управлять ScrollController и PageController
/// из любого места приложения
abstract class HomePageControllerService {
  // ==================== ScrollController методы ====================

  /// Регистрирует ScrollController для использования
  /// Должен быть вызван при инициализации HomePage
  void registerScrollController(ScrollController controller);

  /// Отменяет регистрацию ScrollController
  /// Должен быть вызван при dispose HomePage
  void unregisterScrollController();

  /// Проверяет, зарегистрирован ли ScrollController
  bool get hasScrollController;

  /// Прокручивает список вниз до конца с анимацией
  ///
  /// [duration] - продолжительность анимации (по умолчанию 300ms)
  /// [curve] - кривая анимации (по умолчанию easeInOut)
  ///
  /// Возвращает true, если прокрутка выполнена успешно,
  /// false, если контроллер не зарегистрирован
  Future<bool> scrollToBottom({
    Duration? duration,
    Curve? curve,
  });

  /// Прокручивает список к определенной позиции с анимацией
  ///
  /// [offset] - целевое смещение в пикселях
  /// [duration] - продолжительность анимации (по умолчанию 300ms)
  /// [curve] - кривая анимации (по умолчанию easeInOut)
  ///
  /// Возвращает true, если прокрутка выполнена успешно,
  /// false, если контроллер не зарегистрирован
  Future<bool> scrollToOffset({
    required double offset,
    Duration? duration,
    Curve? curve,
  });

  /// Прокручивает список вниз с плавной анимацией
  ///
  /// [delta] - величина прокрутки в пикселях (по умолчанию 100)
  /// [duration] - продолжительность анимации (по умолчанию 300ms)
  /// [curve] - кривая анимации (по умолчанию easeInOut)
  ///
  /// Возвращает true, если прокрутка выполнена успешно,
  /// false, если контроллер не зарегистрирован
  Future<bool> scrollDown({
    double? delta,
    Duration? duration,
    Curve? curve,
  });

  // ==================== PageController методы ====================

  /// Регистрирует PageController для использования
  /// Должен быть вызван при инициализации HomeScreen
  void registerPageController(PageController controller);

  /// Отменяет регистрацию PageController
  /// Должен быть вызван при dispose HomeScreen
  void unregisterPageController();

  /// Проверяет, зарегистрирован ли PageController
  bool get hasPageController;

  /// Получает текущую страницу
  /// Возвращает индекс текущей страницы или null, если контроллер не доступен
  int? get currentPage;

  /// ValueNotifier для отслеживания изменений текущей страницы
  /// Можно использовать для подписки на изменения страницы
  ValueNotifier<int> get currentPageNotifier;

  /// Переход на страницу с анимацией
  ///
  /// [page] - индекс целевой страницы (0-4)
  /// [duration] - продолжительность анимации (по умолчанию 150ms из Durations.short4)
  /// [curve] - кривая анимации (по умолчанию Curves.ease)
  ///
  /// Возвращает true, если переход выполнен успешно,
  /// false, если контроллер не зарегистрирован
  Future<bool> navigateToPage({
    required int page,
    Duration? duration,
    Curve? curve,
  });

  /// Мгновенный переход на страницу без анимации
  ///
  /// [page] - индекс целевой страницы (0-4)
  ///
  /// Возвращает true, если переход выполнен успешно,
  /// false, если контроллер не зарегистрирован
  bool jumpToPage(int page);

  /// Получает PageController для прямого доступа (если требуется)
  /// Рекомендуется использовать методы сервиса вместо прямого доступа
  PageController? get pageController;
}
