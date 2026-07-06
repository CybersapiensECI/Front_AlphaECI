import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final scheme = Theme.of(context).colorScheme;

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationActionsProvider).markAllAsRead(),
            child: const Text('Marcar todas'),
          ),
        ],
      ),
      body: AsyncValueView<List<AppNotification>>(
        value: notifications,
        onRetry: () => ref.invalidate(notificationsProvider),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none,
              message: 'Sin notificaciones. Cuando pase algo, te avisamos 🔔',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final notification = items[index];
                return FadeSlideIn(
                  delay: Duration(milliseconds: 40 * index),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                          maxWidth: Breakpoints.contentMaxWidth),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        color: notification.read
                            ? null
                            : scheme.tertiary.withValues(alpha: 0.08),
                        child: ListTile(
                          leading: Icon(
                            _iconFor(notification.type),
                            color: notification.read
                                ? scheme.onSurfaceVariant
                                : scheme.primary,
                          ),
                          title: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.read
                                  ? FontWeight.normal
                                  : FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(notification.body),
                          trailing: notification.createdAt != null
                              ? Text(
                                  DateFormat('d MMM\nHH:mm')
                                      .format(notification.createdAt!),
                                  textAlign: TextAlign.right,
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                )
                              : null,
                          onTap: notification.read
                              ? null
                              : () => ref
                                  .read(notificationActionsProvider)
                                  .markAsRead(notification.id),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _iconFor(String? type) {
    final t = type?.toUpperCase() ?? '';
    if (t.contains('MATCH') || t.contains('CONNECTION')) {
      return Icons.favorite_outline;
    }
    if (t.contains('PARCHE') || t.contains('INVITATION')) {
      return Icons.groups_outlined;
    }
    if (t.contains('EVENT') || t.contains('REMINDER')) {
      return Icons.event_outlined;
    }
    return Icons.notifications_outlined;
  }
}
