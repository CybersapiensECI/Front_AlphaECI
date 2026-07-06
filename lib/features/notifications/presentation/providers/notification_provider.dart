import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_client.dart';
import '../../data/notification_service_and_repo.dart';
import '../../domain/entities/app_notification.dart';

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  return NotificationRepository(
    NotificationApiService(
        ref.watch(apiClientProvider(Env.notificationUrl))),
  );
});

final notificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  final result =
      await ref.watch(notificationRepositoryProvider).getNotifications();
  return result.when(
    success: (items) => items,
    error: (failure) => throw failure,
  );
});

/// Contador para el badge de la campana. Falla en silencio (0).
final unreadCountProvider = FutureProvider<int>((ref) async {
  final result =
      await ref.watch(notificationRepositoryProvider).getUnreadCount();
  return result.dataOrNull ?? 0;
});

final notificationActionsProvider =
    Provider<NotificationActions>((ref) => NotificationActions(ref));

class NotificationActions {
  const NotificationActions(this._ref);

  final Ref _ref;

  Future<void> markAsRead(String id) async {
    await _ref.read(notificationRepositoryProvider).markAsRead(id);
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadCountProvider);
  }

  Future<void> markAllAsRead() async {
    await _ref.read(notificationRepositoryProvider).markAllAsRead();
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadCountProvider);
  }
}
