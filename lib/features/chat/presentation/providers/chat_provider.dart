import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/mock_chat_repository.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (Env.demoMode) {
    final mock = MockChatRepository();
    ref.onDispose(mock.disconnect);
    return mock;
  }
  final session = ref.watch(authControllerProvider).session;
  final repo = ChatRepositoryImpl(
    dio: ref.watch(apiClientProvider(Env.chatUrl)),
    userId: session?.userId ?? '',
  );
  ref.onDispose(repo.disconnect);
  return repo;
});

/// Conexión + nombre/foto de la otra persona.
class ChatConversation {
  const ChatConversation({required this.connection, required this.profile});

  final ChatConnection connection;
  final ProfileSummary profile;
}

final conversationsProvider =
    FutureProvider<List<ChatConversation>>((ref) async {
  final result = await ref.watch(chatRepositoryProvider).getConnections();
  return result.when(
    error: (failure) => throw failure,
    success: (connections) async {
      if (connections.isEmpty) return const <ChatConversation>[];
      final profiles = await ref
          .read(profileRepositoryProvider)
          .getProfilesByIds([for (final c in connections) c.otherUserId]);
      final byId = {
        for (final p in profiles.dataOrNull ?? const <ProfileSummary>[])
          p.id: p,
      };
      return [
        for (final c in connections)
          ChatConversation(
            connection: c,
            profile: byId[c.otherUserId] ??
                ProfileSummary(id: c.otherUserId, name: 'Estudiante ECI'),
          ),
      ];
    },
  );
});

/// Mensajes de una sala: historial + tiempo real.
class ChatRoomController
    extends FamilyAsyncNotifier<List<ChatMessage>, String> {
  StreamSubscription<ChatMessage>? _subscription;

  @override
  Future<List<ChatMessage>> build(String chatRoomId) async {
    final repo = ref.watch(chatRepositoryProvider);

    _subscription?.cancel();
    _subscription = repo.subscribe(chatRoomId).listen((message) {
      final current = state.valueOrNull ?? const <ChatMessage>[];
      // Evita duplicados (el propio mensaje puede volver por el topic).
      if (current.any((m) => m.id == message.id)) return;
      state = AsyncData([...current, message]);
    });
    ref.onDispose(() => _subscription?.cancel());

    final result = await repo.getHistory(chatRoomId);
    return result.when(
      success: (messages) {
        final sorted = List.of(messages)
          ..sort((a, b) => (a.sentAt ?? DateTime(0))
              .compareTo(b.sentAt ?? DateTime(0)));
        return sorted;
      },
      error: (failure) => throw failure,
    );
  }

  Future<Result<void>> send(String content) {
    return ref.read(chatRepositoryProvider).sendMessage(arg, content);
  }
}

final chatRoomProvider = AsyncNotifierProvider.family<ChatRoomController,
    List<ChatMessage>, String>(ChatRoomController.new);

/// Failure reexportado para pantallas de chat.
typedef ChatFailure = Failure;
