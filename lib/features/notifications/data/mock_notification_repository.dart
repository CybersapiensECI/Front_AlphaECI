// TODO(demo): datos falsos para ver la app sin backends. Eliminar en prod.
import '../../../core/errors/result.dart';
import '../domain/entities/app_notification.dart';
import 'notification_service_and_repo.dart';

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository();

  final List<AppNotification> _items = [
    AppNotification(
      id: 'n1',
      title: 'Nueva solicitud de conexión',
      body: 'Carlos López quiere conectar contigo.',
      read: false,
      type: 'CONNECTION_REQUEST',
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    AppNotification(
      id: 'n2',
      title: 'Invitación a parche',
      body: 'Te invitaron al Torneo de Smash Bros.',
      read: false,
      type: 'PARCHE_INVITATION',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'n3',
      title: 'Recordatorio de evento',
      body: 'Taller de Liderazgo mañana a las 10:00.',
      read: true,
      type: 'EVENT_REMINDER',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  Future<Result<T>> _ok<T>(T value) =>
      Future.delayed(const Duration(milliseconds: 300), () => Success(value));

  @override
  Future<Result<List<AppNotification>>> getNotifications() =>
      _ok(List.of(_items));

  @override
  Future<Result<int>> getUnreadCount() =>
      _ok(_items.where((n) => !n.read).length);

  @override
  Future<Result<void>> markAsRead(String id) {
    final index = _items.indexWhere((n) => n.id == id);
    if (index >= 0) {
      final old = _items[index];
      _items[index] = AppNotification(
        id: old.id,
        title: old.title,
        body: old.body,
        read: true,
        type: old.type,
        referenceId: old.referenceId,
        createdAt: old.createdAt,
      );
    }
    return _ok(null);
  }

  @override
  Future<Result<void>> markAllAsRead() {
    for (var i = 0; i < _items.length; i++) {
      final old = _items[i];
      _items[i] = AppNotification(
        id: old.id,
        title: old.title,
        body: old.body,
        read: true,
        type: old.type,
        referenceId: old.referenceId,
        createdAt: old.createdAt,
      );
    }
    return _ok(null);
  }
}
