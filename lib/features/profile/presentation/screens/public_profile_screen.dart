import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/auth_layout.dart'
    show showAppSnackBar;
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../matching/domain/entities/match.dart';
import '../../../matching/presentation/providers/matching_provider.dart';
import '../../domain/entities/profile.dart';
import '../widgets/profile_avatar.dart';

/// Perfil público de otro estudiante (RFB05).
/// Recibe el ProfileSummary por extra; muestra solo datos públicos
/// (nunca correo ni datos sensibles).
class PublicProfileScreen extends ConsumerStatefulWidget {
  const PublicProfileScreen({super.key, required this.summary});

  final ProfileSummary summary;

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  bool _busy = false;

  Future<void> _connect() async {
    final session = ref.read(authControllerProvider).session;
    if (session == null) return;
    setState(() => _busy = true);
    final result = await ref.read(matchingRepositoryProvider).createMatch(
          requesterId: session.userId,
          targetId: widget.summary.id,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (_) {
        ref.invalidate(relationshipProvider(widget.summary.id));
        showAppSnackBar(context, 'Solicitud enviada a ${widget.summary.name} 🚀');
      },
      error: (failure) => showAppSnackBar(context, failure.message),
    );
  }

  /// Ya son amigos: abre (o crea, si es una amistad de antes de que
  /// existiera este mecanismo) la sala directa y navega al chat.
  Future<void> _message() async {
    setState(() => _busy = true);
    final result =
        await ref.read(chatRepositoryProvider).ensureFriendRoom(widget.summary.id);
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (connection) => context.push(
        Routes.chatRoomPath(connection.chatRoomId),
        extra: ChatConversation(connection: connection, profile: widget.summary),
      ),
      error: (failure) => showAppSnackBar(context, failure.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = widget.summary;
    final relationship = ref.watch(relationshipProvider(summary.id));

    return GradientScaffold(
      appBar: AppBar(title: Text(summary.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: StaggeredColumn(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: ProfileAvatar(
                    name: summary.name,
                    photoUrl: summary.photoUrl,
                    radius: 52,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  summary.name,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                if (summary.biography?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        summary.biography!,
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                relationship.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  ),
                  error: (_, _) => FilledButton.icon(
                    onPressed: _busy ? null : _connect,
                    icon: const Icon(Icons.favorite_outline),
                    label: Text(
                        _busy ? 'Enviando…' : 'Enviar solicitud de conexión'),
                  ),
                  data: (r) => switch (r.status) {
                    RelationshipStatus.friend => FilledButton.icon(
                        onPressed: _busy ? null : _message,
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: Text(_busy ? 'Abriendo…' : 'Enviar mensaje'),
                      ),
                    RelationshipStatus.pendingSent => OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.hourglass_top_outlined),
                        label: const Text('Solicitud enviada'),
                      ),
                    RelationshipStatus.pendingReceived => FilledButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.mark_email_unread_outlined),
                        label: const Text('Te envió una solicitud · ir a Matches'),
                      ),
                    RelationshipStatus.none => FilledButton.icon(
                        onPressed: _busy ? null : _connect,
                        icon: const Icon(Icons.favorite_outline),
                        label: Text(_busy
                            ? 'Enviando…'
                            : 'Enviar solicitud de conexión'),
                      ),
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  // TODO(backend): traer intereses públicos y compatibilidad
                  // cuando el perfil consultado lo permita (privacyLevel).
                  'Los intereses y datos completos se muestran según la '
                  'privacidad del perfil.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
