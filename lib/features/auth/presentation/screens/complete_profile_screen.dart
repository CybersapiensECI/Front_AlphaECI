import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/env.dart';
import '../../../../core/constants/careers.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/storage/media_upload_service.dart';
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
  bool _uploadingPhoto = false;
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
    try {
      MediaUploadService.validate(
        bytes,
        MediaUploadService.allowedExtensions.contains(ext) ? ext : 'jpg',
      );
    } on MediaValidationException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.message);
      return;
    }
    setState(() {
      _pickedPhotoBytes = bytes;
      _pickedPhotoExt = MediaUploadService.allowedExtensions.contains(ext)
          ? ext
          : 'jpg';
    });
  }

  /// Foto es opcional para no bloquear el registro: si no eligen una, se
  /// manda un avatar genérico (photoUrl es @NotBlank en el DTO, no puede
  /// ir vacío).
  Future<String> _resolvePhotoUrl(String userId) async {
    if (_pickedPhotoBytes == null) {
      return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_name.text.trim())}&background=1A3F6D&color=fff';
    }
    if (Env.demoMode && !Env.firebaseTest) {
      return 'https://picsum.photos/seed/$userId/400/400';
    }
    return ref.read(mediaUploadServiceProvider).uploadProfilePhoto(
          _pickedPhotoBytes!,
          userId: userId,
          ext: _pickedPhotoExt,
        );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTags.isEmpty) {
      showAppSnackBar(
          context, 'Elige al menos un interés para terminar tu registro.');
      return;
    }
    if (_dateOfBirth == null) {
      showAppSnackBar(context, 'Ingresa tu fecha de nacimiento.');
      return;
    }
    if (_career == null) {
      showAppSnackBar(context, 'Elige tu carrera.');
      return;
    }

    final session = ref.read(authControllerProvider).session;
    setState(() => _loading = true);

    String photoUrl;
    try {
      setState(() => _uploadingPhoto = true);
      photoUrl = await _resolvePhotoUrl(session?.userId ?? 'anon');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _uploadingPhoto = false;
      });
      showAppSnackBar(context, 'No se pudo subir la foto. Intenta de nuevo.');
      return;
    }
    if (!mounted) return;
    setState(() => _uploadingPhoto = false);

    final result =
        await ref.read(authControllerProvider.notifier).completeRegistration(
              RegistrationData(
                email: widget.email,
                name: _name.text.trim(),
                gender: _gender,
                career: _career,
                semester: int.tryParse(_semester.text.trim()),
                studentCarnet:
                    _carnet.text.trim().isEmpty ? null : _carnet.text.trim(),
                biography: _biography.text.trim().isEmpty
                    ? null
                    : _biography.text.trim(),
                photoUrl: photoUrl,
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
              validator: (v) => Validators.required(v, 'El nombre'),
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
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _career,
              decoration: const InputDecoration(labelText: 'Carrera'),
              isExpanded: true,
              items: [
                for (final c in careers)
                  DropdownMenuItem(value: c, child: Text(careerLabel(c))),
              ],
              onChanged: (v) => setState(() => _career = v),
              validator: (v) => v == null ? 'Elige tu carrera.' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Semestre',
                    controller: _semester,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.next,
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
                      if (v == null || v.trim().isEmpty) return null;
                      return v.trim().length == 10
                          ? null
                          : 'Debe tener exactamente 10 dígitos.';
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDateOfBirth,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de nacimiento',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _dateOfBirth == null
                      ? 'Toca para elegir'
                      : DateFormat('d MMM yyyy').format(_dateOfBirth!),
                  style: _dateOfBirth == null
                      ? theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)
                      : theme.textTheme.bodyMedium,
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
              label: _uploadingPhoto ? 'Subiendo foto…' : 'Finalizar registro',
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
