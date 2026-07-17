/// Rutas centralizadas de assets de marca (logo, mascota y stickers).
/// Los stickers usan los archivos del paquete oficial (nombres en español).
abstract final class AppAssets {
  static const logo = 'assets/brand/logo.png';
  static const mascot = 'assets/brand/mascot.png';
  static const mascotStanding = 'assets/brand/mascot_standing.png';

  static const _st = 'assets/stickers';

  // Alias semánticos (nombres estables usados por toda la app) apuntando
  // a los archivos reales del paquete de stickers.
  static const stickerHello = '$_st/Buenos_Dias.png';
  static const stickerReminder = '$_st/Te_Lo_Recuerdo.png';
  static const stickerApproved = '$_st/Aprobado.png';
  static const stickerOk = '$_st/Bien.png';
  static const stickerHey = '$_st/Oye_Tu.png';
  static const stickerConfused = '$_st/Eh.png';
  static const stickerSleepy = '$_st/Mucho_Sueno.png';
  static const stickerLove = '$_st/Demasiado_Lindo.png';
  static const stickerCool = '$_st/Cool.png';
  static const stickerStudying = '$_st/Estudiando.png';
  static const stickerGrumpy = '$_st/Grunon.png';
  static const stickerGoodnight = '$_st/Buenas_noches.png';

  // Extras del paquete.
  static const stickerSneeze = '$_st/Achis.png';
  static const stickerYum = '$_st/Nom_Nom.png';
  static const stickerAngry = '$_st/Enojado.png';
  static const stickerWhat = '$_st/Queee.png';
}
