import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/mascot.dart';
import '../../../auth/presentation/widgets/auth_layout.dart'
    show showAppSnackBar;
import '../../../home/presentation/screens/home_screen.dart';
import '../../../matching/domain/entities/match.dart';
import '../../../matching/presentation/providers/matching_provider.dart';
import '../../../parches/presentation/providers/parche_provider.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notification_provider.dart';

/// Tipo semántico de la notificación (deducido del campo type).
enum _NotificationKind { match, parcheInvitation, reminder, general }

_NotificationKind _kindOf(String? type) {
  final t = type?.toUpperCase() ?? '';
  if (t.contains('MATCH') || t.contains('CONNECTION')) {
    return _NotificationKind.match;
  }
  if (t.contains('PARCHE') || t.contains('INVITATION')) {
    return _NotificationKind.parcheInvitation;
  }
  if (t.contains('EVENT') || t.contains('REMINDER')) {
    return _NotificationKind.reminder;
  }
  return _NotificationKind.general;
}

/// Sticker de la mascota según el tipo de notificación.
String _stickerOf(_NotificationKind kind) => switch (kind) {
      _NotificationKind.match => AppAssets.stickerLove,
      _NotificationKind.parcheInvitation => AppAssets.stickerHey,
      _NotificationKind.reminder => AppAssets.stickerReminder,
      _NotificationKind.general => AppAssets.stickerHello,
    };

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

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
            return const MascotEmptyState(
              asset: AppAssets.stickerGoodnight,
              message:
                  'Todo tranquilo por aquí.\nCuando pase algo, te avisamos 🔔',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    maxWidth: Breakpoints.contentMaxWidth),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) => FadeSlideIn(
                    delay: Duration(milliseconds: 40 * index),
                    child: _NotificationCard(notification: items[index]),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.notification});

  final AppNotification notification;

  /// Tocar la notificación: marcar leída + ir al apartado correspondiente.
  void _open(BuildContext context, WidgetRef ref, _NotificationKind kind) {
    ref.read(notificationActionsProvider).markAsRead(notification.id);
    final tab = switch (kind) {
      _NotificationKind.match => HomeTabs.matches,
      _NotificationKind.parcheInvitation => HomeTabs.parches,
      _NotificationKind.reminder => HomeTabs.eventos,
      _NotificationKind.general => HomeTabs.inicio,
    };
    ref.read(homeTabProvider.notifier).state = tab;
    context.go(Routes.home);
  }

  Future<void> _acceptMatch(BuildContext context, WidgetRef ref) async {
    final matchId = notification.referenceId;
    if (matchId == null) {
      _open(context, ref, _NotificationKind.match);
      return;
    }
    final result = await ref
        .read(matchActionsProvider)
        .respond(matchId, MatchStatus.accepted);
    if (!context.mounted) return;
    result.when(
      success: (_) {
        ref.read(notificationActionsProvider).markAsRead(notification.id);
        ref.invalidate(friendsProvider);
        showAppSnackBar(context, '¡Conexión aceptada! 🎉');
      },
      error: (failure) => showAppSnackBar(context, failure.message),
    );
  }

  Future<void> _rejectMatch(BuildContext context, WidgetRef ref) async {
    final matchId = notification.referenceId;
    if (matchId == null) {
      ref.read(notificationActionsProvider).markAsRead(notification.id);
      return;
    }
    final result = await ref
        .read(matchActionsProvider)
        .respond(matchId, MatchStatus.rejected);
    if (!context.mounted) return;
    result.when(
      success: (_) {
        ref.read(notificationActionsProvider).markAsRead(notification.id);
        showAppSnackBar(context, 'Solicitud rechazada.');
      },
      error: (failure) => showAppSnackBar(context, failure.message),
    );
  }

  Future<void> _acceptParche(BuildContext context, WidgetRef ref) async {
    final parcheId = notification.referenceId;
    if (parcheId == null) {
      _open(context, ref, _NotificationKind.parcheInvitation);
      return;
    }
    final result = await ref.read(parcheActionsProvider).join(parcheId);
    if (!context.mounted) return;
    result.when(
      success: (message) {
        ref.read(notificationActionsProvider).markAsRead(notification.id);
        showAppSnackBar(context, '$message 🎉');
      },
      error: (failure) => showAppSnackBar(context, failure.message),
    );
  }

  void _dismiss(WidgetRef ref) =>
      ref.read(notificationActionsProvider).markAsRead(notification.id);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final kind = _kindOf(notification.type);
    final actionable = kind == _NotificationKind.match ||
        kind == _NotificationKind.parcheInvitation;
    final pending = !notification.read;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: pending ? scheme.tertiary.withValues(alpha: 0.08) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _open(context, ref, kind),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Expresión de la mascota según el tipo.
                  MascotSticker(asset: _stickerOf(kind), size: 56),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight:
                                pending ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(notification.body,
                            style: theme.textTheme.bodyMedium),
                        if (notification.createdAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('d MMM · HH:mm')
                                .format(notification.createdAt!),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Recordatorios/genéricas: descartar con una X.
                  if (!actionable && pending)
                    IconButton(
                      tooltip: 'Descartar',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _dismiss(ref),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                ],
              ),
              // Match/invitación pendiente: aceptar o rechazar aquí mismo.
              if (actionable && pending) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => kind == _NotificationKind.match
                          ? _rejectMatch(context, ref)
                          : _dismiss(ref),
                      child: const Text('Rechazar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => kind == _NotificationKind.match
                          ? _acceptMatch(context, ref)
                          : _acceptParche(context, ref),
                      child: const Text('Aceptar'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
