import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/mascot.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/post_composer_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/auth_layout.dart'
    show showAppSnackBar;
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/parche.dart';
import '../providers/parche_provider.dart';

/// Detalle de parche: info, unirse, miembros y muro de posts.
class ParcheDetailScreen extends ConsumerStatefulWidget {
  const ParcheDetailScreen({super.key, required this.parche});

  final Parche parche;

  @override
  ConsumerState<ParcheDetailScreen> createState() =>
      _ParcheDetailScreenState();
}

class _ParcheDetailScreenState extends ConsumerState<ParcheDetailScreen> {
  bool _joining = false;

  Future<void> _join() async {
    setState(() => _joining = true);
    final result =
        await ref.read(parcheActionsProvider).join(widget.parche.id);
    if (!mounted) return;
    setState(() => _joining = false);
    result.when(
      success: (message) => showMascotSnackBar(context, '$message 🎉', AppAssets.stickerApproved),
      error: (failure) => showAppSnackBar(context, failure.message),
    );
  }

  Future<void> _react(String postId) async {
    final result =
        await ref.read(parcheActionsProvider).react(widget.parche.id, postId);
    if (!mounted) return;
    final failure = result.failureOrNull;
    if (failure != null) showAppSnackBar(context, failure.message);
  }

  /// Comentarios estilo Instagram: lista + campo para comentar.
  void _comment(String postId) => showCommentsSheet(
        context,
        parcheId: widget.parche.id,
        postId: postId,
      );

  Future<void> _publish() async {
    final draft = await showPostComposerSheet(
      context,
      title: 'Publicar en ${widget.parche.name}',
    );
    if (draft == null || !mounted) return;
    final result = await ref.read(parcheActionsProvider).createPost(
          widget.parche.id,
          draft.text,
          photoUrl: draft.photoUrl,
        );
    if (!mounted) return;
    result.when(
      success: (_) => showMascotSnackBar(
          context, '¡Publicado en el muro! 🎉', AppAssets.stickerOk),
      error: (failure) => showAppSnackBar(context, failure.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parche = widget.parche;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final session = ref.watch(authControllerProvider).session;
    final members = ref.watch(parcheMembersProvider(parche.id));
    final posts = ref.watch(parchePostsProvider(parche.id));

    final memberList = members.valueOrNull ?? parche.members;
    final isMember =
        session != null && memberList.any((m) => m.studentId == session.userId);
    final isFull = memberList.length >= parche.maximumQuota;

    return GradientScaffold(
      appBar: AppBar(title: Text(parche.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: StaggeredColumn(
              children: [
                // ── Info ──────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (parche.description?.isNotEmpty == true) ...[
                          Text(parche.description!,
                              style: theme.textTheme.bodyLarge),
                          const SizedBox(height: 12),
                        ],
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            if (parche.date != null)
                              _InfoItem(
                                icon: Icons.calendar_today_outlined,
                                text: DateFormat('d MMM yyyy')
                                    .format(parche.date!),
                              ),
                            if (parche.hour != null)
                              _InfoItem(
                                  icon: Icons.schedule_outlined,
                                  text: parche.hour!),
                            if (parche.place != null)
                              _InfoItem(
                                  icon: Icons.place_outlined,
                                  text: parche.place!),
                            if (parche.category != null)
                              _InfoItem(
                                  icon: Icons.tag_outlined,
                                  text: parche.category!),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (!isMember)
                          AppButton(
                            label: isFull ? 'Parche lleno' : 'Unirme al parche',
                            loading: _joining,
                            icon: Icons.group_add_outlined,
                            onPressed: isFull ? null : _join,
                          )
                        else
                          Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green.shade600),
                              const SizedBox(width: 8),
                              Text('Eres parte de este parche',
                                  style: theme.textTheme.titleMedium),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // ── Miembros ──────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Miembros (${memberList.length}/${parche.maximumQuota})',
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            if (isMember)
                              TextButton.icon(
                                icon: const Icon(Icons.person_add_outlined,
                                    size: 18),
                                label: const Text('Invitar'),
                                onPressed: () => showDialog<void>(
                                  context: context,
                                  builder: (_) => _InviteDialog(
                                      parcheId: widget.parche.id),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final member in memberList)
                              Chip(
                                avatar: Icon(
                                  member.role == 'CREATOR'
                                      ? Icons.star
                                      : Icons.person_outline,
                                  size: 18,
                                  color: member.role == 'CREATOR'
                                      ? Colors.amber
                                      : scheme.primary,
                                ),
                                // TODO(profile): resolver nombre vía batch
                                // de profile-service.
                                label: Text(
                                  member.role == 'CREATOR'
                                      ? 'Capitán'
                                      : 'Estudiante',
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // ── Muro ──────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Muro del parche',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 12),
                        if (isMember)
                          // Composer: texto + foto (abre sheet completo).
                          BouncyTap(
                            onTap: _publish,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: scheme.tertiary
                                    .withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: scheme.outline
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined,
                                      size: 18, color: scheme.primary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '¿Qué está pasando? Texto o foto…',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 20,
                                    color: scheme.tertiary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        posts.when(
                          loading: () => const Center(
                              child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(),
                          )),
                          error: (e, _) => Text(
                            'No se pudo cargar el muro.',
                            style: theme.textTheme.bodySmall,
                          ),
                          data: (items) {
                            if (items.isEmpty) {
                              return Text(
                                'Sin publicaciones todavía.',
                                style: theme.textTheme.bodySmall,
                              );
                            }
                            return Column(
                              children: [
                                for (final post in items)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: scheme.tertiary
                                          .withValues(alpha: 0.2),
                                      child: Icon(Icons.person_outline,
                                          color: scheme.primary),
                                    ),
                                    title: Text(post.text ?? ''),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Foto adjunta de la publicación.
                                        if (post.photoUrl?.isNotEmpty ==
                                            true)
                                          Padding(
                                            padding: const EdgeInsets
                                                .only(top: 6, bottom: 4),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      10),
                                              child: Image.network(
                                                post.photoUrl!,
                                                height: 140,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (_, _, _) =>
                                                        const SizedBox
                                                            .shrink(),
                                              ),
                                            ),
                                          ),
                                        if (post.createdAt != null)
                                          Text(DateFormat('d MMM · HH:mm')
                                              .format(post.createdAt!)),
                                      ],
                                    ),
                                    trailing: isMember
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: 'Me gusta',
                                                icon: const Icon(
                                                    Icons.favorite_border,
                                                    size: 20),
                                                onPressed: () =>
                                                    _react(post.id),
                                              ),
                                              IconButton(
                                                tooltip: 'Comentar',
                                                icon: const Icon(
                                                    Icons
                                                        .mode_comment_outlined,
                                                    size: 20),
                                                onPressed: () =>
                                                    _comment(post.id),
                                              ),
                                            ],
                                          )
                                        : null,
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog para invitar amigos al parche (RFB12).
/// Lista los friendsId del perfil propio resueltos vía batch.
class _InviteDialog extends ConsumerWidget {
  const _InviteDialog({required this.parcheId});

  final String parcheId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);

    return AlertDialog(
      title: const Text('Invitar a un amigo'),
      content: SizedBox(
        width: 360,
        child: profile.when(
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => const Text('No se pudo cargar tu perfil.'),
          data: (me) {
            if (me.friendsId.isEmpty) {
              return const Text(
                  'Aún no tienes conexiones para invitar. '
                  '¡Conecta con gente en Descubrir!');
            }
            return _FriendList(parcheId: parcheId, friendIds: me.friendsId);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class _FriendList extends ConsumerWidget {
  const _FriendList({required this.parcheId, required this.friendIds});

  final String parcheId;
  final List<String> friendIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(profileRepositoryProvider).getProfilesByIds(friendIds),
      builder: (context, snapshot) {
        final profiles =
            snapshot.data?.dataOrNull ?? const <ProfileSummary>[];
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (profiles.isEmpty) {
          return const Text('No se pudieron cargar tus conexiones.');
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final friend in profiles)
              ListTile(
                dense: true,
                title: Text(friend.name),
                trailing: IconButton(
                  tooltip: 'Enviar invitación',
                  icon: const Icon(Icons.send_outlined, size: 20),
                  onPressed: () async {
                    final result = await ref
                        .read(parcheActionsProvider)
                        .invite(parcheId, friend.id);
                    if (!context.mounted) return;
                    result.when(
                      success: (m) => showMascotSnackBar(context, m, AppAssets.stickerHey),
                      error: (f) => showAppSnackBar(context, f.message),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
