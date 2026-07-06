import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Shell principal post-login. Las pestañas Matches/Chat/Parches son
/// placeholders: cada una se reemplaza al implementar su feature
/// (matching-service, chat-service, Parches-Service).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  static const _destinations = [
    AdaptiveDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Inicio',
    ),
    AdaptiveDestination(
      icon: Icons.favorite_outline,
      selectedIcon: Icons.favorite,
      label: 'Matches',
    ),
    AdaptiveDestination(
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      label: 'Chat',
    ),
    AdaptiveDestination(
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
      label: 'Parches',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).session;

    return AdaptiveScaffold(
      destinations: _destinations,
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      appBar: AppBar(
        title: Text(_destinations[_index].label),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: switch (_index) {
        0 => _WelcomeTab(email: session?.email ?? ''),
        1 => const EmptyState(
            icon: Icons.favorite_outline,
            message:
                'Matches — pendiente de implementar (matching-service).',
          ),
        2 => const EmptyState(
            icon: Icons.chat_bubble_outline,
            message: 'Chat — pendiente de implementar (chat-service).',
          ),
        _ => const EmptyState(
            icon: Icons.groups_outlined,
            message: 'Parches — pendiente de implementar (Parches-Service).',
          ),
      },
    );
  }
}

class _WelcomeTab extends StatelessWidget {
  const _WelcomeTab({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('¡Bienvenido!', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(email, style: theme.textTheme.bodySmall),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sesión activa',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        'La autenticación contra identity-service funciona. '
                        'Las demás features (perfil, matching, chat, eventos, '
                        'parches…) se conectan sobre esta misma base.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
