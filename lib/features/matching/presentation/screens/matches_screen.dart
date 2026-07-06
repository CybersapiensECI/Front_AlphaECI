import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/mascot.dart';
import '../../../auth/presentation/widgets/auth_layout.dart'
    show showAppSnackBar;
import '../../../profile/presentation/widgets/profile_avatar.dart';
import '../../domain/entities/match.dart';
import '../providers/matching_provider.dart';

/// Solicitudes de conexión: recibidas (aceptar/rechazar) y enviadas (estado).
class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Recibidas'),
              Tab(text: 'Enviadas'),
              Tab(text: 'Amistades'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ReceivedTab(),
                _SentTab(),
                _FriendsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceivedTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final received = ref.watch(receivedMatchesProvider);
    return AsyncValueView<List<MatchWithProfile>>(
      value: received,
      onRetry: () => ref.invalidate(receivedMatchesProvider),
      data: (items) {
        final pending = [
          for (final m in items)
            if (m.match.status == MatchStatus.pending) m,
        ];
        if (pending.isEmpty) {
          return const EmptyState(
            icon: Icons.mark_email_unread_outlined,
            message: 'No tienes solicitudes pendientes.',
          );
        }
        return _MatchList(
          items: pending,
          trailingBuilder: (context, item) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(
                tooltip: 'Rechazar',
                icon: const Icon(Icons.close),
                onPressed: () =>
                    _respond(context, ref, item, MatchStatus.rejected),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Aceptar',
                icon: const Icon(Icons.check),
                onPressed: () =>
                    _respond(context, ref, item, MatchStatus.accepted),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    MatchWithProfile item,
    MatchStatus status,
  ) async {
    final result =
        await ref.read(matchActionsProvider).respond(item.match.id, status);
    if (!context.mounted) return;
    result.when(
      success: (_) => showAppSnackBar(
        context,
        status == MatchStatus.accepted
            ? '¡Ahora estás conectado con ${item.profile.name}! 🎉'
            : 'Solicitud rechazada.',
      ),
      error: (failure) => showAppSnackBar(context, failure.message),
    );
  }
}

class _SentTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sent = ref.watch(sentMatchesProvider);
    return AsyncValueView<List<MatchWithProfile>>(
      value: sent,
      onRetry: () => ref.invalidate(sentMatchesProvider),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.send_outlined,
            message:
                'Aún no has enviado solicitudes.\n¡Ve a Descubrir y conecta!',
          );
        }
        return _MatchList(
          items: items,
          trailingBuilder: (context, item) =>
              _StatusChip(status: item.match.status),
        );
      },
    );
  }
}

/// Amistades: conexiones aceptadas con acciones de gestión.
class _FriendsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsProvider);
    return AsyncValueView<List<MatchWithProfile>>(
      value: friends,
      onRetry: () => ref.invalidate(friendsProvider),
      data: (items) {
        if (items.isEmpty) {
          return const MascotEmptyState(
            asset: AppAssets.stickerHello,
            message: 'Aún no tienes amistades.\nAcepta solicitudes o '
                'conecta en Descubrir.',
          );
        }
        return _MatchList(
          items: items,
          trailingBuilder: (context, item) => PopupMenuButton<String>(
            tooltip: 'Opciones',
            onSelected: (action) => _handle(context, ref, item, action),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'block',
                child: Row(children: [
                  Icon(Icons.block, size: 20),
                  SizedBox(width: 8),
                  Text('Bloquear'),
                ]),
              ),
              PopupMenuItem(
                value: 'report',
                child: Row(children: [
                  Icon(Icons.flag_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('Reportar'),
                ]),
              ),
              PopupMenuItem(
                value: 'remove',
                child: Row(children: [
                  Icon(Icons.person_remove_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('Eliminar amistad'),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    MatchWithProfile item,
    String action,
  ) async {
    final name = item.profile.name;
    final (title, body, confirmLabel) = switch (action) {
      'block' => (
          'Bloquear a $name',
          'No verás más su perfil ni recibirás mensajes.',
          'Bloquear'
        ),
      'report' => (
          'Reportar a $name',
          'Se enviará el reporte al equipo de convivencia.',
          'Reportar'
        ),
      _ => (
          'Eliminar amistad',
          'Dejarán de estar conectados. Esta acción se puede rehacer '
              'con un nuevo match.',
          'Eliminar'
        ),
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    if (action == 'remove') {
      // Reutiliza el endpoint real de respuesta: pasa el match a REJECTED.
      final result = await ref
          .read(matchActionsProvider)
          .respond(item.match.id, MatchStatus.rejected);
      if (!context.mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(friendsProvider);
          showAppSnackBar(context, 'Amistad con $name eliminada.');
        },
        error: (failure) => showAppSnackBar(context, failure.message),
      );
      return;
    }

    // TODO(backend): matching-service aún no expone bloquear/reportar.
    showAppSnackBar(
      context,
      action == 'block'
          ? '$name bloqueado en este dispositivo. Pendiente en servidor.'
          : 'Reporte de $name registrado. Pendiente en servidor.',
    );
  }
}

class _MatchList extends StatelessWidget {
  const _MatchList({required this.items, required this.trailingBuilder});

  final List<MatchWithProfile> items;
  final Widget Function(BuildContext, MatchWithProfile) trailingBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return FadeSlideIn(
          delay: Duration(milliseconds: 50 * index),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.of(context),
                    ),
                    child: ProfileAvatar(
                      name: item.profile.name,
                      photoUrl: item.profile.photoUrl,
                      radius: 22,
                    ),
                  ),
                  title: Text(item.profile.name),
                  subtitle: item.match.score != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: AnimatedProgressBar(
                                  value:
                                      item.match.score!.clamp(0.0, 1.0),
                                  height: 5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(item.match.score! * 100).round()}%',
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        )
                      : null,
                  trailing: trailingBuilder(context, item),
                  onTap: () => context.push(
                    Routes.publicProfilePath(item.profile.id),
                    extra: item.profile,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final MatchStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MatchStatus.pending => ('Pendiente', Colors.amber),
      MatchStatus.accepted => ('Aceptada', Colors.green),
      MatchStatus.rejected => ('Rechazada', Colors.redAccent),
    };
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
    );
  }
}
