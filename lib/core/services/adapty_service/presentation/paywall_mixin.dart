part of 'paywall.dart';

mixin PaywallMixin on State<Paywall> {
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
      // [initSelectedProduct] Определяем начальный выбранный продукт
      // По умолчанию выбираем годовую подписку (продукт с большей ценой)
      // Используем ту же логику, что и в _buildPremiumCard - различаем по цене
      AdaptyPaywallProduct annualProduct;
      if (adapty.products.length > 1) {
        // Сортируем по цене и берем самый дорогой (годовая подписка)
        final sortedProducts = List<AdaptyPaywallProduct>.from(adapty.products)
          ..sort((a, b) => a.price.amount.compareTo(b.price.amount));
        annualProduct = sortedProducts.last;
      } else {
        annualProduct = adapty.products.first;
      }

      // По умолчанию выбираем годовую подписку
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
              // [CheckRedirectFlag] Проверяем, нужно ли переходить на redirect после paywall
              // (используется после завершения опросника)
              // [NOTE] Флаг НЕ сбрасываем здесь, он будет сброшен в Redirect после инициализации
              final shouldRedirect = prefsRepo.getShouldRedirectAfterPaywall();
              if (shouldRedirect) {
                // [RedirectToInit] Переходим на redirect, где будет вызван InitWhoopOnLogin
                context.go(AppRoutes.redirect.path);
              } else {
                // [NormalFlow] Обычный поток - переходим на главный экран
                context.go(AppRoutes.homeScreen.path);
              }
            },
          ),
        ],
      ),
    );
  }

  /// [buildPremiumCard] Строит карточку для Premium плана
  Widget _buildPremiumCard(BuildContext context) {
    // [debugProducts] Выводим все продукты для отладки
    print(
      '[Paywall._buildPremiumCard] Все продукты в adapty.products:',
    );
    for (int i = 0; i < adapty.products.length; i++) {
      final product = adapty.products[i];
      print(
        '  [$i] vendorProductId: ${product.vendorProductId}, price: ${product.price.amount} ${product.price.currencyCode}',
      );
    }

    // [getProducts] Получаем цены для месячной и годовой подписки
    // Используем универсальную логику: различаем продукты по цене
    // Годовая подписка всегда дороже месячной (общая цена, не в пересчете на месяц)
    // Это работает для всех платформ (iOS: pivot_sub/pivot_annual, Android: оба pivot_monthly)
    AdaptyPaywallProduct monthlyProduct;
    AdaptyPaywallProduct annualProduct;

    if (adapty.products.length < 2) {
      // Если только один продукт, используем его для обоих
      monthlyProduct = adapty.products.first;
      annualProduct = adapty.products.first;
      print(
        '[Paywall._buildPremiumCard] Только один продукт, используем его для обоих',
      );
    } else {
      // [sortByPrice] Сортируем продукты по цене: меньшая цена = monthly, большая = annual
      // Это работает для всех платформ, так как годовая подписка всегда дороже месячной
      final sortedProducts = List<AdaptyPaywallProduct>.from(adapty.products)
        ..sort((a, b) => a.price.amount.compareTo(b.price.amount));

      monthlyProduct = sortedProducts[0];
      annualProduct = sortedProducts[sortedProducts.length - 1];

      print(
        '[Paywall._buildPremiumCard] Определено по цене: monthlyProduct (${monthlyProduct.vendorProductId}, ${monthlyProduct.price.amount} ${monthlyProduct.price.currencyCode}), annualProduct (${annualProduct.vendorProductId}, ${annualProduct.price.amount} ${annualProduct.price.currencyCode})',
      );
    }

    print(
      '[Paywall._buildPremiumCard] ✅ Финальные продукты: monthlyProduct: ${monthlyProduct.vendorProductId} (${monthlyProduct.price.amount}), annualProduct: ${annualProduct.vendorProductId} (${annualProduct.price.amount})',
    );

    final monthlyPrice = monthlyProduct.price.localizedString ?? r'$9.99';
    final annualPricePerMonth = annualProduct.price.amount / 12;
    final annualPricePerMonthString =
        '${annualProduct.price.currencySymbol}${annualPricePerMonth.toStringAsFixed(2)}';

    // [Price Display] Определяем, какой план выбран и показываем соответствующую цену
    // Сравниваем по vendorProductId, а если они одинаковые - по цене
    bool isAnnualSelected;
    if (monthlyProduct.vendorProductId == annualProduct.vendorProductId) {
      // Если vendorProductId одинаковые (Android), сравниваем по цене
      isAnnualSelected =
          selectedProduct?.price.amount == annualProduct.price.amount;
    } else {
      // Если vendorProductId разные (iOS), сравниваем по vendorProductId
      isAnnualSelected =
          selectedProduct?.vendorProductId == annualProduct.vendorProductId;
    }
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
    // [isAnnualSelected] Вычисляем на основе текущего selectedProduct
    // Сравниваем по vendorProductId, а если они одинаковые - по цене
    // Пересчитывается автоматически при каждом build после setState
    bool isAnnualSelected;
    if (monthlyProduct.vendorProductId == annualProduct.vendorProductId) {
      // Если vendorProductId одинаковые (Android), сравниваем по цене
      isAnnualSelected =
          selectedProduct?.price.amount == annualProduct.price.amount;
    } else {
      // Если vendorProductId разные (iOS), сравниваем по vendorProductId
      isAnnualSelected =
          selectedProduct?.vendorProductId == annualProduct.vendorProductId;
    }

    final monthlyPrice = monthlyProduct.price.localizedString ?? r'$9.99';
    final annualPrice = annualProduct.price.localizedString ?? r'$96';
    final annualPricePerMonth = annualProduct.price.amount / 12;
    final annualPricePerMonthString =
        '\$${annualPricePerMonth.toStringAsFixed(2)}';

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                selectedProduct = monthlyProduct;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: double.infinity,
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
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
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
        ),
        SizedBox(width: 12.w),
        // [Annually Button]
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                key: ValueKey('annually_${selectedProduct?.vendorProductId}'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    selectedProduct = annualProduct;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: double.infinity,
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
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                child: IgnorePointer(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
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
        // [CheckRedirectFlag] Проверяем, нужно ли переходить на redirect после paywall
        // (используется после завершения опросника)
        // [NOTE] Флаг НЕ сбрасываем здесь, он будет сброшен в Redirect после инициализации
        final shouldRedirect = prefsRepo.getShouldRedirectAfterPaywall();
        if (shouldRedirect) {
          // [RedirectToInit] Переходим на redirect, где будет вызван InitWhoopOnLogin
          appNavigationService.go(path: AppRoutes.redirect.path);
        } else {
          // [NormalFlow] Обычный поток - переходим на главный экран
          appNavigationService.go(path: AppRoutes.homeScreen.path);
        }
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

  void processPurchaseResult(String res) async {
    if (res == 'SUCCESS') {
      // [CheckRedirectFlag] Проверяем, нужно ли переходить на redirect после paywall
      // (используется после завершения опросника)
      // [NOTE] Флаг НЕ сбрасываем здесь, он будет сброшен в Redirect после инициализации
      final shouldRedirect = prefsRepo.getShouldRedirectAfterPaywall();
      if (shouldRedirect) {
        // [RedirectToInit] Переходим на redirect, где будет вызван InitWhoopOnLogin
        appNavigationService.go(path: AppRoutes.redirect.path);
      } else {
        // [NormalFlow] Обычный поток - переходим на главный экран
        appNavigationService.go(path: AppRoutes.homeScreen.path);
      }
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
        // [CheckRedirectFlag] Проверяем, нужно ли переходить на redirect после paywall
        // (используется после завершения опросника)
        // [NOTE] Флаг НЕ сбрасываем здесь, он будет сброшен в Redirect после инициализации
        final shouldRedirect = prefsRepo.getShouldRedirectAfterPaywall();
        if (shouldRedirect) {
          // [RedirectToInit] Переходим на redirect, где будет вызван InitWhoopOnLogin
          appNavigationService.go(path: AppRoutes.redirect.path);
        } else {
          // [NormalFlow] Обычный поток - переходим на главный экран
          appNavigationService.go(path: AppRoutes.homeScreen.path);
        }
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
