// TODO(demo): datos falsos de bienestar. Eliminar en prod.
import '../../../../core/errors/result.dart';
import '../../../events/domain/entities/event.dart';
import '../../domain/entities/wellbeing.dart';
import '../../domain/repositories/wellbeing_repository.dart';

class MockWellbeingRepository implements WellbeingRepository {
  const MockWellbeingRepository();

  Future<Result<T>> _ok<T>(T value) =>
      Future.delayed(const Duration(milliseconds: 400), () => Success(value));

  @override
  Future<Result<List<WellbeingResource>>> getResources({String? category}) {
    const resources = [
      WellbeingResource(
        id: 'r1',
        title: 'Técnica Pomodoro para parciales',
        description: '25 min de foco + 5 de descanso. Tu cerebro lo agradece.',
        type: 'TIP',
        category: 'ACADÉMICO',
      ),
      WellbeingResource(
        id: 'r2',
        title: 'Cómo manejar la ansiedad en semana de parciales',
        description: 'Artículo de Bienestar Universitario con ejercicios.',
        type: 'ARTICLE',
        category: 'PSICOLOGÍA',
      ),
      WellbeingResource(
        id: 'r3',
        title: 'Consulta psicológica gratuita',
        description: 'Agenda tu cita en Bienestar, edificio D, oficina 201.',
        type: 'CONTACT',
        category: 'PSICOLOGÍA',
      ),
      WellbeingResource(
        id: 'r4',
        title: 'Guía de alimentación en época de estrés',
        description: 'Recomendaciones del área de nutrición.',
        type: 'ARTICLE',
        category: 'NUTRICIÓN',
      ),
    ];
    return _ok([
      for (final r in resources)
        if (category == null || r.category == category) r,
    ]);
  }

  @override
  Future<Result<List<EmergencyContact>>> getContacts() => _ok(const [
        EmergencyContact(
          id: 'ec1',
          name: 'Bienestar Universitario ECI',
          phone: '601 668 3600',
          email: 'bienestar@escuelaing.edu.co',
        ),
        EmergencyContact(
          id: 'ec2',
          name: 'Línea de emergencia psicológica',
          phone: '106',
        ),
        EmergencyContact(
          id: 'ec3',
          name: 'Enfermería campus',
          phone: 'Ext. 218',
        ),
      ]);

  @override
  Future<Result<List<UniversityEvent>>> getWellbeingEvents() => _ok(const [
        UniversityEvent(
          id: 'e2',
          name: 'Taller de Liderazgo Estudiantil',
          description: 'Habilidades blandas para representantes.',
          category: 'BIENESTAR',
          date: '2026-07-18',
          availableCapacity: 5,
          status: 'ACTIVE',
        ),
      ]);
}
