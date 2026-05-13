import 'dart:developer';

import 'package:injectable/injectable.dart';
import 'package:rishai/core/services/accounts_whitelist/accounts_whitelist_service.dart';
import 'package:rishai/core/services/user_service/user_service_client.dart';

@Singleton(as: AccountsWhiteListService)
class AccountsWhiteListServiceImpl implements AccountsWhiteListService {
  AccountsWhiteListServiceImpl(this._userServiceClient);
  final UserServiceClient _userServiceClient;

  /// Кэшируем JSON whitelist с Pivot API ([GET /config/accounts-whitelist]),
  /// чтобы не дёргать сеть на каждый [isEmailInWhiteList].
  Map<String, dynamic>? _whiteListData;

  /// Загрузка и кэш whitelist; бэкенд отдаёт канонически `{ "emails": [...] }`.
  Future<Map<String, dynamic>?> _getWhiteListData() async {
    try {
      _whiteListData ??=
          await _userServiceClient.getAccountsWhitelistPublic();
      return _whiteListData;
    } catch (e, stackTrace) {
      log(
        '[AccountsWhiteListService] Error fetching whitelist data: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Только поле [emails] из ответа GET /config/accounts-whitelist.
  List<String> _emailsFromPayload(Map<String, dynamic> data) {
    final direct = data['emails'];
    if (direct is! List) {
      return const <String>[];
    }
    return direct
        .map((e) => e.toString().toLowerCase().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  Future<bool> isEmailInWhiteList(String email) async {
    if (email.isEmpty) {
      log('[AccountsWhiteListService] Empty email provided');
      return false;
    }

    final whiteListData = await _getWhiteListData();
    if (whiteListData == null) {
      log('[AccountsWhiteListService] WhiteList data is null, cannot check email');
      return false;
    }

    try {
      final emails = _emailsFromPayload(whiteListData);
      if (emails.isEmpty) {
        log('[AccountsWhiteListService] Email list is empty');
        return false;
      }

      final bool isInList = emails.contains(email.toLowerCase().trim());

      log(
        '[AccountsWhiteListService] Email $email ${isInList ? "found" : "not found"} in whitelist',
      );

      return isInList;
    } on Object catch (e) {
      log('[AccountsWhiteListService] Error parsing whitelist data: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getWhiteListEmails() async {
    final whiteListData = await _getWhiteListData();
    if (whiteListData == null) {
      log(
        '[AccountsWhiteListService] WhiteList data is null, returning empty list',
      );
      return [];
    }

    try {
      final emails = _emailsFromPayload(whiteListData);
      log(
        '[AccountsWhiteListService] Retrieved ${emails.length} emails from whitelist',
      );

      return emails;
    } on Object catch (e) {
      log('[AccountsWhiteListService] Error parsing whitelist emails: $e');
      return [];
    }
  }
}
