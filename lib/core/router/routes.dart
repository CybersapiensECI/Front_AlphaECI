/// Paths centralizados. Nunca hardcodear rutas en pantallas.
abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';
  static const forgotPassword = '/forgot-password';
  static const completeProfile = '/complete-profile';
  static const home = '/home';
  static const editProfile = '/profile/edit';
  static const notifications = '/notifications';
  static const createParche = '/parches/create';
  static const parcheDetail = '/parches/:id';
  static const chats = '/chats';
  static const chatRoom = '/chats/:roomId';
  static const monas = '/monas';
  static const dashboard = '/dashboard';
  static const bienestar = '/bienestar';
  static const zone = '/zona';
  static const cafeteria = '/cafeteria';
  static const publicProfile = '/users/:id';

  static String parcheDetailPath(String id) => '/parches/$id';
  static String chatRoomPath(String roomId) => '/chats/$roomId';
  static String publicProfilePath(String id) => '/users/$id';
}
