import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/campus_places.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../auth/presentation/widgets/auth_layout.dart'
    show showAppSnackBar;
import '../../../matching/presentation/providers/matching_provider.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';
import '../providers/parche_provider.dart';
import 'parches_screen.dart' show kParcheCategories;

/// Crear parche — espejo de CreateParcheCommand. `place` y `category`
/// envían el código real del enum del backend; el dropdown solo muestra
/// una etiqueta bonita (ver `placeLabelOf` / `AppCategoryStyles.labelOf`).
class CreateParcheScreen extends ConsumerStatefulWidget {
  const CreateParcheScreen({super.key});

  @override
  ConsumerState<CreateParcheScreen> createState() =>
      _CreateParcheScreenState();
}

class _CreateParcheScreenState extends ConsumerState<CreateParcheScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _quota = TextEditingController(text: '5');
  String? _place;
  String? _category;
  DateTime? _date;
  TimeOfDay? _hour;
  bool _isPrivate = false;
  bool _loading = false;

  /// Amistades a invitar al crear (solo parche privado).
  final _invitees = <String>{};

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _quota.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickHour() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 15, minute: 0),
    );
    if (picked != null) setState(() => _hour = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_place == null || _category == null) {
      showAppSnackBar(context, 'Elige lugar y categoría del parche.');
      return;
    }
    if (_date == null || _hour == null) {
      showAppSnackBar(context, 'Elige fecha y hora del parche.');
      return;
    }
    setState(() => _loading = true);
    final hourString =
        '${_hour!.hour.toString().padLeft(2, '0')}:${_hour!.minute.toString().padLeft(2, '0')}';
    final result = await ref.read(parcheActionsProvider).create(
          name: _name.text.trim(),
          description: _description.text.trim(),
          place: _place!,
          category: _category!,
          type: _isPrivate ? 'PRIVATE' : 'PUBLIC',
          date: _date!,
          hour: hourString,
          maximumQuota: int.parse(_quota.text.trim()),
        );
    if (!mounted) return;
    setState(() => _loading = false);
    await result.when(
      success: (parcheId) async {
        // Parche privado: enviar invitaciones a las amistades marcadas.
        var sent = 0;
        if (_isPrivate && _invitees.isNotEmpty) {
          final actions = ref.read(parcheActionsProvider);
          for (final id in _invitees) {
            final invitation = await actions.invite(parcheId, id);
            if (invitation.isSuccess) sent++;
          }
        }
        if (!mounted) return;
        showAppSnackBar(
          context,
          sent > 0
              ? '¡Parche creado! $sent invitación(es) enviada(s) 🎉'
              : '¡Parche creado! 🎉',
        );
        context.pop();
      },
      error: (failure) async => showAppSnackBar(context, failure.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientScaffold(
      appBar: AppBar(title: const Text('Crear parche')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Nombre del parche',
                    controller: _name,
                    validator: (v) => Validators.required(v, 'El nombre'),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Descripción',
                    controller: _description,
                    maxLines: 3,
                    validator: (v) =>
                        Validators.required(v, 'La descripción'),
                  ),
                  const SizedBox(height: 16),
                  // Lugar del campus: alimenta el mapa de geolocalización.
                  DropdownButtonFormField<String>(
                    initialValue: _place,
                    decoration: const InputDecoration(
                      labelText: 'Lugar del campus',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                    items: [
                      for (final place in campusPlaces.keys)
                        DropdownMenuItem(
                          value: place,
                          child: Text(placeLabelOf(place)),
                        ),
                    ],
                    onChanged: (v) => setState(() => _place = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: [
                      for (final category in kParcheCategories)
                        DropdownMenuItem(
                          value: category,
                          child: Row(
                            children: [
                              Icon(
                                AppCategoryStyles.of(category).$1,
                                size: 18,
                                color: AppCategoryStyles.of(category).$2,
                              ),
                              const SizedBox(width: 8),
                              Text(AppCategoryStyles.labelOf(category)),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _category = v),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(_date == null
                              ? 'Fecha'
                              : DateFormat('d MMM yyyy').format(_date!)),
                          onPressed: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.schedule_outlined),
                          label: Text(_hour == null
                              ? 'Hora'
                              : _hour!.format(context)),
                          onPressed: _pickHour,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Cupo máximo (2-30)',
                    controller: _quota,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      if (n == null || n < 2 || n > 30) {
                        return 'Cupo entre 2 y 30.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Parche privado'),
                    subtitle: Text(
                      'Solo se entra con invitación',
                      style: theme.textTheme.bodySmall,
                    ),
                    value: _isPrivate,
                    onChanged: (v) => setState(() => _isPrivate = v),
                  ),
                  // Privado: elegir amistades a invitar al crear.
                  if (_isPrivate) ...[
                    const SizedBox(height: 8),
                    Text('Invitar amistades',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Consumer(
                      builder: (context, ref, _) {
                        final friends = ref.watch(friendsProvider);
                        return friends.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(
                                child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => Text(
                            'No se pudieron cargar tus amistades.',
                            style: theme.textTheme.bodySmall,
                          ),
                          data: (items) {
                            if (items.isEmpty) {
                              return Text(
                                'Aún no tienes amistades. Conecta en '
                                'Descubrir para poder invitar.',
                                style: theme.textTheme.bodySmall,
                              );
                            }
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final friend in items)
                                  FilterChip(
                                    avatar: ProfileAvatar(
                                      name: friend.profile.name,
                                      photoUrl: friend.profile.photoUrl,
                                      radius: 12,
                                    ),
                                    label: Text(friend.profile.name),
                                    selected: _invitees
                                        .contains(friend.profile.id),
                                    onSelected: (v) => setState(() {
                                      if (v) {
                                        _invitees.add(friend.profile.id);
                                      } else {
                                        _invitees
                                            .remove(friend.profile.id);
                                      }
                                    }),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Crear parche',
                    icon: Icons.celebration_outlined,
                    loading: _loading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
