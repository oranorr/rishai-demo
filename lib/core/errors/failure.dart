import 'package:equatable/equatable.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  // String getMessage();
}

class UnknownFailure extends Failure {
  const UnknownFailure() : super('Unkown error');
  @override
  List<Object?> get props => [];
}

class FailureNoGoogleUser extends Failure {
  const FailureNoGoogleUser(String? message)
      : super(message ?? 'No google user found.');
  @override
  List<Object?> get props => [];
}

class FailureOnNewUserCreation extends Failure {
  const FailureOnNewUserCreation()
      : super('Error occured, while creating new user. Please, try again.');
  @override
  List<Object?> get props => [];
}

class FailureUserAlreadyExists extends Failure {
  const FailureUserAlreadyExists()
      : super('User with this email already exists. Try to sign in, please.');
  @override
  List<Object?> get props => [];
}

class FailureNoUserWithEmail extends Failure {
  const FailureNoUserWithEmail()
      : super(
            'We could not find any user with matching email. Please check spelling or create new account.');
  @override
  List<Object?> get props => [];
}

class FailureDirectus extends Failure {
  const FailureDirectus() : super('Network issue occured, please try again.');
  @override
  List<Object?> get props => [];
}

class WhoopDidNotReturnAuthCodeFailure extends Failure {
  const WhoopDidNotReturnAuthCodeFailure()
      : super('Whoop connection failed. Please, try again.');
  @override
  List<Object?> get props => [];
}

class WhoopFailedToReturnAccessToken extends Failure {
  const WhoopFailedToReturnAccessToken()
      : super('Whoop did not return access token');
  @override
  List<Object?> get props => [];
}

class WhoopNoDataFailure extends Failure {
  const WhoopNoDataFailure() : super('There is no data.');

  @override
  // TODO: implement props
  List<Object?> get props => throw UnimplementedError();
}

class ChatGptRequestMealFailures extends Failure {
  const ChatGptRequestMealFailures(super.message);

  @override
  List<Object?> get props => throw UnimplementedError();
}

class FailedUpdateUser extends Failure {
  const FailedUpdateUser(String e) : super('User updating was failed with: $e');

  @override
  // TODO: implement props
  List<Object?> get props => throw UnimplementedError();
}

class FailedToGetUserData extends Failure {
  const FailedToGetUserData(String e) : super('Failed to get user data: $e');

  @override
  // TODO: implement props
  List<Object?> get props => throw UnimplementedError();
}

class FailureNoAppleUser extends Failure {
  const FailureNoAppleUser(String? message)
      : super(message ?? 'No apple user found.');
  @override
  List<Object?> get props => [];
}

class WhoopAuthenticationFailure extends Failure {
  const WhoopAuthenticationFailure() : super('Whoop connection was cancelled.');
  @override
  List<Object?> get props => [];
}

class WhoopDataDueToRefresh extends Failure {
  const WhoopDataDueToRefresh()
      : super('It seems, that WHOOP Data needs to be refreshed.');

  @override
  // TODO: implement props
  List<Object?> get props => throw UnimplementedError();
}
