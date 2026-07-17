import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/stats_repository.dart';
import '../../domain/entities/personal_stats.dart';
import '../widgets/activity_card.dart';
import '../widgets/collection_section.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/profile_card.dart';
import '../widgets/progress_card.dart';
import '../widgets/stats_grid.dart';
import '../widgets/stats_palette.dart';

// ── Providers: lógica intacta, sin cambios ──────────────────────────
final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  if (Env.demoMode) return const MockStatsRepository();
  return StatsRepositoryImpl(ref.watch(apiClientProvider(Env.statsUrl)));
});

final personalStatsProvider = FutureProvider<PersonalStats>((ref) async {
  final session = ref.watch(authControllerProvider).session;
  if (session == null) throw const AuthFailure();
  final result = await ref
      .watch(statsRepositoryProvider)
      .getPersonalStats(session.userId);
  return result.when(
    success: (stats) => stats,
    error: (failure) => throw failure,
  );
});

/// Dashboard personal: todo lo importante (XP, nivel, progreso, actividad
/// y colección) visible casi de un vistazo, sin gráficas gigantes.
/// Orquestador delgado — cada sección vive en su propio widget bajo
/// `widgets/`.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(personalStatsProvider);

    return Scaffold(
      backgroundColor: StatsPalette.background,
      appBar: const DashboardHeader(),
      body: AsyncValueView<PersonalStats>(
        value: stats,
        onRetry: () => ref.invalidate(personalStatsProvider),
        data: (data) => RefreshIndicator(
          color: StatsPalette.primaryBlue,
          backgroundColor: StatsPalette.surface,
          onRefresh: () async => ref.invalidate(personalStatsProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Breakpoints.contentMaxWidth,
                ),
                child: StaggeredColumn(
                  children: [
                    ProfileCard(data: data),
                    const SizedBox(height: 16),
                    ProgressCard(data: data),
                    const SizedBox(height: 16),
                    StatsGrid(data: data),
                    const SizedBox(height: 16),
                    const ActivityCard(),
                    const SizedBox(height: 16),
                    const CollectionSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
