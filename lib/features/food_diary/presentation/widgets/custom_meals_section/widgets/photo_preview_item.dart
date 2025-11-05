import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rishai/core/theme/theme_colors.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PhotoPreviewItem Widget
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Превью выбранной фотографии с кнопкой удаления.
///
/// **UI/UX:**
/// - Квадратный контейнер 90x90
/// - Превью изображения с rounded corners
/// - Кнопка удаления в правом верхнем углу
/// - Тень для глубины
///
class PhotoPreviewItem extends StatelessWidget {
  const PhotoPreviewItem({
    required this.photo,
    required this.onRemove,
    super.key,
  });

  final XFile photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Контейнер с изображением
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 90.w,
              height: 90.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RishColors.stroke.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(photo.path),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => ColoredBox(
                    color: RishColors.formBackgroun,
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 40.w,
                      color: RishColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Кнопка удаления
          Positioned(
            top: 0,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(Icons.close, size: 14.w, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

