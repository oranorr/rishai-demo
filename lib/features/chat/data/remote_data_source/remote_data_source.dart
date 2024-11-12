abstract class ChatRemoteDataSource {
  Future<bool> initGpt(String? savedThreadId);
  Future<Map<String, dynamic>> requestMealPlan(String prompt);
  Future<String?> sendMessage(String userMessage);
  Future<Map<String, dynamic>?> fetchLastChatSnap(String directusId);
  String? get threadId;
  Future<void> closeGpt();
}
