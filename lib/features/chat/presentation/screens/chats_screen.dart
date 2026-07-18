import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/mascot.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../parches/domain/entities/parche.dart';
import '../../../parches/presentation/providers/parche_provider.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';
import '../providers/chat_provider.dart';

enum ChatFilter { todos, directos, grupos }

final chatFilterProvider = StateProvider<ChatFilter>((ref) => ChatFilter.todos);

/// Chats: directos (matches) y grupales (un chat por parche al que
/// perteneces), como una app de mensajería moderna.
class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(chatFilterProvider);
    final conversationsAsync = ref.watch(conversationsProvider);
    final parchesAsync = ref.watch(parcheFeedProvider);
    final userId = ref.watch(authControllerProvider).session?.userId ?? '';

    final isLoading = conversationsAsync.isLoading || parchesAsync.isLoading;
    
    final myParches = parchesAsync.valueOrNull
            ?.where((p) => p.isMember(userId))
            .toList() ??
        [];
    final myDirects = conversationsAsync.valueOrNull ?? [];

    List<dynamic> items = [];
    if (filter == ChatFilter.todos) {
      items = [...myDirects, ...myParches];
    } else if (filter == ChatFilter.directos) {
      items = [...myDirects];
    } else if (filter == ChatFilter.grupos) {
      items = [...myParches];
    }

    return GradientScaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: Column(
        children: [
          // Filtros rápidos
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todos',
                  selected: filter == ChatFilter.todos,
                  onSelected: () => ref.read(chatFilterProvider.notifier).state = ChatFilter.todos,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Directos',
                  selected: filter == ChatFilter.directos,
                  onSelected: () => ref.read(chatFilterProvider.notifier).state = ChatFilter.directos,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Grupos',
                  selected: filter == ChatFilter.grupos,
                  onSelected: () => ref.read(chatFilterProvider.notifier).state = ChatFilter.grupos,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Lista unificada
          Expanded(
            child: isLoading
                ? const SkeletonList(count: 6)
                : items.isEmpty
                    ? const MascotEmptyState(
                        asset: AppAssets.stickerConfused,
                        message: 'No hay chats para mostrar aquí.',
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(conversationsProvider);
                          ref.invalidate(parcheFeedProvider);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return FadeSlideIn(
                              delay: Duration(milliseconds: 30 * index),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                      maxWidth: Breakpoints.contentMaxWidth),
                                  child: item is ChatConversation
                                      ? _DirectChatTile(conversation: item)
                                      : _GroupChatTile(parche: item as Parche),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onSelected});

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        color: selected ? theme.colorScheme.onPrimaryContainer : null,
      ),
    );
  }
}

class _DirectChatTile extends StatelessWidget {
  const _DirectChatTile({required this.conversation});

  final ChatConversation conversation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: ProfileAvatar(
        name: conversation.profile.name,
        photoUrl: conversation.profile.photoUrl,
        radius: 26,
      ),
      title: Text(
        conversation.profile.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        conversation.connection.lastMessageContent ?? 'Toca para chatear',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: conversation.connection.lastMessageAt == null
          ? null
          : Text(
              _timeAgo(conversation.connection.lastMessageAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      onTap: () => context.push(
        Routes.chatRoomPath(conversation.connection.chatRoomId),
        extra: conversation,
      ),
    );
  }
}

class _GroupChatTile extends StatelessWidget {
  const _GroupChatTile({required this.parche});

  final Parche parche;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = AppCategoryStyles.of(parche.category);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: color,
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      title: Text(
        parche.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        '${parche.memberCount} integrantes',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: () => context.push(
        Routes.chatRoomPath(parche.id),
        extra: parche,
      ),
    );
  }
}

String _timeAgo(DateTime? date) {
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inHours < 1) return '${diff.inMinutes} min';
  if (diff.inDays < 1) return '${diff.inHours} h';
  if (diff.inDays < 7) return '${diff.inDays} d';
  return '${(diff.inDays / 7).floor()} sem';
}
