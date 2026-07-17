import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_client.dart';
import '../../../events/domain/entities/event.dart';
import '../../data/repositories/mock_wellbeing_repository.dart';
import '../../data/repositories/wellbeing_repository_impl.dart';
import '../../domain/entities/wellbeing.dart';
import '../../domain/repositories/wellbeing_repository.dart';

final wellbeingRepositoryProvider = Provider<WellbeingRepository>((ref) {
  if (Env.demoMode) return const MockWellbeingRepository();
  return WellbeingRepositoryImpl(
      ref.watch(apiClientProvider(Env.bienestarUrl)));
});

final wellbeingCategoryProvider = StateProvider<String?>((_) => null);

/// Categorías DERIVADAS de los recursos reales. BienestarService no
/// define enum de categorías (String libre): los chips salen de los
/// datos, no de una lista inventada en el front.
final wellbeingCategoriesProvider =
    FutureProvider<List<String>>((ref) async {
  final result = await ref.watch(wellbeingRepositoryProvider).getResources();
  return result.when(
    success: (resources) {
      final unique = <String>{
        for (final resource in resources)
          if (resource.category?.trim().isNotEmpty == true)
            resource.category!.trim(),
      };
      return unique.toList()..sort();
    },
    error: (failure) => throw failure,
  );
});

final wellbeingResourcesProvider =
    FutureProvider<List<WellbeingResource>>((ref) async {
  final category = ref.watch(wellbeingCategoryProvider);
  final result = await ref
      .watch(wellbeingRepositoryProvider)
      .getResources(category: category);
  return result.when(
      success: (resources) => resources,
      error: (failure) => throw failure);
});

final emergencyContactsProvider =
    FutureProvider<List<EmergencyContact>>((ref) async {
  final result = await ref.watch(wellbeingRepositoryProvider).getContacts();
  return result.when(
      success: (contacts) => contacts, error: (failure) => throw failure);
});

final wellbeingEventsProvider =
    FutureProvider<List<UniversityEvent>>((ref) async {
  final result =
      await ref.watch(wellbeingRepositoryProvider).getWellbeingEvents();
  return result.when(
      success: (events) => events, error: (failure) => throw failure);
});
