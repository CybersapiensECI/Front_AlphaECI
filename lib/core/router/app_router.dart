import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/complete_profile_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/bienestar/presentation/screens/wellbeing_screen.dart';
import '../../features/chat/presentation/providers/chat_provider.dart';
import '../../features/chat/presentation/screens/chat_room_screen.dart';
import '../../features/chat/presentation/screens/chats_screen.dart';
import '../../features/gamification/presentation/screens/monas_screen.dart';
import '../../features/geo/presentation/screens/zone_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/parches/domain/entities/parche.dart';
import '../../features/parches/presentation/screens/cafeteria_screen.dart';
import '../../features/parches/presentation/screens/create_parche_screen.dart';
import '../../features/parches/presentation/screens/parche_detail_screen.dart';
import '../../features/profile/domain/entities/profile.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/public_profile_screen.dart';
import '../../features/stats/presentation/screens/dashboard_screen.dart';
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
        pageBuilder: (_, state) => _page(state, const SplashScreen()),
      ),
      GoRoute(
        path: Routes.login,
        pageBuilder: (_, state) => _page(state, const LoginScreen()),
      ),
      GoRoute(
        path: Routes.register,
        pageBuilder: (_, state) => _page(state, const RegisterScreen()),
      ),
      GoRoute(
        path: Routes.otp,
        pageBuilder: (_, state) {
          final extra = state.extra;
          final map = extra is Map ? extra : const {};
          return _page(state, OtpScreen(
            email: map['email'] as String? ?? '',
            password: map['password'] as String? ?? '',
          ));
        },
      ),
      GoRoute(
        path: Routes.forgotPassword,
        pageBuilder: (_, state) => _page(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: Routes.completeProfile,
        pageBuilder: (_, state) => _page(
            state, CompleteProfileScreen(email: state.extra as String? ?? '')),
      ),
      GoRoute(
        path: Routes.home,
        pageBuilder: (_, state) => _page(state, const HomeScreen()),
      ),
      GoRoute(
        path: Routes.editProfile,
        pageBuilder: (_, state) => _page(state, const EditProfileScreen()),
      ),
      GoRoute(
        path: Routes.notifications,
        pageBuilder: (_, state) => _page(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: Routes.createParche,
        pageBuilder: (_, state) => _page(state, const CreateParcheScreen()),
      ),
      GoRoute(
        path: Routes.chats,
        pageBuilder: (_, state) => _page(state, const ChatsScreen()),
      ),
      GoRoute(
        path: Routes.chatRoom,
        pageBuilder: (_, state) {
          final extra = state.extra;
          if (extra is ChatConversation) {
            return _page(state, ChatRoomScreen(conversation: extra));
          }
          // Chat grupal del parche.
          if (extra is Parche) {
            return _page(state, ChatRoomScreen.group(parche: extra));
          }
          return _page(state, const ChatsScreen());
        },
      ),
      GoRoute(
        path: Routes.monas,
        pageBuilder: (_, state) => _page(state, const MonasScreen()),
      ),
      GoRoute(
        path: Routes.dashboard,
        pageBuilder: (_, state) => _page(state, const DashboardScreen()),
      ),
      GoRoute(
        path: Routes.bienestar,
        pageBuilder: (_, state) => _page(state, const WellbeingScreen()),
      ),
      GoRoute(
        path: Routes.zone,
        pageBuilder: (_, state) => _page(state, const ZoneScreen()),
      ),
      GoRoute(
        path: Routes.cafeteria,
        pageBuilder: (_, state) => _page(state, const CafeteriaScreen()),
      ),
      GoRoute(
        path: Routes.publicProfile,
        pageBuilder: (_, state) {
          final summary = state.extra;
          if (summary is ProfileSummary) {
            return _page(state, PublicProfileScreen(summary: summary));
          }
          return _page(state, const HomeScreen());
        },
      ),
      GoRoute(
        path: Routes.parcheDetail,
        pageBuilder: (_, state) {
          final parche = state.extra;
          if (parche is Parche) {
            return _page(state, ParcheDetailScreen(parche: parche));
          }
          // Acceso directo por URL sin objeto: volver al feed.
          return _page(state, const _ParcheNotLoaded());
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

/// Transición estándar de la app: fade + slide sutil (280ms).
CustomTransitionPage<void> _page(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
