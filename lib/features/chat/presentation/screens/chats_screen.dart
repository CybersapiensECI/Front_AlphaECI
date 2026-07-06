import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/mascot.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../parches/domain/entities/parche.dart';
import '../../../parches/presentation/providers/parche_provider.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';
import '../providers/chat_provider.dart';

/// Chats: directos (matches) y grupales (un chat por parche al que
/// perteneces), como cualquier app de mensajería.
class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Directos'),
                Tab(text: 'Parches'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _DirectsTab(),
                  _ParcheChatsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);
    return AsyncValueView<List<ChatConversation>>(
      value: conversations,
      onRetry: () => ref.invalidate(conversationsProvider),
      loading: const SkeletonList(count: 5),
      data: (items) {
        if (items.isEmpty) {
          return const MascotEmptyState(
            asset: AppAssets.stickerConfused,
            message: 'Nada por aquí todavía.\nConecta con alguien en '
                'Descubrir para empezar a chatear.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final conversation = items[index];
            return FadeSlideIn(
              delay: Duration(milliseconds: 50 * index),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                      maxWidth: Breakpoints.contentMaxWidth),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: ProfileAvatar(
                        name: conversation.profile.name,
                        photoUrl: conversation.profile.photoUrl,
                        radius: 24,
                      ),
                      title: Text(conversation.profile.name),
                      subtitle: Text(
                        conversation.profile.biography ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(
                        Routes.chatRoomPath(
                            conversation.connection.chatRoomId),
                        extra: conversation,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Chats grupales: parches donde soy miembro.
class _ParcheChatsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(parcheFeedProvider);
    final userId = ref.watch(authControllerProvider).session?.userId ?? '';

    return AsyncValueView<List<Parche>>(
      value: feed,
      onRetry: () => ref.invalidate(parcheFeedProvider),
      loading: const SkeletonList(count: 4),
      data: (parches) {
        final mine = [
          for (final p in parches)
            if (p.isMember(userId)) p,
        ];
        if (mine.isEmpty) {
          return const MascotEmptyState(
            asset: AppAssets.stickerSleepy,
            message: 'Sin chats grupales.\nÚnete a un parche y su chat '
                'aparecerá aquí.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: mine.length,
          itemBuilder: (context, index) {
            final parche = mine[index];
            final (icon, color) = AppCategoryStyles.of(parche.category);
            return FadeSlideIn(
              delay: Duration(milliseconds: 50 * index),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                      maxWidth: Breakpoints.contentMaxWidth),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: color,
                        child:
                            Icon(icon, color: Colors.white, size: 24),
                      ),
                      title: Text(parche.name),
                      subtitle: Text(
                        '${parche.memberCount} integrantes',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(
                        Routes.chatRoomPath(parche.id),
                        extra: parche,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
