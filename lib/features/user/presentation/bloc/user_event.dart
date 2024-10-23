// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'user_bloc.dart';

sealed class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object> get props => [];
}

class UpdateUserEvent extends UserEvent {
  final UserEntity user;
  const UpdateUserEvent({
    required this.user,
  });
}

class CheckForSavedUser extends UserEvent {}

class CreateUserOnLogin extends UserEvent {
  final UserEntity user;
  const CreateUserOnLogin({
    required this.user,
  });
}

class UserDeleteAccount extends UserEvent {}

class UserCheckForRecomp extends UserEvent {
  const UserCheckForRecomp();
}

class UserManageDay extends UserEvent {
  final DayEntity day;
  const UserManageDay({
    required this.day,
  });
}

class UserGetDays extends UserEvent {}
