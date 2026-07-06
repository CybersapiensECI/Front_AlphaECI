import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/gamification_repository_impl.dart';
import '../../data/repositories/mock_gamification_repository.dart';
import '../../domain/entities/mona.dart';
import '../../domain/repositories/gamification_repository.dart';

final gamificationRepositoryProvider =
    Provider<GamificationRepository>((ref) {
  if (Env.demoMode) return const MockGamificationRepository();
  return GamificationRepositoryImpl(
      ref.watch(apiClientProvider(Env.gamificationUrl)));
});

final myMonasProvider = FutureProvider<UserMonas>((ref) async {
  final session = ref.watch(authControllerProvider).session;
  if (session == null) throw const AuthFailure();
  final result = await ref
      .watch(gamificationRepositoryProvider)
      .getUserMonas(session.userId);
  return result.when(
    success: (monas) => monas,
    error: (failure) => throw failure,
  );
});
