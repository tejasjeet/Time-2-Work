import '../core/network/api_client.dart';
import '../core/network/json_helpers.dart';
import '../models/chat.dart';

class ChatRepository {
  ChatRepository(this._api);
  final ApiClient _api;

  Future<List<ChatThread>> list() async {
    final body = await _api.get('/chats');
    return unwrapList(body).whereType<Map>().map((e) => ChatThread.fromJson(asMap(e))).toList();
  }

  Future<List<ChatMessage>> messages(String chatId) async {
    final body = await _api.get('/chats/$chatId/messages');
    return unwrapList(body).whereType<Map>().map((e) => ChatMessage.fromJson(asMap(e))).toList();
  }

  Future<ChatMessage> send(String chatId, {String? text, String? imageUrl, String? videoUrl}) async {
    final body = await _api.post('/chats/$chatId/messages', data: {
      if (text != null && text.isNotEmpty) 'text': text,
      if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      if (videoUrl != null && videoUrl.isNotEmpty) 'videoUrl': videoUrl,
    });
    return ChatMessage.fromJson(unwrapMap(body));
  }
}
