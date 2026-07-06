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

  static String parcheDetailPath(String id) => '/parches/$id';
}
