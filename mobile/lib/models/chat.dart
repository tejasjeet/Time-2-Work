import '../core/network/json_helpers.dart';

class ChatThread {
  final String id;
  final String title;
  final String? lastMessage;
  final DateTime? lastAt;
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserPhoto;
  final String? jobId;
  final String? jobTitle;
  final int unread;

  const ChatThread({
    required this.id,
    required this.title,
    this.lastMessage,
    this.lastAt,
    this.otherUserId,
    this.otherUserName,
    this.otherUserPhoto,
    this.jobId,
    this.jobTitle,
    this.unread = 0,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> other = {};
    if (json['otherUser'] is Map) {
      other = asMap(json['otherUser']);
    } else if (json['participant'] is Map) {
      other = asMap(json['participant']);
    } else if (json['peer'] is Map) {
      other = asMap(json['peer']);
    }

    final last = json['lastMessage'];
    String? lastText;
    DateTime? lastAt;
    if (last is Map) {
      final m = asMap(last);
      lastText = readString(m, ['text', 'body', 'content']);
      lastAt = readDate(m['createdAt']);
    } else {
      lastText = last?.toString();
      lastAt = readDate(json['lastMessageAt'] ?? json['updatedAt']);
    }

    final name = readString(other, ['name']) ?? readString(json, ['title', 'name']);
    return ChatThread(
      id: readId(json),
      title: name ?? 'Chat',
      lastMessage: lastText,
      lastAt: lastAt,
      otherUserId: readString(other, ['id', '_id']) ?? readString(json, ['otherUserId']),
      otherUserName: name,
      otherUserPhoto: readString(other, ['photoUrl', 'avatar']),
      jobId: readString(json, ['jobId']),
      jobTitle: json['job'] is Map ? readString(asMap(json['job']), ['title']) : readString(json, ['jobTitle']),
      unread: readInt(json['unread'] ?? json['unreadCount']) ?? 0,
    );
  }
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final String? imageUrl;
  final String? videoUrl;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.text = '',
    this.imageUrl,
    this.videoUrl,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: readId(json),
      chatId: readString(json, ['chatId', 'roomId']) ?? '',
      senderId: readString(json, ['senderId', 'from', 'userId']) ??
          (json['sender'] is Map ? readId(asMap(json['sender'])) : ''),
      text: readString(json, ['text', 'body', 'content', 'message']) ?? '',
      imageUrl: readString(json, ['imageUrl', 'image', 'photoUrl']),
      videoUrl: readString(json, ['videoUrl', 'video']),
      createdAt: readDate(json['createdAt']),
    );
  }
}
