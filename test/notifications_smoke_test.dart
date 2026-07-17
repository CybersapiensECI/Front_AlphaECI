import 'package:alphafront/core/theme/app_theme.dart';
import 'package:alphafront/features/notifications/domain/entities/app_notification.dart';
import 'package:alphafront/features/notifications/presentation/providers/notification_provider.dart';
import 'package:alphafront/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('NotificationsScreen construye sin excepciones', (tester) async {
    final items = [
      AppNotification(
        id: 'n1',
        title: 'Nueva solicitud de conexión',
        body: 'Carlos quiere conectar contigo.',
        read: false,
        type: 'CONNECTION_REQUEST',
        referenceId: 'm2',
        createdAt: DateTime.now(),
      ),
      AppNotification(
        id: 'n2',
        title: 'Invitación a parche',
        body: 'Te invitaron al torneo.',
        read: false,
        type: 'PARCHE_INVITATION',
        referenceId: 'p3',
        createdAt: DateTime.now(),
      ),
      AppNotification(
        id: 'n3',
        title: 'Recordatorio',
        body: 'Taller mañana.',
        read: true,
        type: 'EVENT_REMINDER',
        createdAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationsProvider.overrideWith((ref) async => items),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const NotificationsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.text('Nueva solicitud de conexión'), findsOneWidget);
  });
}
