// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/services/ads/ads_repository.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository_impl.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/cpi.dart';
import 'package:rishai/core/widgets/dialog.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/chat/data/remote_data_source/llm_proxy_client.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_state.dart';

part 'comparison_widget.dart';
part 'recommendations_widget.dart';

class WellnessPage extends StatefulWidget {
  const WellnessPage({super.key});

  @override
  State<WellnessPage> createState() => _WellnessPageState();
}

class _WellnessPageState extends State<WellnessPage> {
  /// Локальный флаг доступа к полной версии страницы
  ///
  /// Изначально равен статусу подписки adapty.isActive
  /// После просмотра рекламы устанавливается в true
  late bool _hasAccess;

  /// Флаг загрузки рекламы
  ///
  /// Используется для отображения индикатора загрузки (CPI)
  /// вместо кнопки "Watch ad" во время загрузки рекламы
  bool _isLoadingAd = false;

  /// Репозиторий для работы с рекламой
  final _adsRepository = getIt<AdsRepository>();

  @override
  void initState() {
    super.initState();
    // ┌─────────────────────────────────────────────────────────┐
    // │ Инициализируем флаг доступа значением из adapty        │
    // │ После просмотра рекламы он будет обновлен через setState│
    // └─────────────────────────────────────────────────────────┘
    _hasAccess = adapty.isActive;
  }

  /// ┌─────────────────────────────────────────────────────────┐
  /// │ Обработчик нажатия на кнопку "Watch ad"                 │
  /// │                                                         │
  /// │ 1. Показывает индикатор загрузки (CPI)                  │
  /// │ 2. Проверяет, не загружена ли уже реклама               │
  /// │ 3. Загружает рекламу за вознаграждение (если нужно)     │
  /// │ 4. После загрузки показывает рекламу                    │
  /// │ 5. Доступ предоставляется ТОЛЬКО после полного          │
  /// │    просмотра рекламы (не при закрытии)                  │
  /// │                                                         │
  /// │ Callback onRewarded вызывается только когда            │
  /// │ пользователь досмотрел рекламу до конца                │
  /// └─────────────────────────────────────────────────────────┘
  Future<void> _handleWatchAd() async {
    // ┌─────────────────────────────────────────────────────────┐
    // │ Блокируем повторные нажатия во время загрузки          │
    // └─────────────────────────────────────────────────────────┘
    if (_isLoadingAd) {
      if (kDebugMode) {
        print(
          '[WellnessPage] Реклама уже загружается, игнорируем повторное нажатие',
        );
      }
      return;
    }

    try {
      // ┌─────────────────────────────────────────────────────────┐
      // │ Показываем индикатор загрузки вместо кнопки            │
      // └─────────────────────────────────────────────────────────┘
      if (mounted) {
        setState(() {
          _isLoadingAd = true;
        });
      }

      // ┌─────────────────────────────────────────────────────────┐
      // │ Определяем Ad Unit ID для Rewarded Ad в зависимости     │
      // │ от платформы (продакшн ID)                              │
      // └─────────────────────────────────────────────────────────┘
      final String adUnitId;
      if (Platform.isAndroid) {
        adUnitId =
            'ca-app-pub-9722388149022562/3705012456'; // Android Rewarded
      } else if (Platform.isIOS) {
        adUnitId =
            'ca-app-pub-9722388149022562/2962776426'; // iOS Rewarded
      } else {
        adUnitId =
            'ca-app-pub-9722388149022562/3705012456'; // По умолчанию Android
      }

      // ┌─────────────────────────────────────────────────────────┐
      // │ Проверяем, не загружена ли уже реклама                 │
      // │ Если не загружена, загружаем её                         │
      // └─────────────────────────────────────────────────────────┘
      bool loaded = _adsRepository.isRewardedAdLoaded;

      if (!loaded) {
        if (kDebugMode) {
          print('[WellnessPage] Начата загрузка рекламы за вознаграждение...');
        }

        // ┌─────────────────────────────────────────────────────────┐
        // │ Загружаем рекламу за вознаграждение                     │
        // │ Метод loadRewardedAd теперь правильно ждет загрузки    │
        // └─────────────────────────────────────────────────────────┘
        loaded = await _adsRepository.loadRewardedAd(adUnitId);
      } else {
        if (kDebugMode) {
          print('[WellnessPage] Реклама уже загружена, пропускаем загрузку');
        }
      }

      // ┌─────────────────────────────────────────────────────────┐
      // │ Скрываем индикатор загрузки после завершения           │
      // └─────────────────────────────────────────────────────────┘
      if (mounted) {
        setState(() {
          _isLoadingAd = false;
        });
      }

      // ┌─────────────────────────────────────────────────────────┐
      // │ Проверяем результат загрузки                            │
      // └─────────────────────────────────────────────────────────┘
      if (!loaded) {
        if (kDebugMode) {
          print('[WellnessPage] Не удалось загрузить рекламу');
        }
        // Показываем сообщение пользователю
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось загрузить рекламу. Попробуйте позже.'),
            ),
          );
        }
        return;
      }

      if (kDebugMode) {
        print('[WellnessPage] Реклама успешно загружена, показываем...');
      }

      // ┌─────────────────────────────────────────────────────────┐
      // │ Показываем рекламу за вознаграждение                    │
      // │                                                         │
      // │ ВАЖНО: onRewarded вызывается ТОЛЬКО когда пользователь  │
      // │ досмотрел рекламу до конца. Если пользователь закрыл    │
      // │ рекламу раньше времени, callback НЕ будет вызван      │
      // └─────────────────────────────────────────────────────────┘
      final shown = await _adsRepository.showRewardedAd(
        onRewarded: (String rewardType, int rewardAmount) {
          // ┌─────────────────────────────────────────────────────────┐
          // │ Пользователь досмотрел рекламу до конца и получил     │
          // │ награду. Обновляем состояние для отображения полной   │
          // │ версии страницы                                        │
          // └─────────────────────────────────────────────────────────┘
          if (mounted) {
            setState(() {
              _hasAccess = true;
            });

            if (kDebugMode) {
              print(
                '[WellnessPage] Реклама досмотрена до конца, доступ к полной версии предоставлен',
              );
              print(
                '[WellnessPage] Награда: тип=$rewardType, количество=$rewardAmount',
              );
            }
          }
        },
      );

      if (!shown && mounted) {
        if (kDebugMode) {
          print('[WellnessPage] Не удалось показать рекламу');
        }
        // Показываем сообщение пользователю
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось показать рекламу. Попробуйте позже.'),
          ),
        );
      }
    } catch (e) {
      // ┌─────────────────────────────────────────────────────────┐
      // │ Скрываем индикатор загрузки при ошибке                 │
      // └─────────────────────────────────────────────────────────┘
      if (mounted) {
        setState(() {
          _isLoadingAd = false;
        });
      }

      if (kDebugMode) {
        print('[WellnessPage] Ошибка при показе рекламы: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при показе рекламы: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WhoopBloc, WhoopState>(
      bloc: whoopBloc,
      builder: (context, state) {
        return RishScaffold(
          needsAppBar: true,
          implyLeading: true,
          appBar: AppBar(
            title: Row(
              children: [
                Text(
                  'Daily Nutritional Wellness',
                  style: context.styles.h2,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () async => RishiDialog.infoPopup(
                    context,
                    '''
The Daily Nutritional Wellness Score (DNWS) is your personal performance tracker and gives you a clear snapshot of how well you're fueling your body, measuring your nutritional consistency.

Our proprietary algorithm calculates a % score based on how closely your calorie and macro intake matches your daily targets.

Your Daily Nutritional Wellness score provides nutritional insights and personalized recommendations for dietary choices by Pivot's nutritional intelligence.

Your DNWS drops faster once you exceed 110% of your target intake, encouraging balance over excess.''',
                    title: 'Daily Nutritional Wellness',
                  ),
                  child: SvgPicture.asset('assets/icons/info_round.svg'),
                ),
              ],
            ),
          ),
          child: state.day.welnessEntity != null
              ? ListView(
                  children: [
                    _AnimationWidget(
                      welnessPercentage:
                          state.day.welnessEntity?.welnessPercentage ?? 0,
                    ),
                    SizedBox(height: 40.h),
                    // ┌─────────────────────────────────────────────────────────┐
                    // │ Показываем полную версию, если есть доступ             │
                    // │ (подписка ИЛИ просмотр рекламы)                        │
                    // └─────────────────────────────────────────────────────────┘
                    if (_hasAccess) ...[
                      const _RecommendationsWidget(),
                      SizedBox(height: 20.h),
                      const _ComparisonWidget(),
                    ] else ...[
                      _NoSubscriptionWidget(
                        onWatchAd: _handleWatchAd,
                        isLoadingAd: _isLoadingAd,
                      ),
                    ],
                  ],
                )
              : Column(
                  children: [
                    _AnimationWidget(
                      welnessPercentage:
                          state.day.welnessEntity?.welnessPercentage ?? 0,
                    ),
                    const Spacer(),
                    const _CaptureMeal(),
                  ],
                ),
        );
      },
    );
  }
}

class _AnimationWidget extends StatelessWidget {
  final double welnessPercentage;
  const _AnimationWidget({
    required this.welnessPercentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 311.h,
      decoration: BoxDecoration(
        // color: RishColors.formBackgroun,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              child: Image.asset('assets/images/wellness.png'),
            ),
            Align(
              child: Text(
                '${welnessPercentage.toStringAsFixed(0)}%',
                style: context.styles.h2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureMeal extends StatelessWidget {
  const _CaptureMeal({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 130.h,
      child: Column(
        children: [
          Text(
            "You haven't recorded anything yet. Please add a meal to your Food Diary.",
            style: context.styles.regularMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.h),
          RishButton.primary(
            title: 'Capture a meal',
            enabled: true,
            isLoading: false,
            action: () {
              appNavigationService.push(path: AppRoutes.diaryEntryPage.path);
            },
          ),
        ],
      ),
    );
  }
}

class _NoSubscriptionWidget extends StatelessWidget {
  const _NoSubscriptionWidget({
    required this.onWatchAd,
    required this.isLoadingAd,
  });

  /// Callback для обработки нажатия на кнопку "Watch ad"
  final VoidCallback onWatchAd;

  /// Флаг загрузки рекламы
  ///
  /// Если true, показывается индикатор загрузки (CPI) вместо кнопки
  final bool isLoadingAd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок с описанием преимуществ
        Text(
          'Daily Nutritional Wellness Insights',
          style: context.styles.h2,
        ),
        SizedBox(height: 16.h),

        // Описание преимуществ фичи
        Text(
          'Access Pivot\'s nutritional intelligence for personalized recommendations to optimize your daily nutrition',
          style: context.styles.regularMedium,
        ),
        SizedBox(height: 20.h),

        // Список преимуществ
        _buildBenefitItem(
          context,
          'Track your daily nutritional performance and wellness score',
        ),
        SizedBox(height: 12.h),
        _buildBenefitItem(
          context,
          'Receive personalized recommendations based on your intake, targets and dietary preferences',
        ),
        SizedBox(height: 12.h),
        _buildBenefitItem(
          context,
          'Compare your performance over time',
        ),
        SizedBox(height: 24.h),

        // Подпись о платной функции
        Text(
          'This is a premium feature available with a subscription or by watching an ad.',
          style: context.styles.regularSmall.copyWith(
            color: RishColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24.h),

        // Кнопка Upgrade
        RishButton.primary(
          title: 'Upgrade',
          enabled: true,
          isLoading: false,
          action: () {
            appNavigationService.go(path: AppRoutes.paywall.path);
          },
        ),
        SizedBox(height: 12.h),

        // ┌─────────────────────────────────────────────────────────┐
        // │ Показываем индикатор загрузки или кнопку "Watch ad"    │
        // │ в зависимости от состояния загрузки рекламы           │
        // └─────────────────────────────────────────────────────────┘
        if (isLoadingAd)
          const Center(
            child: RishCPI(),
          )
        else
          RishButton.teritary(
            title: 'Watch ad',
            textColor: RishColors.primary,
            borderColor: RishColors.primary,
            action: onWatchAd,
          ),
      ],
    );
  }

  /// Строит элемент списка преимуществ с буллетом
  Widget _buildBenefitItem(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Буллет
        Container(
          margin: EdgeInsets.only(top: 8.h, right: 12.w),
          width: 6.w,
          height: 6.h,
          decoration: const BoxDecoration(
            color: RishColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        // Текст преимущества
        Expanded(
          child: Text(
            text,
            style: context.styles.regularMedium,
          ),
        ),
      ],
    );
  }
}
