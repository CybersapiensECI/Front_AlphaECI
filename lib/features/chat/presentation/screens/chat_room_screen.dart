import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/auth_layout.dart'
    show showAppSnackBar;
import '../../../parches/domain/entities/parche.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';
import '../../domain/entities/chat.dart';
import '../providers/chat_provider.dart';

/// Sala de chat en tiempo real: burbujas + input, auto-scroll al final.
/// Directo (conversation) o grupal de parche (ChatRoomScreen.group).
class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({super.key, required ChatConversation this.conversation})
      : parche = null;

  const ChatRoomScreen.group({super.key, required Parche this.parche})
      : conversation = null;

  final ChatConversation? conversation;
  final Parche? parche;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _showEmojis = false;

  /// Emojis rápidos del contexto universitario/social.
  static const _quickEmojis = [
    '😀', '😂', '😍', '🔥', '🎉', '👍', '🙌', '💙', '😅', '😎',
    '🤝', '⚽', '🎮', '📚', '🍕', '☕', '🥳', '😢', '😮', '💪',
    '✨', '🤓', '🙏', '🫶',
  ];

  // Confirmado con backend: la sala grupal de un parche usa el propio
  // parche.id como chatRoomId (chat-service la crea así al consumir
  // parche.created, ver CreateParcheRoomUseCaseImpl).
  String get _roomId =>
      widget.conversation?.connection.chatRoomId ?? widget.parche!.id;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    final result =
        await ref.read(chatRoomProvider(_roomId).notifier).send(text);
    if (!mounted) return;
    final failure = result.failureOrNull;
    if (failure != null) showAppSnackBar(context, failure.message);
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatRoomProvider(_roomId));
    final myId = ref.watch(authControllerProvider).session?.userId ?? '';

    // Auto-scroll cuando llegan mensajes.
    ref.listen(chatRoomProvider(_roomId), (_, _) => _scrollToBottom());

    final parche = widget.parche;
    final (categoryIcon, categoryColor) =
        AppCategoryStyles.of(parche?.category);

    return GradientScaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (parche != null)
              // Chat grupal: burbuja con color de categoría del parche.
              CircleAvatar(
                radius: 16,
                backgroundColor: categoryColor,
                child: Icon(categoryIcon, size: 18, color: Colors.white),
              )
            else
              ProfileAvatar(
                name: widget.conversation!.profile.name,
                photoUrl: widget.conversation!.profile.photoUrl,
                radius: 16,
              ),
            const SizedBox(width: 10),
            Flexible(
              child: parche != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(parche.name,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          '${parche.memberCount} integrantes',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    )
                  : Text(
                      widget.conversation!.profile.name,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
          child: Column(
            children: [
              Expanded(
                child: AsyncValueView<List<ChatMessage>>(
                  value: messages,
                  onRetry: () => ref.invalidate(chatRoomProvider(_roomId)),
                  data: (items) {
                    _scrollToBottom();
                    return ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, index) => _MessageBubble(
                        message: items[index],
                        isMine: items[index].senderId == myId,
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: GlassCard(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Barra de emojis rápidos (toggle).
                        AnimatedSize(
                          duration: AppDurations.base,
                          curve: AppCurves.enter,
                          child: !_showEmojis
                              ? const SizedBox(width: double.infinity)
                              : SizedBox(
                                  height: 44,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _quickEmojis.length,
                                    itemBuilder: (context, i) => BouncyTap(
                                      onTap: () {
                                        _input.text += _quickEmojis[i];
                                        _input.selection =
                                            TextSelection.collapsed(
                                          offset: _input.text.length,
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets
                                            .symmetric(horizontal: 6),
                                        child: Center(
                                          child: Text(
                                            _quickEmojis[i],
                                            style: const TextStyle(
                                                fontSize: 24),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Emojis',
                              onPressed: () => setState(
                                  () => _showEmojis = !_showEmojis),
                              icon: Icon(
                                _showEmojis
                                    ? Icons.keyboard_alt_outlined
                                    : Icons.emoji_emotions_outlined,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _input,
                                decoration: const InputDecoration(
                                  hintText: 'Escribe un mensaje…',
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _send(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            BouncyTap(
                              onTap: _send,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppGradients.buttonOf(context),
                                  boxShadow: AppShadows.glow(
                                      Theme.of(context)
                                          .colorScheme
                                          .primary),
                                ),
                                child: const Icon(Icons.send,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// true si el texto son solo emojis (hasta 10) — se renderizan grandes.
bool _isEmojiOnly(String text) {
  final stripped = text.replaceAll(RegExp(r'\s'), '');
  if (stripped.isEmpty || stripped.runes.length > 10) return false;
  // Sin caracteres alfanuméricos ni puntuación ASCII: lo tratamos como emoji.
  return !RegExp(r'[\x20-\x7E]').hasMatch(stripped);
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time = message.sentAt != null
        ? DateFormat('HH:mm').format(message.sentAt!)
        : '';

    // Mensajes de solo emojis: grandes y sin burbuja (estilo social).
    final emojiOnly = _isEmojiOnly(message.content);

    return FadeSlideIn(
      offset: Offset(isMine ? 0.1 : -0.1, 0),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: emojiOnly
              ? null
              : BoxDecoration(
            gradient: isMine ? AppGradients.buttonOf(context) : null,
            color: isMine ? null : scheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.content,
                style: TextStyle(
                  color: isMine ? Colors.white : scheme.onSurface,
                  fontSize: emojiOnly ? 34 : 15,
                ),
              ),
              if (time.isNotEmpty)
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: !emojiOnly && isMine
                        ? Colors.white.withValues(alpha: 0.7)
                        : scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
