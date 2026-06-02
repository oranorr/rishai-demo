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

    // [ViewState] По умолчанию показываем премиум версию (платный тариф)
    // Пользователь может переключиться на бесплатный тариф через сегментированный контрол
    _currentViewState = PaywallViewState.premium;
  }

  /// [formatPrice] Форматирует цену в едином формате: "Валюта, сумма, пробел, /, пробел, период"
  ///
  /// [amount] - сумма цены
  /// [currencySymbol] - символ валюты (может быть null, тогда используется "$")
  /// [period] - период (например, "month", "year", "forever")
  String _formatPrice(double amount, String? currencySymbol, String period) {
    // Используем символ валюты или значение по умолчанию
    final symbol = currencySymbol ?? '\$';
    
    // Форматируем сумму с двумя знаками после запятой
    final formattedAmount = amount.toStringAsFixed(2);
    // Разделяем на целую и дробную части
    final parts = formattedAmount.split('.');
    final integerPart = int.parse(parts[0]);
    final decimalPart = parts[1];
    
    // Форматируем целую часть с разделителями тысяч
    final formattedInteger = integerPart.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
    
    // Если дробная часть не равна "00", добавляем её
    final cleanDecimal = decimalPart == '00' ? '' : '.$decimalPart';
    final cleanAmount = '$formattedInteger$cleanDecimal';
    
    // Возвращаем в формате: "Валюта, сумма, пробел, /, пробел, период"
    return '$symbol $cleanAmount / $period';
  }

  /// [buildPremiumOnlyView] Строит экран только с премиум карточкой
  ///
  /// Показывается когда пользователь уже видел бесплатную версию
  /// Включает кнопку назад для закрытия экрана
  Widget _buildPremiumOnlyView(BuildContext context) {
    return RishScaffold(
      needsAppBar: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 20.h),
          // [Back Button] Кнопка назад для закрытия экрана
          Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  // [PostQuestionaryBack] Home + InitWhoop при флаге (плашка sync вместо /redirect).
                  onTap: navigateHomeAndInitWhoopIfNeeded,
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
          SizedBox(height: 16.h),
          // [Premium Card] Только премиум карточка с возможностью скролла внутри
          Expanded(
            child: _buildPremiumCard(context, needsTag: true),
          ),
        ],
      ),
    );
  }

  /// [buildUnifiedView] Строит единый экран с сегментированным контролом
  ///
  /// Позволяет переключаться между Free и Premium планами
  Widget _buildUnifiedView(BuildContext context) {
    return RishScaffold(
      needsAppBar: false,
      child: Column(
        children: [
          SizedBox(height: 20.h),
          // [Title] Заголовок "Choose a plan"
          AutoSizeText(
            'Choose a plan',
            style: context.styles.h1,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          // [Segmented Control] Переключатель между Free и Premium
          _buildSegmentedControl(context),
          SizedBox(height: 16.h),
          // [Plan Card] Карточка с выбранным планом с возможностью скролла внутри
          Expanded(
            child: _buildPlanCard(context),
          ),
        ],
      ),
    );
  }

  /// [buildSegmentedControl] Строит сегментированный контрол для переключения планов
  Widget _buildSegmentedControl(BuildContext context) {
    return Container(
      width: 220.w,
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
                padding: EdgeInsets.symmetric(vertical: 10.h),
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
      return _buildPremiumCard(context, needsTag: false);
    }
  }

  /// [buildFreeCard] Строит карточку для Free плана
  Widget _buildFreeCard(BuildContext context) {
    // [Currency Symbol] Получаем символ валюты пользователя из доступных продуктов
    // Используем валюту из selectedProduct, если доступен, иначе из первого продукта
    final currencySymbol = selectedProduct?.price.currencySymbol ??
        (adapty.products.isNotEmpty
            ? adapty.products.first.price.currencySymbol
            : '\$');

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: RishColors.textPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // [Title] Заголовок карточки
          Text(
            'Enjoy core features for free',
            style: context.styles.h2.copyWith(
              color: RishColors.formBackgroun,
            ),
          ),
          SizedBox(height: 12.h),
          // [Price] Цена в формате "Валюта, сумма, пробел, /, пробел, период"
          // Используем валюту пользователя вместо жестко закодированного доллара
          Text(
            _formatPrice(0, currencySymbol, 'forever'),
            style: context.styles.h1.copyWith(
              fontWeight: FontWeight.w900,
              color: RishColors.formBackgroun,
            ),
          ),
          SizedBox(height: 6.h),
          // [Subtitle] Подзаголовок
          Text(
            'Start free. Upgrade anytime.',
            style: context.styles.regularMedium.copyWith(
              color: RishColors.formBackgroun,
            ),
          ),
          SizedBox(height: 4.h),
          // [Divider] Разделитель
          Divider(
            color: RishColors.formBackgroun.withOpacity(0.3),
            thickness: 1,
          ),
          SizedBox(height: 4.h),
          // [Free Features] Список функций для бесплатных пользователей
          // Скроллируемый список функций
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Включенные функции (с галочкой)
                  ..._freeFeaturesIncluded.map(
                    (feature) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
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
                      padding: EdgeInsets.only(bottom: 12.h),
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
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
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
              // [SyncBanner] Home + InitWhoop при флаге после опросника.
              navigateHomeAndInitWhoopIfNeeded();
            },
          ),
        ],
      ),
    );
  }

  /// [buildPremiumCard] Строит карточку для Premium плана
  Widget _buildPremiumCard(BuildContext context, {required bool needsTag}) {
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
    
    // [Formatted Prices] Форматируем цены в едином формате
    final annualPricePerMonth = annualProduct.price.amount / 12;
    final displayPrice = isAnnualSelected
        ? _formatPrice(
            annualPricePerMonth,
            annualProduct.price.currencySymbol,
            'month',
          )
        : _formatPrice(
            monthlyProduct.price.amount,
            monthlyProduct.price.currencySymbol,
            'month',
          );
    
    // [Billing Text] Форматируем текст о биллинге
    final monthlyPriceFormatted = _formatPrice(
      monthlyProduct.price.amount,
      monthlyProduct.price.currencySymbol,
      'month',
    );
    final billingText = isAnnualSelected
        ? 'Billed yearly or $monthlyPriceFormatted billed monthly.'
        : 'Billed monthly.';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: RishColors.formBackgroun,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // [Title] Заголовок карточки
          SizedBox(height: needsTag ? 16.h : 0),
          if (needsTag)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: RishColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'PREMIUM',
                style: context.styles.h3.copyWith(
                  color: RishColors.formBackgroun,
                ),
              ),
            ),
          SizedBox(height: needsTag ? 16.h : 0),
          AutoSizeText(
            'Unlock advanced features',
            style: context.styles.h2,
          ),
          SizedBox(height: 12.h),
          // [Price] Цена с подзаголовком (зависит от выбранного плана)
          AutoSizeText(
            displayPrice,
            style: context.styles.h1.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6.h),
          AutoSizeText(
            billingText,
            style: context.styles.regularSmall.copyWith(
              color: RishColors.textSecondary,
            ),
          ),
          SizedBox(height: 4.h),

          // [Divider] Разделитель
          Divider(
            color: RishColors.textSecondary.withOpacity(0.3),
            thickness: 1,
          ),
          SizedBox(height: 4.h),
          // [Premium Features] Список всех премиум функций (все включены)
          // Скроллируемый список функций
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._premiumFeatures.map(
                    (feature) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
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
                ],
              ),
            ),
          ),

          SizedBox(height: 16.h),
          // [Subscription Buttons] Кнопки выбора подписки
          _buildSubscriptionButtons(context, monthlyProduct, annualProduct),
          SizedBox(height: 16.h),
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
  ///
  /// Кнопки адаптируются под размер экрана, используя MediaQuery
  /// для определения размера экрана и адаптивные отступы/шрифты
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

    // [Formatted Prices] Форматируем цены в едином формате для кнопок
    final annualPricePerMonth = annualProduct.price.amount / 12;
    final monthlyPriceFormatted = _formatPrice(
      monthlyProduct.price.amount,
      monthlyProduct.price.currencySymbol,
      'month',
    );
    final annualPricePerMonthFormatted = _formatPrice(
      annualPricePerMonth,
      annualProduct.price.currencySymbol,
      'month',
    );
    final annualPriceFormatted = _formatPrice(
      annualProduct.price.amount,
      annualProduct.price.currencySymbol,
      'year',
    );

    // [Adaptive Sizing] Определяем размер экрана для адаптации
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // [Screen Size Categories] Категории размеров экрана
    // Маленький экран: высота < 700 или ширина < 350
    final isSmallScreen = screenHeight < 700 || screenWidth < 350;
    // Средний экран: высота между 700 и 850
    final isMediumScreen = screenHeight >= 700 && screenHeight < 850;

    // [Adaptive Padding] Адаптивные отступы в зависимости от размера экрана
    final verticalPadding =
        isSmallScreen ? 12.h : (isMediumScreen ? 16.h : 20.h);
    final horizontalPadding = isSmallScreen ? 8.w : 12.w;

    // [Adaptive Font Sizes] Адаптивные размеры шрифтов
    final titleFontSize = isSmallScreen ? 14.0 : 16.0;
    final priceFontSize = isSmallScreen ? 12.0 : 14.0;
    final yearPriceFontSize = isSmallScreen ? 10.0 : 12.0;
    final badgeFontSize = isSmallScreen ? 8.0 : 10.0;

    // [Adaptive Spacing] Адаптивные отступы между элементами
    final spacingBetweenButtons = isSmallScreen ? 8.w : 12.w;
    final spacingBetweenTexts = isSmallScreen ? 2.h : 4.h;

    // [Equal Height Buttons] Используем IntrinsicHeight для выравнивания кнопок по высоте
    return IntrinsicHeight(
      child: Row(
        children: [
          // [Monthly Button] Кнопка месячной подписки
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
                padding: EdgeInsets.symmetric(
                  vertical: verticalPadding,
                  horizontal: horizontalPadding,
                ),
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
                    // [Monthly Label] Адаптивный текст "Monthly"
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Monthly',
                        style: context.styles.boldMedium.copyWith(
                          fontSize: titleFontSize,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(height: spacingBetweenTexts),
                    // [Monthly Price] Адаптивный текст с ценой в формате "Валюта, сумма, пробел, /, пробел, период"
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        monthlyPriceFormatted,
                        style: context.styles.regularMedium.copyWith(
                          fontSize: priceFontSize,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                    // [Spacer] Добавляем невидимый элемент для выравнивания высоты
                    // Это компенсирует третью строку в кнопке Annually
                    SizedBox(height: spacingBetweenTexts),
                    Opacity(
                      opacity: 0,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          annualPriceFormatted,
                          style: context.styles.regularSmall.copyWith(
                            color: RishColors.textSecondary,
                            fontSize: yearPriceFontSize,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: spacingBetweenButtons),
          // [Annually Button] Кнопка годовой подписки
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
                    padding: EdgeInsets.symmetric(
                      vertical: verticalPadding,
                      horizontal: horizontalPadding,
                    ),
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
                        // [Annually Label] Адаптивный текст "Annually"
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Annually',
                            style: context.styles.boldMedium.copyWith(
                              fontSize: titleFontSize,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(height: spacingBetweenTexts),
                        // [Annual Price Per Month] Адаптивный текст с месячной ценой в формате "Валюта, сумма, пробел, /, пробел, период"
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            annualPricePerMonthFormatted,
                            style: context.styles.regularMedium.copyWith(
                              fontSize: priceFontSize,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(height: spacingBetweenTexts),
                        // [Annual Price] Адаптивный текст с годовой ценой в формате "Валюта, сумма, пробел, /, пробел, период"
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            annualPriceFormatted,
                            style: context.styles.regularSmall.copyWith(
                              color: RishColors.textSecondary,
                              fontSize: yearPriceFontSize,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // [Badge] "20% off" badge - адаптивный размер
                Positioned(
                  top: isSmallScreen ? -6.h : -8.h,
                  right: isSmallScreen ? 6.w : 8.w,
                  child: IgnorePointer(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 6.w : 8.w,
                        vertical: isSmallScreen ? 2.h : 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: RishColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '20% off',
                        style: context.styles.boldSmall.copyWith(
                          color: RishColors.formBackgroun,
                          fontSize: badgeFontSize,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> restore() async {
    setState(() {
      processing = true;
    });
    final res = await adapty.restorePurchases();
    switch (res) {
      case 'ACTIVE':
        navigateHomeAndInitWhoopIfNeeded();
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

  Future<void> processPurchaseResult(String res) async {
    if (res == 'SUCCESS') {
      navigateHomeAndInitWhoopIfNeeded();
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
        navigateHomeAndInitWhoopIfNeeded();
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
