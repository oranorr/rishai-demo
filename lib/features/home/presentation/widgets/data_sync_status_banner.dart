import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/extensions/date_time_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_state.dart';

/// [DataSyncStatusBanner] Плашка синхронизации WHOOP под шапкой домашнего экрана.
///
/// Состояния: catching up (spinner), synced fresh (зелёный timestamp + галочка),
/// synced updated (accent timestamp + галочка).
class DataSyncStatusBanner extends StatelessWidget {
  const DataSyncStatusBanner({
    required this.phase,
    required this.lastSyncedAt,
    super.key,
  });

  final WhoopSyncBannerPhase phase;
  final DateTime? lastSyncedAt;

  bool get _isVisible => phase != WhoopSyncBannerPhase.hidden;

  @override
  Widget build(BuildContext context) {
    final isCatchingUp = phase == WhoopSyncBannerPhase.catchingUp;
    final isFresh = phase == WhoopSyncBannerPhase.syncedFresh;
    // [displayTime] При catching up — последний успешный sync; иначе время текущего.
    final displayTime = lastSyncedAt ?? DateTime.now();
    final timestampColor = isFresh ? RishColors.success : RishColors.primary;
    // [bannerHeight] Одна высота для catching up и synced — без скачка layout.
    final bannerHeight = 52.h;

    return IgnorePointer(
      ignoring: !_isVisible,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        offset: _isVisible ? Offset.zero : const Offset(0, -0.5),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: _isVisible ? 1 : 0,
          child: Material(
            color: Colors.transparent,
            child: Container(
              height: bannerHeight,
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                // [decoration] Чуть светлее карточек (formBackgroun), чтобы не сливаться с контентом.
                color: const Color(0xFF1C1A32),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: RishColors.textPrimary.withValues(alpha: 0.14),
                ),
                boxShadow: [
                  // [boxShadow] Лёгкое белое свечение — плашка «парит» над тёмным UI.
                  BoxShadow(
                    color: RishColors.textPrimary.withValues(alpha: 0.12),
                    blurRadius: 14,
                  ),
                  BoxShadow(
                    color: RishColors.textPrimary.withValues(alpha: 0.06),
                    blurRadius: 1,
                    offset: const Offset(0, -1),
                  ),
                  // [boxShadow] Глубина вниз — отделение от скролла под плашкой.
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 20,
                    spreadRadius: -2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_outlined,
                    size: 22.sp,
                    color: RishColors.textPrimary,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      // [FittedBox] Ужимаем шрифт, если мало места — без троеточия.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          isCatchingUp ? 'DATA CATCHING UP' : 'SYNCED TO',
                          maxLines: 1,
                          softWrap: false,
                          style: context.styles.regularMedium.copyWith(
                            color: RishColors.textPrimary,
                            letterSpacing: isCatchingUp ? 0.25 : 0.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // [rightColumn] Timestamp + индикатор; без дубля «SYNCED TO» — больше места слева.
                  Text(
                    displayTime.formatAsSyncTimestamp(),
                    style: context.styles.regularMedium.copyWith(
                      color: timestampColor,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: isCatchingUp
                        ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: RishColors.textPrimary,
                          )
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isFresh
                                    ? RishColors.success
                                    : RishColors.textSecondary,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.check,
                              size: 14.sp,
                              color: isFresh
                                  ? RishColors.success
                                  : RishColors.textPrimary,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
