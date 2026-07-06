import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/breakpoints.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/async_value_view.dart';
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

    return Scaffold(
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
