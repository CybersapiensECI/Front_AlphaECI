import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/breakpoints.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../auth/presentation/widgets/auth_layout.dart' show showAppSnackBar;
import '../../domain/entities/profile.dart';
import '../providers/profile_provider.dart';

/// Edición de perfil + selector de intereses del catálogo.
/// PATCH /api/v1/users/{userId}/student — enums verificados en el DTO:
/// gender: MALE/FEMALE/OTHER/PREFER_NOT_TO_SAY;
/// privacyLevel: PUBLIC/PRIVATE/MATCH_ONLY.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _semester = TextEditingController();
  final _biography = TextEditingController();
  String? _gender;
  String? _privacy;
  bool _loading = false;
  bool _initialized = false;

  static const _genders = ['MALE', 'FEMALE', 'OTHER', 'PREFER_NOT_TO_SAY'];
  static const _genderLabels = {
    'MALE': 'Masculino',
    'FEMALE': 'Femenino',
    'OTHER': 'Otro',
    'PREFER_NOT_TO_SAY': 'Prefiero no decir',
  };
  static const _privacyLevels = ['PUBLIC', 'MATCH_ONLY', 'PRIVATE'];
  static const _privacyLabels = {
    'PUBLIC': 'Público',
    'MATCH_ONLY': 'Solo mis conexiones',
    'PRIVATE': 'Privado',
  };

  @override
  void dispose() {
    _name.dispose();
    _semester.dispose();
    _biography.dispose();
    super.dispose();
  }

  void _initFrom(UserProfile p) {
    if (_initialized) return;
    _initialized = true;
    _name.text = p.name;
    _semester.text = p.semester?.toString() ?? '';
    _biography.text = p.biography ?? '';
    _gender = _genders.contains(p.gender) ? p.gender : null;
    _privacy = _privacyLevels.contains(p.privacyLevel) ? p.privacyLevel : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await ref.read(profileActionsProvider).update(
          name: _name.text.trim(),
          gender: _gender,
          semester: int.tryParse(_semester.text.trim()),
          biography: _biography.text.trim(),
          privacyLevel: _privacy,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (_) {
        showAppSnackBar(context, 'Perfil actualizado ✨');
        context.pop();
      },
      error: (failure) => showAppSnackBar(context, failure.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(myProfileProvider);
    final catalog = ref.watch(tagCatalogProvider);
    final theme = Theme.of(context);

    return GradientScaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: AsyncValueView<UserProfile>(
        value: profile,
        onRetry: () => ref.invalidate(myProfileProvider),
        data: (p) {
          _initFrom(p);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    maxWidth: Breakpoints.contentMaxWidth),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        label: 'Nombre completo',
                        controller: _name,
                        validator: (v) =>
                            Validators.required(v, 'El nombre'),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration:
                            const InputDecoration(labelText: 'Género'),
                        items: [
                          for (final g in _genders)
                            DropdownMenuItem(
                                value: g, child: Text(_genderLabels[g]!)),
                        ],
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Semestre (1-10)',
                        controller: _semester,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final n = int.tryParse(v.trim());
                          if (n == null || n < 1 || n > 10) {
                            return 'Semestre entre 1 y 10.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Biografía (máx. 200)',
                        controller: _biography,
                        maxLines: 3,
                        validator: (v) => (v != null && v.length > 200)
                            ? 'Máximo 200 caracteres.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _privacy,
                        decoration: const InputDecoration(
                            labelText: 'Privacidad del perfil'),
                        items: [
                          for (final l in _privacyLevels)
                            DropdownMenuItem(
                                value: l, child: Text(_privacyLabels[l]!)),
                        ],
                        onChanged: (v) => setState(() => _privacy = v),
                      ),
                      const SizedBox(height: 24),
                      Text('Mi horario', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Agrega tus bloques de clase u ocupación: se usan '
                        'para calcular afinidad y son necesarios para '
                        'poder conectar con otras personas.',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      _ScheduleEditor(profile: p),
                      const SizedBox(height: 24),
                      Text('Intereses', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Toca para agregar o quitar (3-10 recomendados).',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      catalog.when(
                        loading: () => const Center(
                            child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        )),
                        error: (e, _) => Text(
                          'No se pudo cargar el catálogo de intereses.',
                          style: theme.textTheme.bodySmall,
                        ),
                        data: (categories) =>
                            _TagSelector(categories: categories, profile: p),
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        label: 'Guardar cambios',
                        loading: _loading,
                        onPressed: _save,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TagSelector extends ConsumerWidget {
  const _TagSelector({required this.categories, required this.profile});

  final List<TagCategory> categories;
  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final myTagIds = {for (final t in profile.tags) t.id};
    final actions = ref.read(profileActionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final category in categories) ...[
          Text(category.name, style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in category.tags)
                FilterChip(
                  label: Text(tag.name),
                  selected: myTagIds.contains(tag.id),
                  onSelected: (selected) async {
                    final result = selected
                        ? await actions.addTag(tag.id)
                        : await actions.removeTag(tag.id);
                    if (context.mounted) {
                      final failure = result.failureOrNull;
                      if (failure != null) {
                        showAppSnackBar(context, failure.message);
                      }
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

const _dayLabels = {
  'MONDAY': 'Lunes',
  'TUESDAY': 'Martes',
  'WEDNESDAY': 'Miércoles',
  'THURSDAY': 'Jueves',
  'FRIDAY': 'Viernes',
  'SATURDAY': 'Sábado',
  'SUNDAY': 'Domingo',
};
const _dayOrder = [
  'MONDAY',
  'TUESDAY',
  'WEDNESDAY',
  'THURSDAY',
  'FRIDAY',
  'SATURDAY',
  'SUNDAY',
];

/// Lista de bloques de disponibilidad + alta/baja (POST/DELETE /schedules).
/// Requerido por matching-service para poder conectar con otras personas.
class _ScheduleEditor extends ConsumerStatefulWidget {
  const _ScheduleEditor({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends ConsumerState<_ScheduleEditor> {
  bool _busy = false;

  Future<void> _remove(Schedule schedule) async {
    setState(() => _busy = true);
    final result =
        await ref.read(profileActionsProvider).removeSchedule(schedule);
    if (!mounted) return;
    setState(() => _busy = false);
    final failure = result.failureOrNull;
    if (failure != null) showAppSnackBar(context, failure.message);
  }

  Future<void> _openAddDialog() async {
    final schedule = await showDialog<Schedule>(
      context: context,
      builder: (_) => const _AddScheduleDialog(),
    );
    if (schedule == null || !mounted) return;
    setState(() => _busy = true);
    final result =
        await ref.read(profileActionsProvider).addSchedule(schedule);
    if (!mounted) return;
    setState(() => _busy = false);
    final failure = result.failureOrNull;
    if (failure != null) showAppSnackBar(context, failure.message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schedules = [...widget.profile.schedules]..sort((a, b) {
        final dayCmp =
            _dayOrder.indexOf(a.dayOfWeek).compareTo(_dayOrder.indexOf(b.dayOfWeek));
        return dayCmp != 0 ? dayCmp : a.startTime.compareTo(b.startTime);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (schedules.isEmpty)
          Text(
            'Aún no tienes horario registrado.',
            style: theme.textTheme.bodySmall,
          )
        else
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final s in schedules) ...[
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.schedule_outlined),
                    title: Text(s.name),
                    subtitle: Text(
                      '${_dayLabels[s.dayOfWeek] ?? s.dayOfWeek} · '
                      '${s.startTime} - ${s.endTime}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _busy ? null : () => _remove(s),
                    ),
                  ),
                  if (s != schedules.last) const Divider(height: 1),
                ],
              ],
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : _openAddDialog,
          icon: const Icon(Icons.add),
          label: const Text('Agregar horario'),
        ),
      ],
    );
  }
}

class _AddScheduleDialog extends StatefulWidget {
  const _AddScheduleDialog();

  @override
  State<_AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<_AddScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _day = 'MONDAY';
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickStart() async {
    final picked = await showTimePicker(context: context, initialTime: _start);
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(context: context, initialTime: _end);
    if (picked != null) setState(() => _end = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final startMinutes = _start.hour * 60 + _start.minute;
    final endMinutes = _end.hour * 60 + _end.minute;
    if (endMinutes <= startMinutes) {
      showAppSnackBar(context, 'La hora final debe ser después de la inicial.');
      return;
    }
    Navigator.of(context).pop(
      Schedule(
        dayOfWeek: _day,
        name: _name.text.trim(),
        startTime: _fmt(_start),
        endTime: _fmt(_end),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar horario'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Nombre (ej. Cálculo diferencial)',
              controller: _name,
              validator: (v) => Validators.required(v, 'El nombre'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _day,
              decoration: const InputDecoration(labelText: 'Día'),
              items: [
                for (final d in _dayOrder)
                  DropdownMenuItem(value: d, child: Text(_dayLabels[d]!)),
              ],
              onChanged: (v) => setState(() => _day = v ?? _day),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickStart,
                    child: Text('Desde ${_fmt(_start)}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickEnd,
                    child: Text('Hasta ${_fmt(_end)}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Agregar')),
      ],
    );
  }
}
