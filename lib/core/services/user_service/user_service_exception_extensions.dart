import 'package:rishai/core/services/user_service/user_service_client.dart';

/// Maps User Service WHOOP errors to client-side recovery actions.
extension UserServiceExceptionWhoop on UserServiceException {
  /// Backend temporarily blocked refresh after repeated failures (circuit breaker).
  bool get isWhoopTokenRefreshBlocked {
    if (statusCode != 403) return false;
    final normalized = message.toLowerCase();
    return normalized.contains('token refresh temporarily blocked') ||
        normalized.contains('repeated failures');
  }

  /// WHOOP tokens on the backend are invalid — user must re-auth, not retry API calls.
  bool get requiresWhoopReconnect {
    if (isWhoopTokenRefreshBlocked) return true;
    if (statusCode == 401) return true;
    if (statusCode == 403) {
      final normalized = message.toLowerCase();
      return normalized.contains('whoop');
    }
    return false;
  }
}
