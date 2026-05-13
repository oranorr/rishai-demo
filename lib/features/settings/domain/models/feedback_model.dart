import 'package:equatable/equatable.dart';

/// Модель для обратной связи пользователя
class FeedbackModel extends Equatable {
  const FeedbackModel({
    required this.authorName,
    required this.email,
    required this.subject,
    required this.message,
    required this.authorDirectusId,
    this.id,
    this.media = const [],
    this.dateCreated,
  });

  /// Создает модель из данных формы
  factory FeedbackModel.fromForm({
    required String name,
    required String email,
    required String subject,
    required String message,
    required List<FeedbackMediaFile> attachments,
    String? userId,
  }) {
    return FeedbackModel(
      authorName: name,
      authorDirectusId: userId,
      email: email,
      subject: subject,
      message: message,
      media: attachments,
    );
  }
  final String? id;
  final String authorName;
  final String? authorDirectusId;
  final String email;
  final String subject;
  final String message;
  final List<FeedbackMediaFile> media;
  final DateTime? dateCreated;

  /// JSON для POST /feedback (Pivot backend): без вложений, лишние поля игнорируются на сервере.
  Map<String, dynamic> toJson() {
    return {
      'authorName': authorName,
      'authorDirectusId': authorDirectusId,
      'email': email,
      'subject': subject,
      'message': message,
    };
  }

  @override
  List<Object?> get props => [
        id,
        authorName,
        authorDirectusId,
        email,
        subject,
        message,
        media,
        dateCreated,
      ];
}

/// Модель для медиа-файлов обратной связи
class FeedbackMediaFile extends Equatable {
  const FeedbackMediaFile({
    required this.directusFileId,
    required this.path,
    required this.name,
    this.id,
    this.feedbackId,
  });
  final String? id;
  final String? feedbackId;
  final String directusFileId;
  final String path;
  final String name;

  /// Конвертирует модель в формат JSON для отправки в Directus
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (feedbackId != null) 'feedback_id': feedbackId,
      'directus_files_id': directusFileId,
    };
  }

  @override
  List<Object?> get props => [id, feedbackId, directusFileId, path, name];
}
