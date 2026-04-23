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
      error: json['error'] is Map<String, dynamic>
          ? (json['error'] as Map<String, dynamic>)
          : (json['error'] != null ? {'message': json['error']} : null),
      output: json['output'] is Map<String, dynamic>
          ? (json['output'] as Map<String, dynamic>)
          : null,
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
