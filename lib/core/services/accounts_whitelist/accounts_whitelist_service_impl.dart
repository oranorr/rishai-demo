import 'dart:developer';

import 'package:injectable/injectable.dart';
import 'package:rishai/core/services/accounts_whitelist/accounts_whitelist_service.dart';
import 'package:rishai/core/services/directus/directus_repository.dart';

@Singleton(as: AccountsWhiteListService)
class AccountsWhiteListServiceImpl implements AccountsWhiteListService {
  AccountsWhiteListServiceImpl(this._directusService);
  final DirectusService _directusService;

  // Кэшируем данные белого списка чтобы не делать запросы каждый раз
  Map<String, dynamic>? _whiteListData;

  /// Получает данные белого списка из Directus
  /// Кэширует результат для оптимизации
  Future<Map<String, dynamic>?> _getWhiteListData() async {
    try {
      _whiteListData ??= await _directusService.readAccountsWhiteList();
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
      // Получаем список email-адресов из поля "list"
      final List<dynamic>? emailList =
          whiteListData['list']['list'] as List<dynamic>?;

      if (emailList == null || emailList.isEmpty) {
        log('[AccountsWhiteListService] Email list is null or empty');
        return false;
      }

      // Приводим к List<String> и проверяем наличие email
      final List<String> emails = emailList.cast<String>();
      final bool isInList = emails.contains(email.toLowerCase().trim());

      log('[AccountsWhiteListService] Email $email ${isInList ? "found" : "not found"} in whitelist');

      return isInList;
    } catch (e) {
      log('[AccountsWhiteListService] Error parsing whitelist data: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getWhiteListEmails() async {
    final whiteListData = await _getWhiteListData();
    if (whiteListData == null) {
      log('[AccountsWhiteListService] WhiteList data is null, returning empty list');
      return [];
    }

    try {
      final List<dynamic>? emailList = whiteListData['list'] as List<dynamic>?;

      if (emailList == null || emailList.isEmpty) {
        log('[AccountsWhiteListService] Email list is null or empty');
        return [];
      }

      final List<String> emails = emailList.cast<String>();
      log('[AccountsWhiteListService] Retrieved ${emails.length} emails from whitelist');

      return emails;
    } catch (e) {
      log('[AccountsWhiteListService] Error parsing whitelist emails: $e');
      return [];
    }
  }
}
