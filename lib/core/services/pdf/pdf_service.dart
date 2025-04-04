import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:rishai/core/services/analytics/analytics_repository_impl.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:share_plus/share_plus.dart';

class PdfService {
  Future<void> generateShoppingList(List<Ingredient> ingredients) async {
    // Трекинг экспорта списка покупок
    await analytics.logCustomEvent(
      name: 'export_grocery_list',
      parameters: {
        'ingredients_count': ingredients.length,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );

    final pdf = pw.Document();

    final font = await rootBundle.load('font/proximanova.ttf');
    final ttf = pw.Font.ttf(font);

    // Загружаем логотип
    final ByteData logoData = await rootBundle.load('assets/logo.png');
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

    // Сохраняем файл
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/grocery_list.pdf');
    await file.writeAsBytes(await pdf.save());

    // Делимся файлом
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Grocery list',
      text: 'My grocery list',
    );
  }
}
