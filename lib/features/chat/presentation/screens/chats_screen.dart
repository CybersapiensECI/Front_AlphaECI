import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';
import '../providers/chat_provider.dart';

/// Lista de conversaciones (conexiones de chat aceptadas).
class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);

    return GradientScaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: AsyncValueView<List<ChatConversation>>(
        value: conversations,
        onRetry: () => ref.invalidate(conversationsProvider),
        loading: const SkeletonList(count: 5),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.chat_bubble_outline,
              message:
                  'Sin conversaciones.\nConecta con alguien en Descubrir '
                  'para empezar a chatear.',
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
      ),
    );
  }
}
