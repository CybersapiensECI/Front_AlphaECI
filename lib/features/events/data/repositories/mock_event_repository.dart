// TODO(demo): datos falsos para ver la app sin backends. Eliminar en prod.
import '../../../../core/errors/result.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';

class MockEventRepository implements EventRepository {
  MockEventRepository();

  final List<UniversityEvent> _events = [
    const UniversityEvent(
      id: 'e1',
      name: 'Conferencia de Innovación',
      description: 'Charlas de egresados fundadores de startups.',
      category: 'TECH',
      date: '2026-07-15',
      capacity: 120,
      availableCapacity: 37,
      status: 'ACTIVE',
    ),
    const UniversityEvent(
      id: 'e2',
      name: 'Taller de Liderazgo Estudiantil',
      description: 'Habilidades blandas para representantes.',
      category: 'BIENESTAR',
      date: '2026-07-18',
      capacity: 40,
      availableCapacity: 5,
      status: 'ACTIVE',
    ),
    const UniversityEvent(
      id: 'e3',
      name: 'Torneo de Robótica',
      description: 'Competencia interfacultades. ¡Inscribe tu equipo!',
      category: 'TECH',
      date: '2026-07-23',
      capacity: 60,
      availableCapacity: 0,
      status: 'ACTIVE',
    ),
    const UniversityEvent(
      id: 'e4',
      name: 'Feria de Emprendimiento',
      description: 'Stands de proyectos estudiantiles.',
      category: 'CULTURA',
      date: '2026-07-29',
      capacity: 300,
      availableCapacity: 210,
      status: 'ACTIVE',
    ),
  ];

  final Set<String> _agenda = {'e2'};

  Future<Result<T>> _ok<T>(T value) =>
      Future.delayed(const Duration(milliseconds: 400), () => Success(value));

  @override
  Future<Result<List<UniversityEvent>>> getEvents({String? category}) {
    return _ok([
      for (final e in _events)
        if (category == null || e.category == category) e,
    ]);
  }

  @override
  Future<Result<String>> confirmRsvp(String eventId, String userId) {
    _agenda.add(eventId);
    return _ok('CONFIRMED');
  }

  @override
  Future<Result<String>> cancelRsvp(String eventId, String userId) {
    _agenda.remove(eventId);
    return _ok('CANCELLED');
  }

  @override
  Future<Result<List<String>>> getAgenda(String userId) =>
      _ok(_agenda.toList());
}
