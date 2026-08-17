import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/network/json_helpers.dart';
import '../../core/network/socket_service.dart';
import '../../core/utils/friendly_error.dart';
import '../../models/chat.dart';
import '../../providers/providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  final _picker = ImagePicker();
  final List<ChatMessage> _live = [];
  late final void Function(dynamic) _onSocket;
  SocketService? _socket;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _onSocket = (data) {
      if (data is! Map) return;
      final map = asMap(data);
      final msg = ChatMessage.fromJson(map['message'] is Map ? asMap(map['message']) : map);
      if (msg.chatId.isNotEmpty && msg.chatId != widget.chatId) return;
      setState(() => _live.add(msg));
      _jump();
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _socket = ref.read(socketServiceProvider);
      _socket!.connect();
      _socket!.joinChat(widget.chatId);
      _socket!.onMessage(_onSocket);
    });
  }

  @override
  void dispose() {
    _socket?.offMessage(_onSocket);
    _socket?.leaveChat(widget.chatId);
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _mediaUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    return ApiConstants.resolveMediaUrl(url, ref.read(apiBaseProvider));
  }

  void _jump() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 80, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  String? _displayText(ChatMessage message) {
    final text = message.text.trim();
    if (text.isEmpty) return null;
    if (looksLikeObjectId(text)) return null;
    return text;
  }

  Future<void> _send({String? text, String? imageUrl, String? videoUrl}) async {
    final body = text?.trim() ?? '';
    if (body.isEmpty && (imageUrl == null || imageUrl.isEmpty) && (videoUrl == null || videoUrl.isEmpty)) return;
    setState(() => _sending = true);
    try {
      final msg = await ref.read(chatRepositoryProvider).send(
            widget.chatId,
            text: body.isEmpty ? null : body,
            imageUrl: imageUrl,
            videoUrl: videoUrl,
          );
      setState(() => _live.add(msg));
      _jump();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendText() async {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    _text.clear();
    await _send(text: text);
  }

  Future<void> _pickMedia(ImageSource source, {required bool video}) async {
    final file = video
        ? await _picker.pickVideo(source: source, maxDuration: const Duration(minutes: 2))
        : await _picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;
    setState(() => _sending = true);
    try {
      final uploaded = await ref.read(uploadRepositoryProvider).uploadChatMedia(file.path);
      if (uploaded.url.isEmpty) throw Exception('Upload failed');
      await _send(
        imageUrl: uploaded.type == 'image' ? uploaded.url : null,
        videoUrl: uploaded.type == 'video' ? uploaded.url : null,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showAttachSheet() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.accent),
              title: const Text('Photo from gallery'),
              onTap: () => Navigator.pop(ctx, 'photo_gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined, color: AppColors.accent),
              title: const Text('Video from gallery'),
              onTap: () => Navigator.pop(ctx, 'video_gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.accent),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, 'photo_camera'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'photo_gallery':
        await _pickMedia(ImageSource.gallery, video: false);
      case 'video_gallery':
        await _pickMedia(ImageSource.gallery, video: true);
      case 'photo_camera':
        await _pickMedia(ImageSource.camera, video: false);
    }
  }

  void _openVideo(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _FullScreenVideo(url: url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(chatMessagesProvider(widget.chatId));
    final me = ref.watch(authProvider).user?.id;
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
              error: (e, _) => Center(child: Text(friendlyError(e))),
              data: (server) {
                final seen = <String>{};
                final all = <ChatMessage>[];
                for (final m in [...server, ..._live]) {
                  if (m.id.isNotEmpty && seen.contains(m.id)) continue;
                  if (m.id.isNotEmpty) seen.add(m.id);
                  all.add(m);
                }
                if (all.isEmpty) {
                  return const Center(
                    child: Text(
                      'Say hello to start the conversation.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: all.length,
                  itemBuilder: (_, i) => _MessageBubble(
                    mine: me != null && all[i].senderId == me,
                    displayText: _displayText(all[i]),
                    imageUrl: _mediaUrl(all[i].imageUrl),
                    videoUrl: _mediaUrl(all[i].videoUrl),
                    onVideoTap: _openVideo,
                  ),
                );
              },
            ),
          ),
          if (_sending)
            const LinearProgressIndicator(minHeight: 2, color: AppColors.accent),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _sending ? null : _showAttachSheet,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: AppColors.accent,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      decoration: const InputDecoration(hintText: 'Message / Sandesh'),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sending ? null : _sendText(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _sendText,
                    style: IconButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.white),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.mine,
    required this.displayText,
    required this.imageUrl,
    required this.videoUrl,
    required this.onVideoTap,
  });

  final bool mine;
  final String? displayText;
  final String imageUrl;
  final String videoUrl;
  final ValueChanged<String> onVideoTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.isNotEmpty;
    final hasVideo = videoUrl.isNotEmpty;
    if (!hasImage && !hasVideo && displayText == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: mine ? AppColors.accent : (isDark ? AppColors.darkSurface : AppColors.surface),
          borderRadius: BorderRadius.circular(14),
          border: mine ? null : Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl.startsWith('http')
                      ? CachedNetworkImage(imageUrl: imageUrl, height: 180, width: 220, fit: BoxFit.cover)
                      : Image.file(File(imageUrl), height: 180, width: 220, fit: BoxFit.cover),
                ),
              ),
            if (hasVideo)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () => onVideoTap(videoUrl),
                  child: Container(
                    height: 180,
                    width: 220,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.play_circle_fill_rounded, color: AppColors.white, size: 56),
                    ),
                  ),
                ),
              ),
            if (displayText != null)
              Text(
                displayText!,
                style: TextStyle(
                  color: mine ? AppColors.white : Theme.of(context).colorScheme.onSurface,
                  height: 1.35,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenVideo extends StatefulWidget {
  const _FullScreenVideo({required this.url});
  final String url;

  @override
  State<_FullScreenVideo> createState() => _FullScreenVideoState();
}

class _FullScreenVideoState extends State<_FullScreenVideo> {
  late final VideoPlayerController _controller;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Center(
        child: _ready
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(color: AppColors.accent),
      ),
    );
  }
}
