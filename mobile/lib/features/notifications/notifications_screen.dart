import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/constants/app_colors.dart';
import '../../models/notification_item.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/widgets.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final Set<String> _removedIds = {};

  Future<void> _remove(NotificationItem item) async {
    setState(() => _removedIds.add(item.id));
    try {
      await ref.read(notificationsRepositoryProvider).delete(item.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _removedIds.remove(item.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove notification. Try again.')),
      );
    }
  }

  Future<void> _open(NotificationItem n) async {
    try {
      await ref.read(notificationsRepositoryProvider).markRead(n.id);
      ref.invalidate(notificationsProvider);
    } catch (_) {}
    if (!mounted) return;
    if (n.jobId != null) context.push('/jobs/${n.jobId}');
    if (n.chatId != null) context.push('/chats/${n.chatId}');
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(notificationsProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        color: onSurface,
        onRefresh: () async {
          setState(_removedIds.clear);
          ref.invalidate(notificationsProvider);
        },
        child: list.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(notificationsProvider)),
          data: (items) {
            final visible = items.where((n) => !_removedIds.contains(n.id)).toList();
            if (visible.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  EmptyState(icon: Icons.notifications_none, title: 'You are all caught up'),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: visible.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Theme.of(context).dividerColor),
              itemBuilder: (_, i) {
                final n = visible[i];
                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: AppColors.danger,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.delete_outline_rounded, color: AppColors.white),
                        SizedBox(width: 8),
                        Text('Remove', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  onDismissed: (_) => _remove(n),
                  child: ListTile(
                    tileColor: n.read ? null : AppColors.chip.withValues(alpha: 0.45),
                    leading: Icon(
                      n.read ? Icons.notifications_none : Icons.notifications_active,
                      color: onSurface,
                    ),
                    title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(n.body),
                    trailing: n.createdAt == null
                        ? null
                        : Text(timeago.format(n.createdAt!), style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.5))),
                    onTap: () => _open(n),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
