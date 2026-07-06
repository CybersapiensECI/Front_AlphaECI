import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
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
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Recibidas'),
              Tab(text: 'Enviadas'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ReceivedTab(),
                _SentTab(),
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

class _MatchList extends StatelessWidget {
  const _MatchList({required this.items, required this.trailingBuilder});

  final List<MatchWithProfile> items;
  final Widget Function(BuildContext, MatchWithProfile) trailingBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
                  leading: ProfileAvatar(
                    name: item.profile.name,
                    photoUrl: item.profile.photoUrl,
                    radius: 24,
                  ),
                  title: Text(item.profile.name),
                  subtitle: item.match.score != null
                      ? Text(
                          'Afinidad ${(item.match.score! * 100).round()}%')
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
