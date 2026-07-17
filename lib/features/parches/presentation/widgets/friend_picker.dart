import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_assets.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/mascot.dart';
import '../../../matching/presentation/providers/matching_provider.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';

/// Selector de amistades (matches ACCEPTED) para invitar a un parche.
/// Devuelve los ids de estudiante seleccionados, o null si cancela.
Future<List<String>?> showFriendPicker(
  BuildContext context, {
  String title = 'Invitar amistades',
}) {
  return showAppSheet<List<String>>(
    context,
    child: _FriendPickerSheet(title: title),
  );
}

class _FriendPickerSheet extends ConsumerStatefulWidget {
  const _FriendPickerSheet({required this.title});

  final String title;

  @override
  ConsumerState<_FriendPickerSheet> createState() =>
      _FriendPickerSheetState();
}

class _FriendPickerSheetState extends ConsumerState<_FriendPickerSheet> {
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final friends = ref.watch(friendsProvider);

    // Contenedor/alto/handle: AppSheet (estándar 2/3 de pantalla).
    return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: friends.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No se pudieron cargar tus amistades.'),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const MascotEmptyState(
                      asset: AppAssets.stickerConfused,
                      message: 'Aún no tienes amistades para invitar.\n'
                          'Conecta con gente en Descubrir.',
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final friend = items[index];
                      final id = friend.profile.id;
                      final checked = _selected.contains(id);
                      return CheckboxListTile(
                        value: checked,
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selected.add(id);
                          } else {
                            _selected.remove(id);
                          }
                        }),
                        secondary: ProfileAvatar(
                          name: friend.profile.name,
                          photoUrl: friend.profile.photoUrl,
                          radius: 20,
                        ),
                        title: Text(friend.profile.name),
                        controlAffinity: ListTileControlAffinity.trailing,
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _selected.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_selected.toList()),
              icon: const Icon(Icons.send, size: 18),
              label: Text(_selected.isEmpty
                  ? 'Selecciona amistades'
                  : 'Invitar (${_selected.length})'),
            ),
          ],
    );
  }
}
