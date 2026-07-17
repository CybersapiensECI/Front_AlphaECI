import '../../../../core/errors/result.dart';
import '../../../events/domain/entities/event.dart';
import '../entities/wellbeing.dart';

/// Contrato contra BienestarService (/bienestar).
abstract interface class WellbeingRepository {
  /// GET /resources?category=.
  Future<Result<List<WellbeingResource>>> getResources({String? category});

  /// GET /contacts.
  Future<Result<List<EmergencyContact>>> getContacts();

  /// GET /events — eventos categoría BIENESTAR (proxy a EventService).
  Future<Result<List<UniversityEvent>>> getWellbeingEvents();
}
