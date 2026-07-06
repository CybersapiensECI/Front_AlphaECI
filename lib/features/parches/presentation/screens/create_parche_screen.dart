import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/breakpoints.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../auth/presentation/widgets/auth_layout.dart'
    show showAppSnackBar;
import '../providers/parche_provider.dart';

/// Crear parche — espejo de CreateParcheCommand.
/// TODO(backend): confirmar valores válidos de los enums Places y
/// ParcheCategory; por ahora se envían como texto libre.
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
  final _place = TextEditingController();
  final _category = TextEditingController();
  final _quota = TextEditingController(text: '5');
  DateTime? _date;
  TimeOfDay? _hour;
  bool _isPrivate = false;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _place.dispose();
    _category.dispose();
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
          place: _place.text.trim(),
          category: _category.text.trim(),
          type: _isPrivate ? 'PRIVATE' : 'PUBLIC',
          date: _date!,
          hour: hourString,
          maximumQuota: int.parse(_quota.text.trim()),
        );
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (_) {
        showAppSnackBar(context, '¡Parche creado! 🎉');
        context.pop();
      },
      error: (failure) => showAppSnackBar(context, failure.message),
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
                  AppTextField(
                    label: 'Lugar (ej. Cafetería central)',
                    controller: _place,
                    validator: (v) => Validators.required(v, 'El lugar'),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Categoría (ej. DEPORTE, ESTUDIO, JUEGOS)',
                    controller: _category,
                    validator: (v) => Validators.required(v, 'La categoría'),
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
