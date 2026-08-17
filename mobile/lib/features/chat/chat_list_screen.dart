import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/constants/app_colors.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/widgets.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(chatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async => ref.invalidate(chatsProvider),
        child: chats.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(chatsProvider)),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'No chats yet',
                    subtitle: 'Chat opens after a job owner accepts your application.',
                  ),
                ],
              );
            }
            return ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final c = list[i];
                return ListTile(
                  leading: AvatarCircle(name: c.otherUserName ?? c.title, url: c.otherUserPhoto),
                  title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                    [
                      if (c.jobTitle != null) c.jobTitle,
                      c.lastMessage ?? 'No messages',
                    ].whereType<String>().join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (c.lastAt != null) Text(timeago.format(c.lastAt!), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                      if (c.unread > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                          child: Text('${c.unread}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.white)),
                        ),
                    ],
                  ),
                  onTap: () => context.push('/chats/${c.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
