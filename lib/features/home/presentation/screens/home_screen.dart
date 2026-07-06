import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/screens/events_screen.dart';
import '../../../feed/presentation/screens/feed_screen.dart';
import '../../../matching/presentation/screens/discovery_screen.dart';
import '../../../matching/presentation/screens/matches_screen.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../parches/presentation/screens/parches_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

/// Shell principal: Descubrir · Matches · Parches · Eventos · Perfil.
/// Campana de notificaciones con badge en el AppBar.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

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
    AdaptiveDestination(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    return AdaptiveScaffold(
      destinations: _destinations,
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      appBar: AppBar(
        title: _index == 0
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
            : Text(_destinations[_index].label),
        actions: [
          IconButton(
            tooltip: 'Chats',
            onPressed: () => context.push(Routes.chats),
            icon: const Icon(Icons.chat_bubble_outline),
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
        child: switch (_index) {
          0 => const FeedScreen(key: ValueKey('feed')),
          1 => const ParchesScreen(key: ValueKey('parches')),
          2 => const DiscoveryScreen(key: ValueKey('discovery')),
          3 => const MatchesScreen(key: ValueKey('matches')),
          4 => const EventsScreen(key: ValueKey('events')),
          _ => const ProfileScreen(key: ValueKey('profile')),
        },
      ),
    );
  }
}
