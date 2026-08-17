import '../core/network/json_helpers.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String? type;
  final String? jobId;
  final String? chatId;
  final bool read;
  final DateTime? createdAt;

  const NotificationItem({
    required this.id,
    required this.title,
    this.body = '',
    this.type,
    this.jobId,
    this.chatId,
    this.read = false,
    this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: readId(json),
      title: readString(json, ['title', 'heading']) ?? 'Notification',
      body: readString(json, ['body', 'message', 'text']) ?? '',
      type: readString(json, ['type', 'kind']),
      jobId: readString(json, ['jobId']),
      chatId: readString(json, ['chatId']),
      read: readBool(json['read'] ?? json['isRead']),
      createdAt: readDate(json['createdAt']),
    );
  }
}
