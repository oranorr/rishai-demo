import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/services/accounts_whitelist/accounts_whitelist_service.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository_impl.dart';
import 'package:rishai/core/services/day_manager/day_manager_impl.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/core/services/notifications/notifications_service_impl.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/core/widgets/snackbar.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:rishai/features/login/domain/entities/login_info_entity.dart';
import 'package:rishai/features/login/domain/params/email_otp_params.dart';
import 'package:rishai/features/login/domain/usecases/create_new_user_usecase.dart';
import 'package:rishai/features/login/domain/usecases/login_via_apple_usecase.dart';
import 'package:rishai/features/login/domain/usecases/login_via_google_usecase.dart';
import 'package:rishai/features/login/domain/usecases/request_email_otp_usecase.dart';
import 'package:rishai/features/login/domain/usecases/verify_email_otp_usecase.dart';
import 'package:rishai/features/login/presentation/bloc/login_state.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/week_plan/presentation/bloc/week_plan_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

part 'login_event.dart';

final loginBloc = getIt.get<LoginBloc>();

@injectable
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc(
    this.loginViaGoogleUsecase,
    this.createNewUserUsecase,
    this.requestEmailOtpUsecase,
    this.verifyEmailOtpUsecase,
    this.loginViaAppleUsecase,
    this.accountsWhiteListService,
  ) : super(
          const LoginMainState(
            status: Status.initial,
          ),
        ) {
    on<CreateAccountEvent>(_createAccount);
    on<LoginViaGoogle>(_loginViaGoogle);
    on<LoginViaEmail>(_loginViaEmail);
    on<LoginCancelOtpEnter>(_cancelOtpEnter);
    on<LoginOtpCorrect>(_correctOtp);
    on<LoginSubmitEmailOtp>(_submitEmailOtp);
    on<LogoutEvent>(_logout);
    on<LoginViaApple>(_loginViaApple);
  }
  final LoginViaGoogleUsecase loginViaGoogleUsecase;
  final CreateNewUserUsecase createNewUserUsecase;
  final RequestEmailOtpUsecase requestEmailOtpUsecase;
  final VerifyEmailOtpUsecase verifyEmailOtpUsecase;
  final LoginViaAppleUsecase loginViaAppleUsecase;
  final AccountsWhiteListService accountsWhiteListService;

  /// Регистрация: `POST /users/create` → `POST /auth/request-otp` → экран OTP.
  FutureOr<void> _createAccount(
    CreateAccountEvent event,
    Emitter<LoginState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    final res = await createNewUserUsecase.call(
      CreateNewUserParams(
        name: event.name,
        email: event.email,
      ),
    );
    await res.fold<Future<void>>(
      (fail) async {
        emit(state.copyWith(status: Status.error));
        RishSnackbar().showSnackBar(fail.message);
      },
      (user) async {
        userBloc.add(
          CreateUserOnLogin(
            user: user,
            shouldCreateHistoryDays: event.shouldCreateHistoryDays,
          ),
        );
        final otpReq = await requestEmailOtpUsecase.call(
          RequestEmailOtpParams(email: event.email),
        );
        await otpReq.fold<Future<void>>(
          (fail) async {
            emit(state.copyWith(status: Status.error));
            RishSnackbar().showSnackBar(fail.message);
          },
          (_) async {
            emit(
              state.copyWith(
                status: Status.success,
                loginEntity: LoginInfoEntity(
                  email: event.email,
                  name: event.name,
                  shouldCreateHistoryDays: event.shouldCreateHistoryDays,
                ),
              ),
            );
            await appNavigationService.push(path: AppRoutes.enterOtp.path);
          },
        );
      },
    );
  }

  FutureOr<void> _loginViaGoogle(
    LoginViaGoogle event,
    Emitter<LoginState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    final res = await loginViaGoogleUsecase.call(const NoParams());
    await res.fold<Future<void>>(
      (f) async {
        RishSnackbar().showSnackBar(f.message);
        emit(state.copyWith(status: Status.error));
      },
      (user) async {
        userBloc.add(CreateUserOnLogin(user: user));
        // Даем время на обновление состояния userBloc
        await Future.delayed(const Duration(milliseconds: 100));
        add(const LoginOtpCorrect());
        emit(state.copyWith(status: Status.success));
      },
    );
  }

  /// Логин по email: только `request-otp`, профиль после `verify` на экране OTP.
  FutureOr<void> _loginViaEmail(
    LoginViaEmail event,
    Emitter<LoginState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    final loginInfoEntity = LoginInfoEntity(
      email: event.email,
      name: '',
    );
    final res = await requestEmailOtpUsecase.call(
      RequestEmailOtpParams(email: event.email),
    );
    await res.fold<Future<void>>(
      (fail) async {
        emit(state.copyWith(status: Status.error));
        RishSnackbar().showSnackBar(fail.message);
      },
      (_) async {
        emit(
          state.copyWith(
            loginEntity: loginInfoEntity,
            status: Status.success,
          ),
        );
        await appNavigationService.push(path: AppRoutes.enterOtp.path);
      },
    );
  }

  FutureOr<void> _cancelOtpEnter(
    LoginCancelOtpEnter event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(loginEntity: null, status: Status.initial));
    userBloc.add(CreateUserOnLogin(user: UserEntity.unauthorized()));
  }

  /// Завершение сессии после того, как в [userBloc] уже лежит актуальный [UserEntity].
  Future<void> _finalizeAuthenticatedSession(
    UserEntity curUser,
    Emitter<LoginState> emit,
  ) async {
    UserEntity user = curUser;
    if (user.adaptyId == null) {
      user = user.copyWith(
        adaptyId: adapty.generateAdaptyId(directusId: user.directusId),
      );
    }

    await prefsRepo.setLogin(true);

    // Сначала сохраняем в Hive
    await hive.saveUser(user: user);
    await adapty.initAdapty();

    // [FIX] Дожидаемся завершения identify перед запуском других блоков
    try {
      await adapty.identify(adaptyId: user.adaptyId!);
      log(
        'Adapty identify завершен при логине. Статус подписки: ${adapty.isActive}',
        name: 'LoginBloc',
      );
    } catch (e) {
      log('Ошибка при identify в логине, но продолжаем: $e', name: 'LoginBloc');
      // Даже если identify упал, пытаемся восстановить покупки
      try {
        final restoreResult = await adapty.restorePurchases();
        log(
          'Результат восстановления покупок при логине: $restoreResult',
          name: 'LoginBloc',
        );
      } catch (restoreError) {
        log(
          'Ошибка при восстановлении покупок в логине: $restoreError',
          name: 'LoginBloc',
        );
      }
    }

    // Проверяем белый список аккаунтов для автоматической активации подписки
    await _checkWhiteListAndActivateSubscription(user.email);

    // Затем обновляем в Directus и состоянии (без вызова identify)
    userBloc.add(UpdateUserEvent(user: user));

    // Теперь инициализируем другие блоки, когда статус подписки определен
    whoopBloc.add(const InitWhoopOnLogin());
    chatBloc.add(InitChatBloc(directusId: user.directusId));
    weekPlanBloc.add(const WeekPlanLoad());
    log(
      'Логин завершен. Финальный статус подписки: ${adapty.isActive}',
      name: 'LoginBloc',
    );
    emit(state.copyWith(status: Status.success));
  }

  FutureOr<void> _correctOtp(
    LoginOtpCorrect event,
    Emitter<LoginState> emit,
  ) async {
    await _finalizeAuthenticatedSession(userBloc.state.user, emit);
  }

  /// Проверка OTP на бэкенде и загрузка профиля (`users/me`).
  FutureOr<void> _submitEmailOtp(
    LoginSubmitEmailOtp event,
    Emitter<LoginState> emit,
  ) async {
    final info = state.loginEntity;
    if (info == null) {
      log('[LoginBloc._submitEmailOtp] loginEntity is null', name: 'LoginBloc');
      emit(state.copyWith(status: Status.error));
      return;
    }

    emit(state.copyWith(status: Status.loading));

    final res = await verifyEmailOtpUsecase.call(
      VerifyEmailOtpParams(email: info.email, code: event.code),
    );

    await res.fold<Future<void>>(
      (fail) async {
        emit(state.copyWith(status: Status.error));
        RishSnackbar().showSnackBar(fail.message);
      },
      (user) async {
        userBloc.add(
          CreateUserOnLogin(
            user: user,
            shouldCreateHistoryDays: info.shouldCreateHistoryDays,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 100));
        // Используем [user] из `users/me`, а не повторное чтение bloc (race).
        await _finalizeAuthenticatedSession(user, emit);
      },
    );
  }

  FutureOr<void> _logout(LogoutEvent event, Emitter<LoginState> emit) async {
    await hive.clear();
    await prefsRepo.clearAppJwtSession();
    await prefsRepo.flush();
    await notes.cancelNotifications();
    await adapty.logout();

    // Очищаем хранилище дней через DayManager
    try {
      await dayManager.clearUserDays();
    } catch (e) {
      log('[LoginBloc] Ошибка при очистке дней: $e');
    }

    chatBloc.add(const ChatOnLogout(needsCounterClear: true));
    userBloc.add(CreateUserOnLogin(user: UserEntity.unauthorized()));
    weekPlanBloc.add(const WeekPlanClear());
    whoopBloc.add(WhoopResetState());
    appNavigationService.go(path: AppRoutes.login.path);
  }

  FutureOr<void> _loginViaApple(
    LoginViaApple event,
    Emitter<LoginState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    final res = await loginViaAppleUsecase.call(const NoParams());
    await res.fold<Future<void>>(
      (f) async {
        RishSnackbar().showSnackBar(f.message);
        emit(state.copyWith(status: Status.error));
      },
      (user) async {
        userBloc.add(CreateUserOnLogin(user: user));
        // Даем время на обновление состояния userBloc
        await Future.delayed(const Duration(milliseconds: 100));
        add(const LoginOtpCorrect());
        emit(state.copyWith(status: Status.success));
      },
    );
  }

  /// Проверяет белый список аккаунтов и активирует подписку для пользователей из списка
  /// Это основная фича для автоматической активации подписки
  Future<void> _checkWhiteListAndActivateSubscription(String email) async {
    try {
      log(
        '[LoginBloc] Проверяем email $email в белом списке',
        name: 'LoginBloc',
      );

      final bool isInWhiteList =
          await accountsWhiteListService.isEmailInWhiteList(email);

      if (isInWhiteList) {
        log(
          '[LoginBloc] ✅ Email $email найден в белом списке! Активируем подписку автоматически',
          name: 'LoginBloc',
        );

        // Активируем подписку для пользователя из белого списка
        adapty.activateWhiteListSubscription();

        log(
          '[LoginBloc] ✅ Подписка активирована для пользователя из белого списка. '
          'Статус: isActive=${adapty.isActive}, isTrialActive=${adapty.isTrialActive}',
          name: 'LoginBloc',
        );
      } else {
        log(
          '[LoginBloc] Email $email не найден в белом списке. '
          'Используем стандартную логику подписки',
          name: 'LoginBloc',
        );
      }
    } catch (e, stackTrace) {
      log(
        '[LoginBloc] Ошибка при проверке белого списка: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'LoginBloc',
      );
      // Не прерываем процесс логина при ошибке проверки белого списка
    }
  }
}

///У нас три варианта логина, после которых мы получаем пользователя
///У него может быть, а может и не быть данных.
///Если данных нет —– ведем его на коннект, а после опросник
///если есть –– смотрим
