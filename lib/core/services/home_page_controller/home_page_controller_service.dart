import 'package:flutter/material.dart';

/// [HomePageControllerService]
/// Абстрактный интерфейс для управления контроллерами HomePage
/// Позволяет регистрировать и управлять ScrollController и другими контроллерами
/// из любого места приложения
abstract class HomePageControllerService {
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
}
