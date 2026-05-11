enum TaskStatus {
  pending,
  processing,
  done,
  failed,
}

TaskStatus? taskStatusFromString(String? value) {
  switch (value) {
    case 'pending':
      return TaskStatus.pending;
    case 'processing':
      return TaskStatus.processing;
    case 'done':
      return TaskStatus.done;
    case 'failed':
      return TaskStatus.failed;
    default:
      return null;
  }
}

class PublicTaskEntity {
  PublicTaskEntity({
    required this.taskId,
    required this.type,
    required this.status,
    this.error,
    this.output,
  });

  factory PublicTaskEntity.fromMap(Map<String, dynamic> json) {
    return PublicTaskEntity(
      taskId: (json['taskId'] as String?) ?? (json['id'] as String?) ?? '',
      type: (json['type'] as String?) ?? '',
      status:
          taskStatusFromString(json['status'] as String?) ?? TaskStatus.pending,
      error: _asStringKeyMap(json['error']) ??
          (json['error'] != null && json['error'] is! Map
              ? {'message': json['error']}
              : null),
      // После [jsonDecode] вложенные объекты часто [Map<dynamic, dynamic>],
      // тогда [is Map<String, dynamic>] = false — [output] терялся, хотя в JSON есть.
      output: _asStringKeyMap(json['output']),
    );
  }

  final String taskId;
  final String type;
  final TaskStatus status;
  final Map<String, dynamic>? error;
  final Map<String, dynamic>? output;

  String? get errorMessage {
    final msg = error?['message'];
    if (msg is String && msg.trim().isNotEmpty) return msg;
    return null;
  }
}

Map<String, dynamic>? _asStringKeyMap(Object? value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}
