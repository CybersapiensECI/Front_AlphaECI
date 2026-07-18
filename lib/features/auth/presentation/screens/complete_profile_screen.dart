import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/storage/media_upload_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/career_field.dart';
import '../../../../core/widgets/interest_chip.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/registration_data.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_layout.dart';

/// Completa el registro (POST /complete-registration).
/// Campos espejo del CompleteRegistrationRequestDto — TODOS los campos
/// @NotNull/@NotBlank del DTO deben salir de esta pantalla, si no el back
/// rechaza la solicitud entera con 400 (antes faltaban dateOfBirth,
/// photoUrl, privacyLevel y geolocationEnabled: el registro nunca podía
/// terminar de verdad).
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
  final _semester = TextEditingController();
  final _carnet = TextEditingController();
  final _biography = TextEditingController();
  String? _gender;
  String? _career;
  String _privacyLevel = 'PUBLIC';
  bool _geolocationEnabled = false;
  DateTime? _dateOfBirth;
  bool _loading = false;
  Uint8List? _pickedPhotoBytes;
  String _pickedPhotoExt = 'jpg';

  /// Intereses elegidos (ids de tags del catálogo del back).
  final _selectedTags = <String>{};

  // Espejo exacto de CompleteRegistrationRequestDto.gender — mismos
  // valores que edit_profile_screen.dart, para que el dato quede
  // consistente entre las dos pantallas.
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
    _carnet.dispose();
    _biography.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'Fecha de nacimiento',
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    final dot = file.name.lastIndexOf('.');
    final ext = dot == -1 ? 'jpg' : file.name.substring(dot + 1).toLowerCase();
    // profile-service solo acepta PNG/JPEG (valida el content type).
    if (!const {'jpg', 'jpeg', 'png'}.contains(ext)) {
      if (!mounted) return;
      showAppSnackBar(context, 'Solo se aceptan fotos JPG o PNG.');
      return;
    }
    try {
      MediaUploadService.validate(bytes, ext);
    } on MediaValidationException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.message);
      return;
    }
    setState(() {
      _pickedPhotoBytes = bytes;
      _pickedPhotoExt = ext;
    });
  }

  /// En el payload del registro va SIEMPRE un avatar generado (photoUrl es
  /// @NotBlank). La foto real elegida se sube después a profile-service
  /// (POST /profile-image, que guarda la imagen y devuelve la URL): el
  /// perfil se crea de forma asíncrona al evento user-verified, así que la
  /// subida se hace con reintentos y sin bloquear la navegación.
  String get _placeholderPhotoUrl =>
      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_name.text.trim())}&background=1A3F6D&color=fff';

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
                career: _career,
                semester: int.tryParse(_semester.text.trim()),
                studentCarnet: _carnet.text.trim(),
                biography: _biography.text.trim().isEmpty
                    ? null
                    : _biography.text.trim(),
                photoUrl: _placeholderPhotoUrl,
                privacyLevel: _privacyLevel,
                dateOfBirth: _dateOfBirth,
                geolocationEnabled: _geolocationEnabled,
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
        // Foto real: en segundo plano con reintentos (el perfil puede
        // tardar unos segundos en existir). Si falla del todo, queda el
        // avatar y se puede cambiar desde "Editar perfil".
        final photoBytes = _pickedPhotoBytes;
        if (photoBytes != null) {
          unawaited(actions.updatePhoto(
            photoBytes,
            ext: _pickedPhotoExt,
            retries: 3,
          ));
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
    final theme = Theme.of(context);
    return AuthLayout(
      title: 'Completa tu perfil',
      subtitle: 'Cuéntanos quién eres para conectarte mejor.',
      child: Form(
        key: _formKey,
        // Errores visibles apenas el campo pierde validez, no solo al enviar.
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Foto de perfil (opcional) ──────────────────
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor:
                          theme.colorScheme.tertiary.withValues(alpha: 0.15),
                      backgroundImage: _pickedPhotoBytes != null
                          ? MemoryImage(_pickedPhotoBytes!)
                          : null,
                      child: _pickedPhotoBytes == null
                          ? Icon(Icons.person_outline,
                              size: 40, color: theme.colorScheme.primary)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_outlined,
                          size: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Foto de perfil (opcional)',
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Nombre completo',
              controller: _name,
              validator: (v) {
                final required = Validators.required(v, 'El nombre');
                if (required != null) return required;
                final length = v!.trim().length;
                if (length < 2 || length > 50) {
                  return 'Entre 2 y 50 caracteres.';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Género'),
              items: [
                for (final g in _genders)
                  DropdownMenuItem(value: g, child: Text(_genderLabels[g]!)),
              ],
              onChanged: (v) => setState(() => _gender = v),
              validator: (v) => v == null ? 'Elige tu género.' : null,
            ),
            const SizedBox(height: 16),
            CareerField(
              initialCode: _career,
              onChanged: (code) => setState(() => _career = code),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Semestre (1-10)',
                    controller: _semester,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Escribe tu semestre.';
                      }
                      final n = int.tryParse(v.trim());
                      if (n == null || n < 1 || n > 10) {
                        return 'Entre 1 y 10.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: 'Carnet (10 dígitos)',
                    controller: _carnet,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Escribe tu carnet.';
                      }
                      return v.trim().length == 10
                          ? null
                          : 'Debe tener exactamente 10 dígitos.';
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // FormField para que el error salga inline bajo el campo, como
            // en el resto del formulario (no solo un snackbar al enviar).
            FormField<DateTime>(
              validator: (_) =>
                  _dateOfBirth == null ? 'Elige tu fecha de nacimiento.' : null,
              builder: (field) => InkWell(
                onTap: () async {
                  await _pickDateOfBirth();
                  field.didChange(_dateOfBirth);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha de nacimiento',
                    suffixIcon: const Icon(Icons.calendar_today_outlined),
                    errorText: field.errorText,
                  ),
                  child: Text(
                    _dateOfBirth == null
                        ? 'Toca para elegir'
                        : DateFormat('d MMM yyyy').format(_dateOfBirth!),
                    style: _dateOfBirth == null
                        ? theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)
                        : theme.textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _privacyLevel,
              decoration:
                  const InputDecoration(labelText: 'Privacidad del perfil'),
              items: [
                for (final l in _privacyLevels)
                  DropdownMenuItem(value: l, child: Text(_privacyLabels[l]!)),
              ],
              onChanged: (v) =>
                  setState(() => _privacyLevel = v ?? _privacyLevel),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Compartir mi ubicación'),
              subtitle: const Text(
                  'Para "Mi zona del campus" — lo puedes cambiar luego.'),
              value: _geolocationEnabled,
              onChanged: (v) => setState(() => _geolocationEnabled = v),
            ),
            const SizedBox(height: 8),
            AppTextField(
              label: 'Biografía (opcional, máx. 200)',
              controller: _biography,
              maxLines: 3,
              validator: (v) => (v != null && v.trim().length > 200)
                  ? 'Máximo 200 caracteres.'
                  : null,
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
