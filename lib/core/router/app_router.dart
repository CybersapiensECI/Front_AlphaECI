import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/complete_profile_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/parches/domain/entities/parche.dart';
import '../../features/parches/presentation/screens/create_parche_screen.dart';
import '../../features/parches/presentation/screens/parche_detail_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../widgets/error_view.dart';
import '../widgets/splash_screen.dart';
import 'routes.dart';

/// Rutas accesibles sin sesión.
const _publicRoutes = {
  Routes.login,
  Routes.register,
  Routes.otp,
  Routes.forgotPassword,
};

final routerProvider = Provider<GoRouter>((ref) {
  // refreshListenable: cuando cambia el estado de auth, el router
  // re-evalúa redirect (login <-> home automático).
  final refresh = ValueNotifier(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;

      // Restaurando sesión: quedarse en splash.
      if (auth.status == AuthStatus.unknown) {
        return location == Routes.splash ? null : Routes.splash;
      }

      final isPublic = _publicRoutes.contains(location);

      if (auth.status == AuthStatus.unauthenticated) {
        return isPublic ? null : Routes.login;
      }

      // Autenticado: fuera de splash y pantallas públicas.
      if (location == Routes.splash || isPublic) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.otp,
        builder: (_, state) {
          final extra = state.extra;
          final map = extra is Map ? extra : const {};
          return OtpScreen(
            email: map['email'] as String? ?? '',
            password: map['password'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: Routes.completeProfile,
        builder: (_, state) =>
            CompleteProfileScreen(email: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: Routes.home,
        builder: (_, _) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.editProfile,
        builder: (_, _) => const EditProfileScreen(),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: Routes.createParche,
        builder: (_, _) => const CreateParcheScreen(),
      ),
      GoRoute(
        path: Routes.parcheDetail,
        builder: (_, state) {
          final parche = state.extra;
          if (parche is Parche) {
            return ParcheDetailScreen(parche: parche);
          }
          // Acceso directo por URL sin objeto: volver al feed.
          return const _ParcheNotLoaded();
        },
      ),
    ],
  );
});

class _ParcheNotLoaded extends StatelessWidget {
  const _ParcheNotLoaded();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parche')),
      body: ErrorView(
        message: 'Abre este parche desde el feed.',
        onRetry: () => context.go(Routes.home),
      ),
    );
  }
}
