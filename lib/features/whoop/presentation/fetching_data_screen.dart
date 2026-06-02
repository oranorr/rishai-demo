import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

/// [Redirect] Shim для deep link /redirect: сразу на home + InitWhoop при необходимости.
class Redirect extends StatefulWidget {
  const Redirect({super.key});

  @override
  State<Redirect> createState() => _RedirectState();
}

class _RedirectState extends State<Redirect> {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirectToHome());
  }

  Future<void> _redirectToHome() async {
    if (_hasInitialized) {
      log('[Redirect] Уже инициализировано, пропускаем', name: 'Redirect');
      return;
    }
    _hasInitialized = true;

    final shouldInit = prefsRepo.getShouldRedirectAfterPaywall();
    log(
      '[Redirect] shouldRedirectAfterPaywall=$shouldInit — переход на home',
      name: 'Redirect',
    );

    if (shouldInit) {
      await prefsRepo.setShouldRedirectAfterPaywall(false);
    }

    if (!mounted) return;

    appNavigationService.go(path: AppRoutes.homeScreen.path);

    if (shouldInit) {
      whoopBloc.add(const InitWhoopOnLogin());
      log('[Redirect] InitWhoopOnLogin вызван', name: 'Redirect');
    }
  }

  @override
  Widget build(BuildContext context) {
    // [build] Пустой scaffold — мгновенный переход на home, без standby UI.
    return const RishScaffold(
      implyLeading: false,
      needsAppBar: false,
      needsBottomPadding: false,
      child: SizedBox.shrink(),
    );
  }
}
