import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/interest_chip.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
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

  /// Intereses elegidos (ids de tags del catálogo del back).
  final _selectedTags = <String>{};

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
    if (_selectedTags.isEmpty) {
      showAppSnackBar(
          context, 'Elige al menos un interés para terminar tu registro.');
      return;
    }
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
    await result.when(
      success: (message) async {
        // Registrar los intereses elegidos (best effort: un tag que
        // falle no bloquea el cierre del registro).
        final actions = ref.read(profileActionsProvider);
        for (final tagId in _selectedTags) {
          await actions.addTag(tagId);
        }
        if (!mounted) return;
        setState(() => _loading = false);
        showAppSnackBar(context, message);
        context.go(Routes.home);
      },
      error: (failure) async {
        setState(() => _loading = false);
        showAppSnackBar(context, failure.message);
      },
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
            // ── Paso: elige tus intereses (catálogo del back) ──
            Text('Tus intereses',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Elige al menos uno: así te recomendamos parches y '
              'personas afines.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, _) {
                final catalog = ref.watch(tagCatalogProvider);
                return catalog.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text(
                    'No se pudo cargar el catálogo de intereses. '
                    'Podrás agregarlos luego desde tu perfil.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  data: (categories) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final category in categories) ...[
                        Text(
                          AppCategoryStyles.labelOf(category.name),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final tag in category.tags)
                              InterestChip(
                                label: tag.name,
                                selected: _selectedTags.contains(tag.id),
                                // Color de la categoría, igual que en
                                // el feed principal.
                                accent:
                                    AppCategoryStyles.of(category.name).$2,
                                onTap: () => setState(() {
                                  if (!_selectedTags.remove(tag.id)) {
                                    _selectedTags.add(tag.id);
                                  }
                                }),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
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
