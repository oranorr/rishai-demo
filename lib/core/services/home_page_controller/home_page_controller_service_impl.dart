import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/home_page_controller/home_page_controller_service.dart';

/// Глобальный экземпляр сервиса для удобного доступа
final homePageControllerService = getIt.get<HomePageControllerService>();

/// [HomePageControllerServiceImpl]
/// Реализация сервиса для управления контроллерами HomePage
///
/// Этот сервис предоставляет централизованный доступ к контроллерам
/// домашней страницы, позволяя управлять скроллингом и другими
/// функциями из любого места приложения
@Singleton(as: HomePageControllerService)
class HomePageControllerServiceImpl implements HomePageControllerService {
  /// ScrollController, зарегистрированный в HomePage
  ScrollController? _scrollController;

  // Константы по умолчанию для анимаций
  static const Duration _defaultDuration = Duration(milliseconds: 300);
  static const Curve _defaultCurve = Curves.easeInOut;
  static const double _defaultScrollDelta = 100;

  @override
  void registerScrollController(ScrollController controller) {
    _scrollController = controller;
    _logger('[HomePageControllerService] ScrollController зарегистрирован');
  }

  @override
  void unregisterScrollController() {
    _scrollController = null;
    _logger('[HomePageControllerService] ScrollController отменён');
  }

  @override
  bool get hasScrollController => _scrollController != null;

  @override
  Future<bool> scrollToBottom({
    Duration? duration,
    Curve? curve,
  }) async {
    if (_scrollController == null || !_scrollController!.hasClients) {
      _logger(
        '[HomePageControllerService] ScrollController не доступен для scrollToBottom',
      );
      return false;
    }

    try {
      // Получаем максимальную позицию скролла
      final maxScrollExtent = _scrollController!.position.maxScrollExtent;

      await _scrollController!.animateTo(
        maxScrollExtent,
        duration: duration ?? _defaultDuration,
        curve: curve ?? _defaultCurve,
      );

      _logger('[HomePageControllerService] Прокрутка вниз выполнена успешно');
      return true;
    } catch (e) {
      _logger('[HomePageControllerService] Ошибка при прокрутке вниз: $e');
      return false;
    }
  }

  @override
  Future<bool> scrollToOffset({
    required double offset,
    Duration? duration,
    Curve? curve,
  }) async {
    if (_scrollController == null || !_scrollController!.hasClients) {
      _logger(
        '[HomePageControllerService] ScrollController не доступен для scrollToOffset',
      );
      return false;
    }

    try {
      // Ограничиваем offset в пределах допустимых значений
      final maxScrollExtent = _scrollController!.position.maxScrollExtent;
      final minScrollExtent = _scrollController!.position.minScrollExtent;
      final targetOffset = offset.clamp(minScrollExtent, maxScrollExtent);

      await _scrollController!.animateTo(
        targetOffset,
        duration: duration ?? _defaultDuration,
        curve: curve ?? _defaultCurve,
      );

      _logger(
        '[HomePageControllerService] Прокрутка к позиции $targetOffset выполнена',
      );
      return true;
    } catch (e) {
      _logger(
        '[HomePageControllerService] Ошибка при прокрутке к позиции: $e',
      );
      return false;
    }
  }

  @override
  Future<bool> scrollDown({
    double? delta,
    Duration? duration,
    Curve? curve,
  }) async {
    if (_scrollController == null || !_scrollController!.hasClients) {
      _logger(
        '[HomePageControllerService] ScrollController не доступен для scrollDown',
      );
      return false;
    }

    try {
      final currentOffset = _scrollController!.offset;
      final targetOffset = currentOffset + (delta ?? _defaultScrollDelta);
      final maxScrollExtent = _scrollController!.position.maxScrollExtent;

      // Ограничиваем целевую позицию максимальным значением
      final clampedOffset = targetOffset.clamp(0.0, maxScrollExtent);

      await _scrollController!.animateTo(
        clampedOffset,
        duration: duration ?? _defaultDuration,
        curve: curve ?? _defaultCurve,
      );

      _logger(
        '[HomePageControllerService] Прокрутка на ${delta ?? _defaultScrollDelta}px выполнена',
      );
      return true;
    } catch (e) {
      _logger('[HomePageControllerService] Ошибка при прокрутке: $e');
      return false;
    }
  }

  /// Вспомогательный метод для логирования
  void _logger(String message) {
    log(message, name: 'HomePageControllerService');
  }
}
