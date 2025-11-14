import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

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
    // [InitWhoopAfterPaywall] Проверяем, пришли ли мы после paywall
    // Если да, инициализируем WHOOP данные
    _initializeWhoop();
  }

  Future<void> _initializeWhoop() async {
    if (_hasInitialized) {
      log('[Redirect] Уже инициализировано, пропускаем', name: 'Redirect');
      return;
    }

    _hasInitialized = true;
    final shouldInit = prefsRepo.getShouldRedirectAfterPaywall();
    log(
      '[Redirect] Проверка флага shouldRedirectAfterPaywall: $shouldInit',
      name: 'Redirect',
    );

    if (shouldInit) {
      log(
        '[Redirect] Флаг установлен, начинаем инициализацию WHOOP',
        name: 'Redirect',
      );
      // [ResetFlag] Сбрасываем флаг перед инициализацией
      await prefsRepo.setShouldRedirectAfterPaywall(false);
      log('[Redirect] Флаг сброшен, вызываем InitWhoopOnLogin', name: 'Redirect');
      // [InitWhoop] Инициализируем WHOOP данные
      // К этому моменту мы уже на странице /redirect, поэтому WhoopBloc не будет
      // автоматически переходить на /redirect (логика изменена в whoop_bloc.dart)
      whoopBloc.add(const InitWhoopOnLogin());
      log('[Redirect] InitWhoopOnLogin вызван', name: 'Redirect');
    } else {
      log(
        '[Redirect] Флаг не установлен, инициализация не требуется',
        name: 'Redirect',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RishScaffold(
      implyLeading: false,
      needsAppBar: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 50.h),
            Text(
              "Please stand by...\nFetching WHOOP data\n\nDon't close the app",
              style: context.styles.h2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
