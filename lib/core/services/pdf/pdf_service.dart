import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:rishai/core/services/analytics/analytics_repository_impl.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:share_plus/share_plus.dart';

/// [PdfServiceException] Кастомное исключение для ошибок генерации PDF
class PdfServiceException implements Exception {
  final String message;
  PdfServiceException(this.message);

  @override
  String toString() => message;
}

class PdfService {
  /// [generateShoppingList] Генерирует PDF со списком покупок и открывает диалог шаринга
  /// 
  /// [sharePositionOrigin] - позиция для share sheet на iOS (особенно важно для iPad).
  /// Если не указана, будет использован центр экрана.
  /// 
  /// Может выбросить [PdfServiceException] в следующих случаях:
  /// - Пустой список ингредиентов
  /// - Ошибка загрузки ресурсов (шрифт, логотип)
  /// - Ошибка доступа к файловой системе
  /// - Ошибка записи файла
  /// - Ошибка Share API
  Future<void> generateShoppingList(
    List<Ingredient> ingredients, {
    Rect? sharePositionOrigin,
  }) async {
    try {
      // [validateIngredients] Проверяем, что список ингредиентов не пустой
      if (ingredients.isEmpty) {
        throw PdfServiceException(
          'Cannot generate grocery list: no ingredients found',
        );
      }

      // [trackExport] Трекинг экспорта списка покупок
      await analytics.logCustomEvent(
        name: 'export_grocery_list',
        parameters: {
          'ingredients_count': ingredients.length,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      final pdf = pw.Document();

      // [loadFont] Загружаем шрифт с обработкой ошибок
      ByteData fontData;
      try {
        fontData = await rootBundle.load('font/proximanova.ttf');
      } catch (e) {
        throw PdfServiceException(
          'Failed to load font: ${e.toString()}',
        );
      }
      final ttf = pw.Font.ttf(fontData);

      // [loadLogo] Загружаем логотип с обработкой ошибок
      ByteData logoData;
      try {
        logoData = await rootBundle.load('assets/logo.png');
      } catch (e) {
        throw PdfServiceException(
          'Failed to load logo: ${e.toString()}',
        );
      }
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      final logoImage = pw.MemoryImage(logoBytes);

    // Разбиваем ингредиенты на группы по 20 элементов для каждой страницы
    const int itemsPerPage = 20;
    final List<List<Ingredient>> pages = [];

    for (var i = 0; i < ingredients.length; i += itemsPerPage) {
      pages.add(
        ingredients.sublist(
          i,
          i + itemsPerPage > ingredients.length
              ? ingredients.length
              : i + itemsPerPage,
        ),
      );
    }

    // Создаем страницы
    for (final pageIngredients in pages) {
      final isFirstPage = pages.indexOf(pageIngredients) == 0;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                // Полупрозрачный логотип как водяной знак (на всех страницах)
                pw.Positioned(
                  top: 200,
                  left: 0,
                  right: 0,
                  child: pw.Opacity(
                    opacity: 0.03,
                    child: pw.Center(
                      child: pw.Image(logoImage, width: 400),
                    ),
                  ),
                ),
                // Основной контент
                pw.Padding(
                  padding: const pw.EdgeInsets.all(40),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Логотип только на первой странице
                      if (isFirstPage) ...[
                        pw.Center(
                          child: pw.Image(logoImage, width: 150),
                        ),
                        pw.SizedBox(height: 30),
                      ],
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Grocery list',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                          // Добавляем номер страницы
                          pw.Text(
                            'Page ${pages.indexOf(pageIngredients) + 1} of ${pages.length}',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 14,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 20),
                      ...pageIngredients.map((ingredient) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          child: pw.Row(
                            children: [
                              pw.Container(
                                width: 20,
                                height: 20,
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(),
                                  shape: pw.BoxShape.circle,
                                ),
                              ),
                              pw.SizedBox(width: 10),
                              pw.Expanded(
                                child: pw.Text(
                                  '${ingredient.title}: ${ingredient.quantity} ${ingredient.unit.toDisplayString()}',
                                  style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 14,
                                    color: PdfColors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

      // [saveFile] Сохраняем файл с обработкой ошибок доступа к файловой системе
      Directory output;
      try {
        output = await getTemporaryDirectory();
      } catch (e) {
        throw PdfServiceException(
          'Failed to access temporary directory: ${e.toString()}',
        );
      }

      // [createFile] Создаем уникальное имя файла с timestamp для избежания конфликтов
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${output.path}/grocery_list_$timestamp.pdf';
      final file = File(filePath);

      // [writeFile] Записываем PDF в файл с обработкой ошибок
      try {
        final pdfBytes = await pdf.save();
        await file.writeAsBytes(pdfBytes);
      } catch (e) {
        throw PdfServiceException(
          'Failed to save PDF file: ${e.toString()}',
        );
      }

      // [verifyFile] Проверяем, что файл был создан и доступен
      if (!await file.exists()) {
        throw PdfServiceException(
          'PDF file was not created successfully',
        );
      }

      // [verifyFileSize] Проверяем размер файла, чтобы убедиться, что он был записан правильно
      // На iOS файл может существовать, но быть пустым из-за проблем с правами доступа
      final fileSize = await file.length();
      if (fileSize == 0) {
        throw PdfServiceException(
          'PDF file is empty. Please try again.',
        );
      }

      // [shareFile] Делимся файлом с обработкой ошибок Share API
      // На iOS Share.shareXFiles требует sharePositionOrigin (особенно на iPad)
      // Если позиция не передана, используем центр экрана как fallback
      try {
        // [prepareSharePosition] Подготавливаем позицию для share sheet
        // На iOS это обязательно, особенно на iPad
        // Используем разумное значение по умолчанию - центр экрана с размером кнопки
        Rect? position = sharePositionOrigin;
        
        if (Platform.isIOS && position == null) {
          // [getDefaultPosition] Получаем размер экрана для fallback позиции
          // Используем WidgetsBinding для получения физического размера экрана
          try {
            final views = WidgetsBinding.instance.platformDispatcher.views;
            if (views.isNotEmpty) {
              final window = views.first;
              final screenSize = window.physicalSize / window.devicePixelRatio;
              
              // [centerPosition] Используем центр экрана с разумным размером кнопки (100x50)
              // Это гарантирует, что share sheet появится в центре экрана
              // iOS требует ненулевой размер, поэтому используем минимальный валидный размер
              final buttonWidth = 100.0;
              final buttonHeight = 50.0;
              position = Rect.fromLTWH(
                (screenSize.width - buttonWidth) / 2, // Центр по X
                screenSize.height - 150, // Немного выше нижнего края
                buttonWidth,
                buttonHeight,
              );
            } else {
              // [fallbackSize] Если не удалось получить размер экрана, используем стандартный размер
              // Это гарантирует валидную позицию с ненулевым размером
              position = const Rect.fromLTWH(0, 0, 100, 50);
            }
          } catch (e) {
            // [errorFallback] В случае ошибки используем стандартный размер
            print('[PdfService.generateShoppingList] Error getting screen size: $e, using fallback');
            position = const Rect.fromLTWH(0, 0, 100, 50);
          }
        }

        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Grocery list',
          text: 'My grocery list',
          sharePositionOrigin: position,
        );
      } catch (e) {
        // Если ошибка при шаринге, но файл создан - это не критично
        // Пользователь может попробовать еще раз
        throw PdfServiceException(
          'Failed to share file. Please try again: ${e.toString()}',
        );
      }
    } catch (e) {
      // [rethrowPdfException] Если это уже наше исключение - пробрасываем дальше
      if (e is PdfServiceException) {
        rethrow;
      }
      // [wrapGenericException] Обертываем другие исключения в наше
      throw PdfServiceException(
        'Unexpected error while generating grocery list: ${e.toString()}',
      );
    }
  }
}
