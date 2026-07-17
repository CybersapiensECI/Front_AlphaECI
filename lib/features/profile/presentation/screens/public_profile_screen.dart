import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/auth_layout.dart'
    show showAppSnackBar;
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
  bool _sending = false;

  Future<void> _connect() async {
    final session = ref.read(authControllerProvider).session;
    if (session == null) return;
    setState(() => _sending = true);
    final result = await ref.read(matchingRepositoryProvider).createMatch(
          requesterId: session.userId,
          targetId: widget.summary.id,
        );
    if (!mounted) return;
    setState(() => _sending = false);
    result.when(
      success: (_) => showAppSnackBar(
          context, 'Solicitud enviada a ${widget.summary.name} 🚀'),
      error: (failure) => showAppSnackBar(context, failure.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = widget.summary;

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
                FilledButton.icon(
                  onPressed: _sending ? null : _connect,
                  icon: const Icon(Icons.favorite_outline),
                  label: Text(
                      _sending ? 'Enviando…' : 'Enviar solicitud de conexión'),
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
