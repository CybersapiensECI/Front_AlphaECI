import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/registration_data.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_layout.dart';

/// Completa el registro (POST /complete-registration).
/// Campos espejo del CompleteRegistrationRequestDto.
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState
    extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _career = TextEditingController();
  final _semester = TextEditingController();
  final _carnet = TextEditingController();
  final _biography = TextEditingController();
  String? _gender;
  bool _loading = false;

  // TODO(backend): confirmar valores válidos de gender y privacyLevel
  // (no hay enum expuesto en el DTO).
  static const _genders = ['MASCULINO', 'FEMENINO', 'OTRO', 'PREFIERO_NO_DECIR'];

  @override
  void dispose() {
    _name.dispose();
    _career.dispose();
    _semester.dispose();
    _carnet.dispose();
    _biography.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final result =
        await ref.read(authControllerProvider.notifier).completeRegistration(
              RegistrationData(
                email: widget.email,
                name: _name.text.trim(),
                gender: _gender,
                career: _career.text.trim().isEmpty ? null : _career.text.trim(),
                semester: int.tryParse(_semester.text.trim()),
                studentCarnet:
                    _carnet.text.trim().isEmpty ? null : _carnet.text.trim(),
                biography: _biography.text.trim().isEmpty
                    ? null
                    : _biography.text.trim(),
              ),
            );
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (message) {
        showAppSnackBar(context, message);
        context.go(Routes.home);
      },
      error: (failure) => showAppSnackBar(context, failure.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Completa tu perfil',
      subtitle: 'Cuéntanos quién eres para conectarte mejor.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Nombre completo',
              controller: _name,
              validator: (v) => Validators.required(v, 'El nombre'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Género'),
              items: [
                for (final g in _genders)
                  DropdownMenuItem(value: g, child: Text(g)),
              ],
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Carrera',
              controller: _career,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Semestre',
                    controller: _semester,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: 'Carnet',
                    controller: _carnet,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Biografía (opcional)',
              controller: _biography,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Finalizar registro',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go(Routes.home),
              child: const Text('Completar después'),
            ),
          ],
        ),
      ),
    );
  }
}
