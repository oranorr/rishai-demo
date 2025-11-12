import 'dart:developer';
import 'dart:io';

import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository_impl.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/core/widgets/snackbar.dart';

class Paywall extends StatefulWidget {
  const Paywall({super.key});

  @override
  State<Paywall> createState() => _PaywallState();
}

/// [PaywallViewState] Перечисление состояний paywall
///
/// [free] - Показывает функционал для бесплатных пользователей
/// [premium] - Показывает премиум версию с подпиской
enum PaywallViewState {
  free,
  premium,
}

/// [PaywallFeature] Структура для описания функции paywall
///
/// [title] - Название функции
/// [subtitle] - Дополнительное описание (опционально)
class PaywallFeature {
  const PaywallFeature({
    required this.title,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
}

class _PaywallState extends State<Paywall> {
  bool processing = false;
  late bool isFreeTrialAvailable;
  late String price;
  AdaptyPaywallProduct? selectedProduct;
  PaywallViewState _currentViewState = PaywallViewState.free;

  @override
  void initState() {
    super.initState();

    // [DEBUG MODE] Проверяем наличие продуктов перед доступом
    // В режиме симулятора products может быть пустым
    if (adapty.products.isNotEmpty) {
      // По умолчанию выбираем годовую подписку, если она доступна
      final annualProduct = adapty.products.firstWhere(
        (p) =>
            p.vendorProductId.contains('annual') ||
            p.vendorProductId == 'pivot_annual',
        orElse: () => adapty.products.first,
      );
      selectedProduct = annualProduct;
    } else {
      // В режиме симулятора products пустой, используем null
      selectedProduct = null;
    }

    // [ViewState] Проверяем, видел ли пользователь бесплатную версию
    // Если видел - сразу показываем премиум версию
    final hasViewedFreePaywall = prefsRepo.hasViewedFreePaywall();
    if (hasViewedFreePaywall) {
      _currentViewState = PaywallViewState.premium;
    } else {
      _currentViewState = PaywallViewState.free;
    }
  }

  @override
  Widget build(BuildContext context) {
    isFreeTrialAvailable = adapty.isTrialActive;
    // adapty.test();

    // [DEBUG MODE] Проверяем наличие selectedProduct (может быть null в режиме симулятора)
    if (selectedProduct == null) {
      // В режиме симулятора показываем заглушку с возможностью пропустить
      return RishScaffold(
        needsAppBar: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Simulator Mode',
                style: context.styles.h1,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                'Subscription purchases are not available in simulator mode.',
                style: context.styles.h3,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              RishButton.primary(
                title: 'Continue to App',
                enabled: true,
                isLoading: false,
                action: () => context.go(AppRoutes.homeScreen.path),
              ),
            ],
          ),
        ),
      );
    }

    // [ViewState Check] Проверяем, видел ли пользователь бесплатную версию
    // Если видел - показываем только премиум карточку с кнопкой назад
    final hasViewedFreePaywall = prefsRepo.hasViewedFreePaywall();
    if (hasViewedFreePaywall) {
      price = selectedProduct!.price.localizedString!;
      return _buildPremiumOnlyView(context);
    }

    // [Unified View] Единый экран с сегментированным контролом
    price = selectedProduct!.price.localizedString!;
    return _buildUnifiedView(context);
  }

  /// [buildPremiumOnlyView] Строит экран только с премиум карточкой
  ///
  /// Показывается когда пользователь уже видел бесплатную версию
  /// Включает кнопку назад для закрытия экрана
  Widget _buildPremiumOnlyView(BuildContext context) {
    return RishScaffold(
      needsAppBar: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 50.h),
              // [Back Button] Кнопка назад для закрытия экрана
              Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => appNavigationService.go(
                        path: AppRoutes.homeScreen.path,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: const BoxDecoration(
                          color: RishColors.formBackgroun,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: RishColors.textPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  // const Spacer(),
                  Align(
                    child: Text(
                      'Upgrade plan',
                      style: context.styles.h1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              // [Premium Card] Только премиум карточка
              _buildPremiumCard(context),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  /// [buildUnifiedView] Строит единый экран с сегментированным контролом
  ///
  /// Позволяет переключаться между Free и Premium планами
  Widget _buildUnifiedView(BuildContext context) {
    return RishScaffold(
      needsAppBar: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 50.h),
              // [Title] Заголовок "Choose a plan"
              Text(
                'Choose a plan',
                style: context.styles.h1,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              // [Segmented Control] Переключатель между Free и Premium
              _buildSegmentedControl(context),
              SizedBox(height: 24.h),
              // [Plan Card] Карточка с выбранным планом
              _buildPlanCard(context),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  /// [buildSegmentedControl] Строит сегментированный контрол для переключения планов
  Widget _buildSegmentedControl(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: RishColors.stroke,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // [Premium Button]
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentViewState = PaywallViewState.premium;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: _currentViewState == PaywallViewState.premium
                      ? RishColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Premium',
                  style: context.styles.h2.copyWith(
                    color: _currentViewState == PaywallViewState.premium
                        ? RishColors.formBackgroun
                        : RishColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          // [Free Button]
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentViewState = PaywallViewState.free;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: _currentViewState == PaywallViewState.free
                      ? RishColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Free',
                  style: context.styles.h2.copyWith(
                    color: _currentViewState == PaywallViewState.free
                        ? RishColors.formBackgroun
                        : RishColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// [buildPlanCard] Строит карточку с выбранным планом
  Widget _buildPlanCard(BuildContext context) {
    if (_currentViewState == PaywallViewState.free) {
      return _buildFreeCard(context);
    } else {
      return _buildPremiumCard(context);
    }
  }

  /// [buildFreeCard] Строит карточку для Free плана
  Widget _buildFreeCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: RishColors.textPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // [Title] Заголовок карточки
          Text(
            'Enjoy core features for free',
            style: context.styles.h2.copyWith(
              color: RishColors.formBackgroun,
            ),
          ),
          SizedBox(height: 16.h),
          // [Price] Цена "$0 / forever"
          Text(
            r'$0 / forever',
            style: context.styles.h1.copyWith(
              fontWeight: FontWeight.w900,
              color: RishColors.formBackgroun,
            ),
          ),
          SizedBox(height: 8.h),
          // [Subtitle] Подзаголовок
          Text(
            'Start free. Upgrade anytime.',
            style: context.styles.regularMedium.copyWith(
              color: RishColors.formBackgroun,
            ),
          ),
          SizedBox(height: 24.h),
          // [Divider] Разделитель
          Divider(
            color: RishColors.formBackgroun.withOpacity(0.3),
            thickness: 1,
          ),
          SizedBox(height: 24.h),
          // [Free Features] Список функций для бесплатных пользователей
          // Включенные функции (с галочкой)
          ..._freeFeaturesIncluded.map(
            (feature) => Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.check_circle,
                      color: RishColors.success,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature.title,
                          style: context.styles.regularLarge.copyWith(
                            color: RishColors.formBackgroun,
                          ),
                        ),
                        if (feature.subtitle != null) ...[
                          SizedBox(height: 4.h),
                          Text(
                            feature.subtitle!,
                            style: context.styles.regularSmall.copyWith(
                              color: RishColors.formBackgroun,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Исключенные функции (с X)
          ..._freeFeaturesExcluded.map(
            (feature) => Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.cancel,
                      color: RishColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      feature.title,
                      style: context.styles.regularLarge.copyWith(
                        color: RishColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 32.h),
          // [Select Button] Кнопка для выбора Free плана
          RishButton.primary(
            title: 'Subscribe',
            enabled: !processing,
            isLoading: processing,
            action: () async {
              // [SaveFlag] Сохраняем флаг, что пользователь видел бесплатную версию
              await prefsRepo.setFreePaywallViewed();
              log(
                '[Paywall] Флаг просмотра бесплатной версии сохранен',
                name: 'Paywall',
              );
              // Переходим на главный экран
              context.go(AppRoutes.homeScreen.path);
            },
          ),
        ],
      ),
    );
  }

  /// [buildPremiumCard] Строит карточку для Premium плана
  Widget _buildPremiumCard(BuildContext context) {
    // Получаем цены для месячной и годовой подписки
    final monthlyProduct = adapty.products.firstWhere(
      (p) =>
          p.vendorProductId.contains('month') ||
          p.vendorProductId == 'pivot_sub',
      orElse: () => adapty.products.first,
    );
    final annualProduct = adapty.products.firstWhere(
      (p) =>
          p.vendorProductId.contains('annual') ||
          p.vendorProductId == 'pivot_annual',
      orElse: () => adapty.products.length > 1
          ? adapty.products[1]
          : adapty.products.first,
    );

    final monthlyPrice = monthlyProduct.price.localizedString ?? r'$9.99';
    final annualPricePerMonth = annualProduct.price.amount / 12;
    final annualPricePerMonthString =
        '${annualProduct.price.currencySymbol}${annualPricePerMonth.toStringAsFixed(2)}';

    // [Price Display] Определяем, какой план выбран и показываем соответствующую цену
    final isAnnualSelected =
        selectedProduct?.vendorProductId == annualProduct.vendorProductId;
    final displayPrice = isAnnualSelected
        ? '$annualPricePerMonthString / month'
        : '$monthlyPrice / month';
    final billingText = isAnnualSelected
        ? 'Billed yearly or $monthlyPrice/month billed monthly.'
        : 'Billed monthly.';

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: RishColors.formBackgroun,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // [Title] Заголовок карточки
          Text(
            'Unlock advanced features',
            style: context.styles.h2,
          ),
          SizedBox(height: 16.h),
          // [Price] Цена с подзаголовком (зависит от выбранного плана)
          Text(
            displayPrice,
            style: context.styles.h1.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            billingText,
            style: context.styles.regularSmall.copyWith(
              color: RishColors.textSecondary,
            ),
          ),
          SizedBox(height: 24.h),

          // [Divider] Разделитель
          Divider(
            color: RishColors.textSecondary.withOpacity(0.3),
            thickness: 1,
          ),
          SizedBox(height: 24.h),
          // [Premium Features] Список всех премиум функций (все включены)
          ..._premiumFeatures.map(
            (feature) => Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.check_circle,
                      color: RishColors.success,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature.title,
                          style: context.styles.regularLarge,
                        ),
                        if (feature.subtitle != null) ...[
                          SizedBox(height: 4.h),
                          Text(
                            feature.subtitle!,
                            style: context.styles.regularSmall.copyWith(
                              color: RishColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24.h),
          // [Subscription Buttons] Кнопки выбора подписки
          _buildSubscriptionButtons(context, monthlyProduct, annualProduct),
          SizedBox(height: 32.h),
          // [Subscribe Button] Кнопка для покупки подписки
          RishButton.primary(
            title: 'Subscribe',
            enabled: !processing,
            isLoading: processing,
            action: () async {
              setState(() {
                processing = true;
              });
              final res = await adapty.makePurchase(product: selectedProduct!);
              processPurchaseResult(res);
            },
          ),
        ],
      ),
    );
  }

  /// [buildSubscriptionButtons] Строит кнопки выбора подписки (Monthly/Annually)
  Widget _buildSubscriptionButtons(
    BuildContext context,
    AdaptyPaywallProduct monthlyProduct,
    AdaptyPaywallProduct annualProduct,
  ) {
    final isAnnualSelected =
        selectedProduct?.vendorProductId == annualProduct.vendorProductId;
    final monthlyPrice = monthlyProduct.price.localizedString ?? r'$9.99';
    final annualPrice = annualProduct.price.localizedString ?? r'$96';
    final annualPricePerMonth = annualProduct.price.amount / 12;
    final annualPricePerMonthString =
        '\$${annualPricePerMonth.toStringAsFixed(2)}';

    return Row(
      children: [
        // [Monthly Button]
        GestureDetector(
          onTap: () {
            setState(() {
              selectedProduct = monthlyProduct;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 27.h, horizontal: 12.w),
            decoration: BoxDecoration(
              border: Border.all(
                color: !isAnnualSelected
                    ? RishColors.primary
                    : RishColors.textSecondary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Monthly',
                  style: context.styles.boldMedium,
                ),
                // SizedBox(height: 4.h),
                Text(
                  '$monthlyPrice/month',
                  style: context.styles.regularMedium,
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12.w),
        // [Annually Button]
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedProduct = annualProduct;
                  });
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isAnnualSelected
                          ? RishColors.primary
                          : RishColors.textSecondary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Annually',
                        style: context.styles.boldMedium,
                      ),
                      // SizedBox(height: 4.h),
                      Text(
                        '$annualPricePerMonthString/month',
                        style: context.styles.regularMedium,
                      ),
                      // SizedBox(height: 4.h),
                      Text(
                        '$annualPrice/year',
                        style: context.styles.regularSmall.copyWith(
                          color: RishColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // [Badge] "20% off" badge
              Positioned(
                top: -8.h,
                right: 8.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: RishColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '20% off',
                    style: context.styles.boldSmall.copyWith(
                      color: RishColors.formBackgroun,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> restore() async {
    setState(() {
      processing = true;
    });
    final res = await adapty.restorePurchases();
    switch (res) {
      case 'ACTIVE':
        appNavigationService.go(path: AppRoutes.homeScreen.path);
      case 'NO_ACTIVE':
        RishSnackbar().showSnackBar('No purchases were found');
      case 'ERROR':
        RishSnackbar().showSnackBar('Some error occured. Please, try again.');
      default:
    }
    setState(() {
      processing = false;
    });
  }

  /// [freeFeaturesIncluded] Список функций, включенных в бесплатную версию
  final List<PaywallFeature> _freeFeaturesIncluded = const [
    PaywallFeature(
      title: 'Wearable Integration (Whoop)',
    ),
    PaywallFeature(
      title: 'Health Metrics',
      subtitle: '(Daily calorie and macro targets)',
    ),
    PaywallFeature(
      title: 'Food Diary (Log or capture meals)',
    ),
    PaywallFeature(
      title: 'Daily Nutrition Wellness Score',
      subtitle: '(View only)',
    ),
  ];

  /// [freeFeaturesExcluded] Список функций, исключенных из бесплатной версии
  final List<PaywallFeature> _freeFeaturesExcluded = const [
    PaywallFeature(
      title: 'Generate Daily Meal Plans',
    ),
    PaywallFeature(
      title: '5-Day Meal Prep',
    ),
    PaywallFeature(
      title: 'AI Nutrition Coach',
    ),
  ];

  /// [premiumFeatures] Список всех премиум функций (все включены)
  final List<PaywallFeature> _premiumFeatures = const [
    PaywallFeature(
      title: 'Wearable Integration (Whoop)',
    ),
    PaywallFeature(
      title: 'Health Metrics',
      subtitle: '(Daily calorie and macro targets)',
    ),
    PaywallFeature(
      title: 'Food Diary (Log or capture meals)',
    ),
    PaywallFeature(
      title: 'Daily Nutrition Wellness Score',
      subtitle: '(Advanced insights)',
    ),
    PaywallFeature(
      title: 'Generate Daily Meal Plans',
    ),
    PaywallFeature(
      title: '5-Day Meal Prep',
    ),
    PaywallFeature(
      title: 'AI Nutrition Coach',
      subtitle: '(Recommendations, chat)',
    ),
  ];

  void processPurchaseResult(String res) {
    if (res == 'SUCCESS') {
      appNavigationService.go(path: AppRoutes.homeScreen.path);
    } else if (res == 'CANCEL') {
      RishSnackbar().showSnackBar('Purchase was cancelled.');
    } else if (res == 'ALREADY_EXISTS') {
      // [FIX] Автоматически пытаемся восстановить покупки при ошибке ALREADY_EXISTS
      _handleAlreadyExistsError();
    } else if (res.contains('Error')) {
      RishSnackbar().showSnackBar(res);
    }
    setState(() {
      processing = false;
    });
  }

  Future<void> _handleAlreadyExistsError() async {
    log(
      'Обнаружена ошибка ALREADY_EXISTS, пытаемся восстановить покупки',
      name: 'Paywall',
    );

    try {
      setState(() {
        processing = true;
      });

      final restoreResult = await adapty.restorePurchases();

      if (restoreResult == 'ACTIVE') {
        log(
          'Подписка успешно восстановлена после ALREADY_EXISTS',
          name: 'Paywall',
        );
        appNavigationService.go(path: AppRoutes.homeScreen.path);
        return;
      }

      // Если restore не помог, показываем пользователю опцию восстановления вручную
      RishSnackbar().showSnackBar(
        'Subscription detected. Try restoring purchases manually.',
      );
    } catch (e) {
      log('Ошибка при автоматическом восстановлении: $e', name: 'Paywall');
      RishSnackbar().showSnackBar(
        'Subscription is already linked to another account. Try restoring purchases.',
      );
    } finally {
      setState(() {
        processing = false;
      });
    }
  }
}

class _SubButtons extends StatefulWidget {
  const _SubButtons({
    required this.callback,
  });
  final Function(AdaptyPaywallProduct) callback;

  @override
  State<_SubButtons> createState() => __SubButtonsState();
}

class __SubButtonsState extends State<_SubButtons> {
  int indexSelected = 0;

  @override
  Widget build(BuildContext context) {
    // [DEBUG MODE] Если нет продуктов (режим симулятора), не показываем кнопки
    if (adapty.products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (int i = 0; i < adapty.products.length; i++)
          Padding(
            padding: EdgeInsets.zero,
            child: GestureDetector(
              onTap: () => _select(i),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 106.h,
                    width: 152.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        width: 2,
                        color: i == indexSelected
                            ? RishColors.primary
                            : RishColors.textSecondary,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            Platform.isIOS
                                ? _getTitleIOs(
                                    adapty.products[i].vendorProductId,
                                  )
                                : '1 ${adapty.products[i].subscription!.period.unit.name}',
                            style:
                                context.styles.boldMedium.copyWith(height: 0),
                          ),
                          FittedBox(
                            child: _getPrice(i, context, i == indexSelected),
                          ),
                          if (i == 1)
                            FittedBox(
                              child: Text(
                                '${adapty.products[i].price.currencySymbol}${(adapty.products[i].price.amount / 12).toStringAsFixed(2)} per month.\nSave 20%',
                                textAlign: TextAlign.center,
                                style: context.styles.regularSmall.copyWith(
                                  color: RishColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (i == 1)
                    Positioned(
                      top: -15.h,
                      left: 26.w,
                      right: 26.w,
                      child: Container(
                        width: 100.w,
                        height: 25.h,
                        decoration: BoxDecoration(
                          color: indexSelected == 1
                              ? RishColors.primary
                              : RishColors.textSecondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          Platform.isAndroid ? 'Best offer' : 'Save 20%',
                          style: context.styles.boldSmall.copyWith(
                            color: RishColors.formBackgroun,
                            // height: 1.5.h,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _getPrice(int i, BuildContext context, bool isSelected) {
    if (i == 0) {
      return Text(
        adapty.products[i].price.localizedString!,
        // "${adapty.products[i].price.currencySymbol}${adapty.products[i].price.amount.toStringAsFixed(2)}",
        style: context.styles.h3.copyWith(
          color: isSelected ? null : RishColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
          height: 1.5,
        ),
      );
    } else {
      return RichText(
        maxLines: 2,
        textAlign: TextAlign.center,
        text: TextSpan(
          text: adapty.products[i].price.localizedString,
          // '${adapty.products[i].price.currencySymbol}${adapty.products[i].price.amount.toStringAsFixed(2)}',
          style: context.styles.h3.copyWith(
            decoration: TextDecoration.none,
            color: isSelected ? null : RishColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
            height: 1.5,
          ),
        ),
        // TextSpan(
        //     text:
        //         '${adapty.products[i].price.currencySymbol}${(adapty.products[0].price.amount * 12).toStringAsFixed(2)}',
        //     style: context.styles.boldLarge.copyWith(
        //       decoration: TextDecoration.lineThrough,
        //       color: RishColors.textSecondary,
        //       height: 1.5,
        //     ),
        //     children: [
        //       TextSpan(
        //         text:
        //             '\n${adapty.products[i].price.currencySymbol}${adapty.products[i].price.amount.toStringAsFixed(2)}',
        //         style: context.styles.h3.copyWith(
        //             decoration: TextDecoration.none,
        //             color: isSelected ? null : RishColors.textSecondary,
        //             fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
        //             height: 1.5),
        //       ),
        //     ]),
      );
    }
  }

  void _select(int i) {
    setState(() {
      indexSelected = i;
    });
    widget.callback(
      adapty.products[i],
    );
  }

  String _getTitleIOs(String vendorId) {
    // print(vendorId);
    switch (vendorId) {
      case 'pivot_sub':
        return '1 month';
      case 'pivot_annual':
        return '1 year';

      default:
        return 'Some error?';
    }
  }
}
