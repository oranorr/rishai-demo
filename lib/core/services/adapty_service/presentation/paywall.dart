import 'dart:developer';

import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository_impl.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/core/widgets/snackbar.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

part 'paywall_mixin.dart';

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

class _PaywallState extends State<Paywall> with PaywallMixin {
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
}
