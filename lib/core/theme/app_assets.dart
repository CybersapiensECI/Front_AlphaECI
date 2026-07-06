/// Rutas centralizadas de assets de marca (logo, mascota y stickers).
abstract final class AppAssets {
  static const logo = 'assets/brand/logo.png';
  static const mascot = 'assets/brand/mascot.png';
  static const mascotStanding = 'assets/brand/mascot_standing.png';

  // Spritesheet de stickers de la mascota (4x5 grilla)
  static const stickersSheet = 'assets/stickers/spritesheet.jpg';

  static const int stickerGoodMorning = 0; // ¡Buenos días!
  static const int stickerWhat = 1;        // ¿Quéee?
  static const int stickerEh = 2;          // ¿Eh?
  static const int stickerReminder = 3;    // ¡Te lo recuerdo!
  
  static const int stickerApproved = 4;    // ¡Guau! ¡Aprobado!
  static const int stickerOk = 5;          // ¡Bien!
  static const int stickerHey = 6;         // ¡Oye, tú!
  static const int stickerSneeze = 7;      // ¡Achís!
  
  static const int stickerAngry = 8;       // ¡Enojado!
  static const int stickerConfused = 9;    // ¿Eh???
  static const int stickerSleepy = 10;     // Mucho sueño
  static const int stickerLove = 11;       // Demasiado lindooo (corazón)
  
  static const int stickerCool = 12;       // ¿Ya me veo cool?! (lentes)
  static const int stickerStudyingLaptop = 13; // Estudiando (laptop)
  static const int stickerEating = 14;     // Nom nom (galleta)
  static const int stickerGrumpy = 15;     // Gruñón
  
  static const int stickerGoodnight = 16;  // Buenas noches :3
  static const int stickerCute = 17;       // Demasiado lindooo (manos en cara)
  static const int stickerWink = 18;       // ¿Ya me veo cool?! (guiño)
  static const int stickerStudyingBook = 19; // Estudiando (libros)
}
