import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await ref.read(authControllerProvider.notifier).login(
          email: _email.text.trim(),
          password: _password.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    // Éxito: el redirect del router lleva a /home automáticamente.
    final failure = result.failureOrNull;
    if (failure != null) showAppSnackBar(context, failure.message);
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'AlphaECI',
      subtitle: 'Conexiones auténticas. Diseño que conecta.',
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Correo institucional',
                controller: _email,
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Contraseña',
                controller: _password,
                validator: Validators.password,
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(Routes.forgotPassword),
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Iniciar sesión',
                loading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push(Routes.register),
                child: const Text('¿No tienes cuenta? Regístrate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
