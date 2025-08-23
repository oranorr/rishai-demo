/// Сервис для проверки белого списка аккаунтов
/// Аккаунты из белого списка получают автоматическую активацию подписки
abstract interface class AccountsWhiteListService {
  /// Проверяет, находится ли email в белом списке
  /// Возвращает true если email найден в списке
  Future<bool> isEmailInWhiteList(String email);

  /// Получает список всех email-адресов из белого списка
  /// Возвращает пустой список в случае ошибки
  Future<List<String>> getWhiteListEmails();
}
