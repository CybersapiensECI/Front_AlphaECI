// TODO(demo): monas falsas para ver la app sin backends. Eliminar en prod.
import '../../../../core/errors/result.dart';
import '../../domain/entities/mona.dart';
import '../../domain/repositories/gamification_repository.dart';

class MockGamificationRepository implements GamificationRepository {
  const MockGamificationRepository();

  @override
  Future<Result<UserMonas>> getUserMonas(String userId) {
    return Future.delayed(
      const Duration(milliseconds: 450),
      () => const Success(
        UserMonas(
          totalXp: 340,
          totalUnlocked: 3,
          unlocked: [
            Mona(
              code: 'FIRST_CONNECTION',
              name: 'Rompehielos',
              description: 'Hiciste tu primera conexión.',
              rarity: 'COMMON',
              xpGranted: 50,
            ),
            Mona(
              code: 'FIRST_PARCHE',
              name: 'Parchero',
              description: 'Te uniste a tu primer parche.',
              rarity: 'COMMON',
              xpGranted: 50,
            ),
            Mona(
              code: 'EVENT_GOER',
              name: 'Presente',
              description: 'Confirmaste asistencia a un evento.',
              rarity: 'RARE',
              xpGranted: 100,
            ),
          ],
          inProgress: [
            Mona(
              code: 'SOCIAL_BUTTERFLY',
              name: 'Mariposa social',
              description: 'Conecta con 10 estudiantes.',
              rarity: 'EPIC',
              xpGranted: 250,
              progressPercentage: 40,
              currentCount: 4,
              requiredCount: 10,
            ),
            Mona(
              code: 'EXPLORER',
              name: 'Exploradora ECI',
              description: 'Visita 5 zonas del campus.',
              rarity: 'RARE',
              xpGranted: 150,
              progressPercentage: 60,
              currentCount: 3,
              requiredCount: 5,
            ),
          ],
          locked: [
            Mona(
              code: 'CAPTAIN',
              name: 'Capitán de parche',
              description: 'Crea un parche y llénalo.',
              rarity: 'EPIC',
              xpGranted: 300,
            ),
            Mona(
              code: 'LEGEND',
              name: 'Leyenda del campus',
              description: 'Desbloquea todas las demás monas.',
              rarity: 'LEGENDARY',
              xpGranted: 500,
            ),
          ],
        ),
      ),
    );
  }
}
