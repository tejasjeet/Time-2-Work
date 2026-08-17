import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/api_constants.dart';
import '../storage/local_store.dart';
import 'api_client.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService(ref);
  ref.onDispose(service.dispose);
  return service;
});

class SocketService {
  SocketService(this._ref);

  final Ref _ref;
  io.Socket? _socket;
  final Map<String, List<void Function(dynamic)>> _listeners = {};

  bool get connected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket?.connected == true) return;
    final token = await _ref.read(localStoreProvider).getToken();
    if (token == null || token.isEmpty) return;

    final url = ApiConstants.socketUrlFrom(_ref.read(apiBaseProvider));
    _socket?.dispose();
    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _socket!.onConnect((_) {});
    _socket!.on('message', _emit);
    _socket!.on('message:new', _emit);
    _socket!.on('chat:message', _emit);
    _socket!.on('notification', _emit);
  }

  void joinChat(String chatId) {
    _socket?.emit('join', {'chatId': chatId});
    _socket?.emit('chat:join', chatId);
  }

  void leaveChat(String chatId) {
    _socket?.emit('leave', {'chatId': chatId});
    _socket?.emit('chat:leave', chatId);
  }

  void onMessage(void Function(dynamic data) handler) {
    _listeners.putIfAbsent('message', () => []).add(handler);
  }

  void offMessage(void Function(dynamic data) handler) {
    _listeners['message']?.remove(handler);
  }

  void _emit(dynamic data) {
    for (final h in List<void Function(dynamic)>.from(_listeners['message'] ?? const [])) {
      h(data);
    }
  }

  void dispose() {
    _listeners.clear();
    _socket?.dispose();
    _socket = null;
  }
}
