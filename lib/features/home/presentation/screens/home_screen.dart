import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/screens/events_screen.dart';
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

  static const _destinations = [
    AdaptiveDestination(
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
      label: 'Descubrir',
    ),
    AdaptiveDestination(
      icon: Icons.favorite_outline,
      selectedIcon: Icons.favorite,
      label: 'Matches',
    ),
    AdaptiveDestination(
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
      label: 'Parches',
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
        title: Text(_destinations[_index].label),
        actions: [
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
          0 => const DiscoveryScreen(key: ValueKey('discovery')),
          1 => const MatchesScreen(key: ValueKey('matches')),
          2 => const ParchesScreen(key: ValueKey('parches')),
          3 => const EventsScreen(key: ValueKey('events')),
          _ => const ProfileScreen(key: ValueKey('profile')),
        },
      ),
    );
  }
}
