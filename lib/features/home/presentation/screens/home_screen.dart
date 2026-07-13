import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/screens/events_screen.dart';
import '../../../feed/presentation/screens/feed_screen.dart';
import '../../../gamification/presentation/screens/monas_screen.dart';
import '../../../matching/presentation/screens/discovery_screen.dart';
import '../../../matching/presentation/screens/matches_screen.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../parches/presentation/screens/parches_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

/// Tab activo del shell. Provider para poder navegar a un tab desde
/// fuera (p. ej. tocar una notificación lleva a Matches o Eventos).
final homeTabProvider = StateProvider<int>((_) => 0);

/// Índices de tabs del shell (mantener en sincronía con _destinations).
abstract final class HomeTabs {
  static const inicio = 0;
  static const parches = 1;
  static const descubrir = 2;
  static const matches = 3;
  static const eventos = 4;
  static const monas = 5;
  static const perfil = 6;
}

/// Shell principal: Inicio · Parches · Descubrir · Matches · Eventos · Perfil.
/// Campana de notificaciones con badge en el AppBar.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  // Inicio = publicaciones hechas desde parches (red social).
  // Parches = buscar/filtrar parches y unirse.
  static const _destinations = [
    AdaptiveDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Inicio',
    ),
    AdaptiveDestination(
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
      label: 'Parches',
    ),
    // join_inner: dos círculos que se cruzan = afinidad entre personas
    // (nada de brújula: eso sugiere geolocalización).
    AdaptiveDestination(
      icon: Icons.join_inner,
      selectedIcon: Icons.join_full,
      label: 'Descubrir',
    ),
    AdaptiveDestination(
      icon: Icons.favorite_outline,
      selectedIcon: Icons.favorite,
      label: 'Matches',
    ),
    AdaptiveDestination(
      icon: Icons.event_outlined,
      selectedIcon: Icons.event,
      label: 'Eventos',
    ),
    // Álbum de monas (gamificación) accesible desde la navegación.
    AdaptiveDestination(
      icon: Icons.emoji_events_outlined,
      selectedIcon: Icons.emoji_events,
      label: 'Monas',
    ),
    AdaptiveDestination(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;
    final index = ref.watch(homeTabProvider);

    return AdaptiveScaffold(
      destinations: _destinations,
      selectedIndex: index,
      onDestinationSelected: (i) =>
          ref.read(homeTabProvider.notifier).state = i,
      appBar: AppBar(
        title: index == 0
            // Wordmark de marca con gradiente en el feed.
            ? ShaderMask(
                shaderCallback: (bounds) =>
                    AppGradients.of(context).createShader(bounds),
                child: Text(
                  'AlphaECI',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              )
            : Text(_destinations[index].label),
        actions: [
          IconButton(
            tooltip: 'Chats',
            onPressed: () => context.push(Routes.chats),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
          // Mapa del campus con parches en tiempo real.
          IconButton(
            tooltip: 'Mapa de parches',
            onPressed: () => context.push(Routes.zone),
            icon: const Icon(Icons.map_outlined),
          ),
          // Campana con badge animado.
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () => context.push(Routes.notifications),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authControllerProvider.notifier).logout();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: switch (index) {
          0 => const FeedScreen(key: ValueKey('feed')),
          1 => const ParchesScreen(key: ValueKey('parches')),
          2 => const DiscoveryScreen(key: ValueKey('discovery')),
          3 => const MatchesScreen(key: ValueKey('matches')),
          4 => const EventsScreen(key: ValueKey('events')),
          5 => const MonasBody(key: ValueKey('monas')),
          _ => const ProfileScreen(key: ValueKey('profile')),
        },
      ),
    );
  }
}
