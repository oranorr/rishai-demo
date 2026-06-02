import 'dart:developer';

import 'package:rishai/features/login/presentation/bloc/login_bloc.dart';

final sessionManager = SessionManager();

/// Centralized app-session actions that must be callable from core services.
///
/// [UserServiceClient] should not duplicate logout cleanup logic. Instead, it
/// asks this manager to dispatch the same [LogoutEvent] as a manual logout, so
/// Hive, prefs, notifications, Adapty, and feature blocs are reset in one path.
class SessionManager {
  bool _logoutInProgress = false;

  void markAuthenticated() {
    _logoutInProgress = false;
  }

  Future<void> forceLogout({
    required String reason,
  }) async {
    if (_logoutInProgress) {
      log(
        '[SessionManager.forceLogout] Logout already in progress: $reason',
        name: 'SessionManager',
      );
      return;
    }

    _logoutInProgress = true;
    log(
      '[SessionManager.forceLogout] Dispatching full logout: $reason',
      name: 'SessionManager',
    );

    loginBloc.add(LogoutEvent());
  }
}
