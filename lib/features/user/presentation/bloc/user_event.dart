// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'user_bloc.dart';

sealed class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object> get props => [];
}

class UpdateUserEvent extends UserEvent {
  final UserEntity user;
  final Completer<bool>? completion;
  const UpdateUserEvent({
    required this.user,
    this.completion,
  });
}

class CheckForSavedUser extends UserEvent {}

class CreateUserOnLogin extends UserEvent {
  final UserEntity user;

  /// Флаг для создания 200 дней истории при первом входе (только для тестирования)
  final bool shouldCreateHistoryDays;

  const CreateUserOnLogin({
    required this.user,
    this.shouldCreateHistoryDays = false,
  });
}

class UserDeleteAccount extends UserEvent {}

class UserManageDay extends UserEvent {
  final DayEntity day;
  const UserManageDay({
    required this.day,
  });
}

class UserGetDays extends UserEvent {
  final DayEntity newDay;
  const UserGetDays({
    required this.newDay,
  });
}

class UserUpdateDay extends UserEvent {
  final DayEntity day;
  const UserUpdateDay({
    required this.day,
  });
}

/// Событие для добавления 200 дней истории пользователю
class UserAddHistoryDays extends UserEvent {
  const UserAddHistoryDays();
}
