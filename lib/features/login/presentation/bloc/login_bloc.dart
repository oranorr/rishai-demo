import 'dart:async';
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'dart:math' as math;
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/core/services/notifications/notifications_service_impl.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/core/widgets/snackbar.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:rishai/features/login/domain/entities/login_info_entity.dart';
import 'package:rishai/features/login/domain/usecases/create_new_user_usecase.dart';
import 'package:rishai/features/login/domain/usecases/login_via_apple_usecase.dart';
import 'package:rishai/features/login/domain/usecases/login_via_email_usecase.dart';
import 'package:rishai/features/login/domain/usecases/login_via_google_usecase.dart';
import 'package:rishai/features/login/presentation/bloc/login_state.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

part 'login_event.dart';

final loginBloc = getIt.get<LoginBloc>();

@injectable
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginViaGoogleUsecase loginViaGoogleUsecase;
  final CreateNewUserUsecase createNewUserUsecase;
  final LoginViaEmailUsecase loginViaEmailUseCase;
  final LoginViaAppleUsecase loginViaAppleUsecase;
  LoginBloc(
    this.loginViaGoogleUsecase,
    this.createNewUserUsecase,
    this.loginViaEmailUseCase,
    this.loginViaAppleUsecase,
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
    on<LogoutEvent>(_logout);
    on<LoginViaApple>(_loginViaApple);
  }

  FutureOr<void> _createAccount(
      CreateAccountEvent event, Emitter<LoginState> emit) async {
    /// тут по крайней мере проще, просто создается аккаунт, прокидываем на онборд
    emit(state.copyWith(status: Status.loading));
    final String otp = generateVerificationCode();
    final res = await createNewUserUsecase.call(CreateNewUserParams(
      code: otp,
      name: event.name,
      email: event.email,
    ));
    emit(state.copyWith(
        otp: otp,
        loginEntity: LoginInfoEntity(
          email: event.email,
          name: event.name,
          verificationCode: otp,
        )));
    res.fold((fail) {
      emit(state.copyWith(status: Status.error));
      RishSnackbar().showSnackBar(fail.message);
    }, (user) {
      userBloc.add(CreateUserOnLogin(user: user));
      appNavigationService.push(path: AppRoutes.enterOtp.path);
      emit(state.copyWith(status: Status.success));
    });
  }

  FutureOr<void> _loginViaGoogle(
      LoginViaGoogle event, Emitter<LoginState> emit) async {
    emit(state.copyWith(status: Status.loading));
    final res = await loginViaGoogleUsecase.call(const NoParams());
    res.fold((f) {
      RishSnackbar().showSnackBar(f.message);
      emit(state.copyWith(status: Status.error));
    }, (user) {
      userBloc.add(CreateUserOnLogin(user: user));
      add(const LoginOtpCorrect());
      emit(state.copyWith(status: Status.success));
    });
  }

  FutureOr<void> _loginViaEmail(
      LoginViaEmail event, Emitter<LoginState> emit) async {
    emit(state.copyWith(status: Status.loading));
    final String otp = generateVerificationCode();
    final LoginInfoEntity loginInfoEntity =
        LoginInfoEntity(email: event.email, name: '', verificationCode: otp);
    final res = await loginViaEmailUseCase
        .call(LoginViaEmailParams(loginInfoEntity: loginInfoEntity));
    emit(state.copyWith(loginEntity: loginInfoEntity, otp: otp));
    res.fold((fail) {
      emit(state.copyWith(status: Status.error));
      RishSnackbar().showSnackBar(fail.message);
    }, (user) {
      userBloc.add(CreateUserOnLogin(user: user));
      appNavigationService.push(path: AppRoutes.enterOtp.path);
      emit(state.copyWith(status: Status.success));
    });
  }

  FutureOr<void> _cancelOtpEnter(
      LoginCancelOtpEnter event, Emitter<LoginState> emit) {
    emit(state.copyWith(otp: null, loginEntity: null, status: Status.initial));
    userBloc.add(CreateUserOnLogin(user: UserEntity.unauthorized()));
  }

  FutureOr<void> _correctOtp(
      LoginOtpCorrect event, Emitter<LoginState> emit) async {
    UserEntity curUser = userBloc.state.user;
    await prefsRepo.setLogin(true);
    userBloc.add(UpdateUserEvent(user: curUser));
    whoopBloc.add(InitWhoopOnLogin());
    chatBloc.add(InitChatBloc());
  }

  FutureOr<void> _logout(LogoutEvent event, Emitter<LoginState> emit) async {
    await hive.clear();
    await prefsRepo.flush();
    await notes.cancelNotifications();
    chatBloc.add(const ChatOnLogout(needsCounterClear: true));
    userBloc.add(CreateUserOnLogin(user: UserEntity.unauthorized()));
    appNavigationService.go(path: AppRoutes.login.path);
  }

  FutureOr<void> _loginViaApple(
      LoginViaApple event, Emitter<LoginState> emit) async {
    emit(state.copyWith(status: Status.loading));
    final res = await loginViaAppleUsecase.call(const NoParams());
    res.fold((f) {
      RishSnackbar().showSnackBar(f.message);
      emit(state.copyWith(status: Status.error));
    }, (user) {
      userBloc.add(CreateUserOnLogin(user: user));
      add(const LoginOtpCorrect());
      emit(state.copyWith(status: Status.success));
    });
  }
}

String generateVerificationCode() {
  final random = math.Random();
  String verificationCode = '';

  for (int i = 0; i < 4; i++) {
    int randomNumber = random.nextInt(10);
    verificationCode += randomNumber.toString();
  }

  log('OTP CODE: $verificationCode');
  return verificationCode;
}



///У нас три варианта логина, после которых мы получаем пользователя  
///У него может быть, а может и не быть данных.
///Если данных нет —– ведем его на коннект, а после опросник
///если есть –– смотрим 