// TODO(demo): monas falsas para ver la app sin backends. Eliminar en prod.
// Catálogo alineado con LISTA_MONAS.md (35 monas, 6 categorías).
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
          totalXp: 1000,
          totalUnlocked: 9,
          unlocked: [
            Mona(
              code: 'PRIMER_CONTACTO',
              name: 'Primer Contacto',
              description:
                  'Da el primer paso y forja tu primera conexión en la '
                  'plataforma. El comienzo de tu red de contactos.',
              category: 'NETWORKING',
              rarity: 'COMUN',
              xpGranted: 50,
            ),
            Mona(
              code: 'NETWORKING_5',
              name: 'Networking 5',
              description:
                  'Conecta con 5 personas y empieza a tejer tu '
                  'red profesional en el campus.',
              category: 'NETWORKING',
              rarity: 'POCO_COMUN',
              xpGranted: 150,
            ),
            Mona(
              code: 'INICIADOR_PARCHE',
              name: 'Iniciador de Parche',
              description:
                  'Únete a tu primer parche y descubre el poder '
                  'de colaborar en equipo.',
              category: 'NETWORKING',
              rarity: 'COMUN',
              xpGranted: 75,
            ),
            Mona(
              code: 'PRIMER_MENSAJERO',
              name: 'Primer Mensajero',
              description:
                  'Envía tu primer mensaje en un parche. La '
                  'comunicación es la llave del éxito.',
              category: 'NETWORKING',
              rarity: 'COMUN',
              xpGranted: 100,
            ),
            Mona(
              code: 'ANFITRION',
              name: 'Anfitrión',
              description:
                  'Da la bienvenida a un nuevo miembro en tu '
                  'parche. Tu comunidad crece gracias a ti.',
              category: 'NETWORKING',
              rarity: 'COMUN',
              xpGranted: 75,
            ),
            Mona(
              code: 'FAN_REGIO',
              name: 'Fan del Regio',
              description:
                  'Registra 5 visitas en la Cafetería Regio. Tu '
                  'lealtad tiene recompensa.',
              category: 'CAFETERIAS',
              rarity: 'COMUN',
              xpGranted: 100,
            ),
            Mona(
              code: 'EDIFICIO_A',
              name: 'Edificio A',
              description:
                  'Marca tu presencia en el Edificio A. Cada '
                  'rincón del campus importa.',
              category: 'EDIFICIOS',
              rarity: 'COMUN',
              xpGranted: 75,
            ),
            Mona(
              code: 'EDIFICIO_B',
              name: 'Edificio B',
              description:
                  'Marca tu presencia en el Edificio B. Un paso '
                  'más en tu travesía por el campus.',
              category: 'EDIFICIOS',
              rarity: 'COMUN',
              xpGranted: 75,
            ),
            Mona(
              code: 'ASISTENTE_VIP',
              name: 'Asistente VIP',
              description:
                  'Escanea un código QR en un evento '
                  'institucional. Tu presencia en los eventos cuenta.',
              category: 'EVENTOS',
              rarity: 'RARO',
              xpGranted: 300,
            ),
          ],
          inProgress: [
            Mona(
              code: 'NETWORKING_10',
              name: 'Networking 10',
              description:
                  'Alcanza las 10 conexiones. Tu círculo crece y '
                  'las oportunidades se multiplican.',
              category: 'NETWORKING',
              rarity: 'RARO',
              xpGranted: 350,
              progressPercentage: 60,
              currentCount: 6,
              requiredCount: 10,
            ),
            Mona(
              code: 'EXPLORADOR_CAFETERIAS',
              name: 'Explorador de Cafeterías',
              description:
                  'Recorre y visita las 4 cafeterías del campus. '
                  'Un viaje culinario que merece reconocimiento.',
              category: 'CAFETERIAS',
              rarity: 'POCO_COMUN',
              xpGranted: 200,
              progressPercentage: 50,
              currentCount: 2,
              requiredCount: 4,
            ),
            Mona(
              code: 'CLIENTE_FRECUENTE',
              name: 'Cliente Frecuente',
              description:
                  'Visita cualquier cafetería 15 veces. El café '
                  'corre por tus venas.',
              category: 'CAFETERIAS',
              rarity: 'POCO_COMUN',
              xpGranted: 250,
              progressPercentage: 60,
              currentCount: 9,
              requiredCount: 15,
            ),
            Mona(
              code: 'MARATON_UNIVERSITARIA',
              name: 'Maratón Universitaria',
              description:
                  'Registra tu paso por 5 zonas distintas del '
                  'campus en un solo día. ¡Todo un récord!',
              category: 'ESTILO_DE_VIDA',
              rarity: 'RARO',
              xpGranted: 400,
              progressPercentage: 60,
              currentCount: 3,
              requiredCount: 5,
            ),
          ],
          locked: [
            Mona(
              code: 'NETWORKING_25',
              name: 'Networking 25',
              description:
                  '25 conexiones activas. Eres un nodo clave '
                  'dentro de la comunidad universitaria.',
              category: 'NETWORKING',
              rarity: 'EPICO',
              xpGranted: 700,
              progressPercentage: 0,
              currentCount: 0,
              requiredCount: 25,
            ),
            Mona(
              code: 'CAPITAN_EQUIPO',
              name: 'Capitán de Equipo',
              description:
                  'Crea 2 parches y demuestra tu liderazgo '
                  'organizando a la comunidad.',
              category: 'NETWORKING',
              rarity: 'POCO_COMUN',
              xpGranted: 200,
              progressPercentage: 0,
              currentCount: 0,
              requiredCount: 2,
            ),
            Mona(
              code: 'ORGANIZADOR_ELITE',
              name: 'Organizador Élite',
              description:
                  'Crea 10 parches y conviértete en un verdadero '
                  'maestro de la organización.',
              category: 'NETWORKING',
              rarity: 'EPICO',
              xpGranted: 500,
              progressPercentage: 0,
              currentCount: 0,
              requiredCount: 10,
            ),
            Mona(
              code: 'CONECTOR_VELOZ',
              name: 'Conector Veloz',
              description:
                  'Conecta con 10 personas en solo 30 días. Tu '
                  'habilidad para hacer contactos es impresionante.',
              category: 'NETWORKING',
              rarity: 'EPICO',
              xpGranted: 850,
              progressPercentage: 0,
              currentCount: 0,
              requiredCount: 10,
            ),
            Mona(
              code: 'RUTA_CAFE',
              name: 'Ruta del Café',
              description:
                  'Descubre 4 cafeterías distintas en el campus. '
                  'Un verdadero conocedor del buen café.',
              category: 'CAFETERIAS',
              rarity: 'RARO',
              xpGranted: 450,
              progressPercentage: 0,
              currentCount: 0,
              requiredCount: 4,
            ),
            Mona(
              code: 'EDIFICIO_C',
              name: 'Edificio C',
              description:
                  'Marca tu presencia en el Edificio C. La '
                  'exploradora no se detiene.',
              category: 'EDIFICIOS',
              rarity: 'COMUN',
              xpGranted: 75,
              progressPercentage: 0,
              currentCount: 0,
              requiredCount: 1,
            ),
            Mona(
              code: 'EDIFICIO_D',
              name: 'Edificio D',
              description:
                  'Marca tu presencia en el Edificio D. Cada '
                  'edificio guarda una historia.',
              category: 'EDIFICIOS',
              rarity: 'COMUN',
              xpGranted: 75,
              progressPercentage: 0,
              currentCount: 0,
              requiredCount: 1,
            ),
            Mona(
              code: 'EDIFICIO_E',
              name: 'Edificio E',
              description:
                  'Marca tu presencia en el Edificio E. Conoces '
                  'el campus como la palma de tu mano.',
              category: 'EDIFICIOS',
              rarity: 'COMUN',
              xpGranted: 75,
              progressPercentage: 0,
              currentCount: 0,
              requiredCount: 1,
            ),
            Mona(
              code: 'EDIFICIO_F',
              name: 'Edificio F',
              description:
                  'Marca tu presencia en el Edificio F. No hay '
                  'aula que se te resista.',
              category: 'EDIFICIOS',
              rarity: 'COMUN',
              xpGranted: 75,
              progressPercentage: 0,
              currentCount: 0,
              requiredCount: 1,
            ),
            Mona(
              code: 'EDIFICIO_G',
              name: 'Edificio G',
              description:
                  'Marca tu presencia en el Edificio G. Sigues '
                  'sumando edificios a tu colección.',
              category: 'EDIFICIOS',
              rarity: 'COMUN',
              xpGranted: 75,
              progressPercentage: 0,
              currentCount: 0,
              requiredCount: 1,
            ),
            Mona(
              code: 'EDIFICIO_H',
              name: 'Edificio H',
              description:
                  'Marca tu presencia en el Edificio H. La meta '
                  'está cada vez más cerca.',
              category: 'EDIFICIOS',
              rarity: 'COMUN',
              xpGranted: 75,
              progressPercentage: 0,
              currentCount: 0,
              requiredCount: 1,
            ),
            Mona(
              code: 'EDIFICIO_I',
              name: 'Edificio I',
              description:
                  'Marca tu presencia en el Edificio I. El '
                  'último de los 9 edificios te espera.',
              category: 'EDIFICIOS',
              rarity: 'COMUN',
              xpGranted: 75,
              progressPercentage: 0,
              currentCount: 0,
              requiredCount: 1,
            ),
            Mona(
              code: 'TOUR_CAMPUS',
              name: 'Tour Campus',
              description:
                  'Visita los 9 edificios del campus. Nadie '
                  'conoce mejor esta universidad que tú.',
              category: 'EDIFICIOS',
              rarity: 'RARO',
              xpGranted: 500,
              progressPercentage: 0,
              currentCount: 0,
              requiredCount: 9,
            ),
            Mona(
              code: 'ZEN_MASTER',
              name: 'Zen Master',
              description:
                  'Encuentra la paz interior registrándote en el '
                  'lago o la zona de reflexión.',
              category: 'ESTILO_DE_VIDA',
              rarity: 'POCO_COMUN',
              xpGranted: 200,
              progressPercentage: 0,
              currentCount: 0,
              requiredCount: 1,
            ),
            Mona(
              code: 'ATLETA_PATIO',
              name: 'Atleta de Patio',
              description:
                  'Únete a un parche deportivo y demuestra que '
                  'el deporte es parte de tu vida.',
              category: 'ESTILO_DE_VIDA',
              rarity: 'POCO_COMUN',
              xpGranted: 150,
              progressPercentage: 0,
              currentCount: 0,
              requiredCount: 1,
            ),
            Mona(
              code: 'NOCTAMBULO_ACADEMICO',
              name: 'Noctámbulo Académico',
              description:
                  'Registra tu entrada después de las 7:30 PM. '
                  'La noche es de los que estudian.',
              category: 'ESTILO_DE_VIDA',
              rarity: 'RARO',
              xpGranted: 300,
              progressPercentage: 0,
              currentCount: 0,
              requiredCount: 1,
            ),
            Mona(
              code: 'AMANECER_PRODUCTIVO',
              name: 'Amanecer Productivo',
              description:
                  'Registra tu entrada antes de las 7:00 AM '
                  'durante 5 días seguidos. La disciplina es tu '
                  'superpoder.',
              category: 'ESTILO_DE_VIDA',
              rarity: 'RARO',
              xpGranted: 300,
              progressPercentage: 0,
              currentCount: 0,
              requiredCount: 5,
            ),
            Mona(
              code: 'INVITADO_ESPECIAL',
              name: 'Invitado Especial',
              description:
                  'Escanea códigos QR en 5 eventos diferentes. '
                  'Eres el alma de los eventos del campus.',
              category: 'EVENTOS',
              rarity: 'EPICO',
              xpGranted: 500,
              progressPercentage: 0,
              currentCount: 0,
              requiredCount: 5,
            ),
            Mona(
              code: 'CONQUISTADOR_CAMPUS',
              name: 'Conquistador del Campus',
              description:
                  'Registra tu paso por todos los edificios y la '
                  'zona de reflexión. El campus es tu territorio.',
              category: 'LEGENDARIAS',
              rarity: 'LEGENDARIO',
              xpGranted: 1000,
              progressPercentage: 0,
              currentCount: 0,
              requiredCount: 10,
            ),
            Mona(
              code: 'LEYENDA_CAMPUS',
              name: 'Leyenda del Campus',
              description:
                  'Colecciona 30 monas diferentes en tu álbum. '
                  'Tu legado trascenderá generaciones.',
              category: 'LEGENDARIAS',
              rarity: 'LEGENDARIO',
              xpGranted: 1500,
              progressPercentage: 30,
              currentCount: 9,
              requiredCount: 30,
            ),
            Mona(
              code: 'NETWORKING_50',
              name: 'Networking 50',
              description:
                  'Alcanza las 50 conexiones activas. Tu red es '
                  'tan vasta como tu ambición.',
              category: 'LEGENDARIAS',
              rarity: 'LEGENDARIO',
              xpGranted: 1200,
              progressPercentage: 12,
              currentCount: 6,
              requiredCount: 50,
            ),
            Mona(
              code: 'EMBAJADOR_CAMPUS',
              name: 'Embajador del Campus',
              description:
                  'Conecta con personas de 4 facultades '
                  'distintas (5 contactos cada una). Eres el puente entre '
                  'mundos.',
              category: 'LEGENDARIAS',
              rarity: 'LEGENDARIO',
              xpGranted: 1500,
              progressPercentage: 0,
              currentCount: 0,
              requiredCount: 20,
            ),
          ],
        ),
      ),
    );
  }
}
