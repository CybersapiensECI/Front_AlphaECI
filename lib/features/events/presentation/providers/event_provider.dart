import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../data/services/event_api_service.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';

final eventApiServiceProvider = Provider<EventApiService>((ref) {
  return EventApiService(ref.watch(apiClientProvider(Env.eventUrl)));
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepositoryImpl(api: ref.watch(eventApiServiceProvider));
});

/// Filtro de categoría (null = todas).
final eventCategoryProvider = StateProvider<String?>((_) => null);

final eventsProvider = FutureProvider<List<UniversityEvent>>((ref) async {
  final category = ref.watch(eventCategoryProvider);
  final result =
      await ref.watch(eventRepositoryProvider).getEvents(category: category);
  return result.when(
    success: (events) => events,
    error: (failure) => throw failure,
  );
});

/// IDs de eventos con RSVP confirmado del usuario actual.
final myAgendaProvider = FutureProvider<Set<String>>((ref) async {
  final session = ref.watch(authControllerProvider).session;
  if (session == null) throw const AuthFailure();
  final result =
      await ref.watch(eventRepositoryProvider).getAgenda(session.userId);
  return result.when(
    success: (ids) => ids.toSet(),
    error: (failure) => throw failure,
  );
});

final eventActionsProvider =
    Provider<EventActions>((ref) => EventActions(ref));

class EventActions {
  const EventActions(this._ref);

  final Ref _ref;

  Future<Result<String>> toggleRsvp(
    UniversityEvent event, {
    required bool confirmed,
  }) async {
    final session = _ref.read(authControllerProvider).session;
    if (session == null) return const Error(AuthFailure());
    final repo = _ref.read(eventRepositoryProvider);
    final result = confirmed
        ? await repo.cancelRsvp(event.id, session.userId)
        : await repo.confirmRsvp(event.id, session.userId);
    if (result.isSuccess) {
      _ref.invalidate(myAgendaProvider);
      _ref.invalidate(eventsProvider);
    }
    return result;
  }
}
