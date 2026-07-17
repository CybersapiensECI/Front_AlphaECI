import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_layout.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final email = _email.text.trim();
    final password = _password.text;
    final result = await ref
        .read(authControllerProvider.notifier)
        .initVerification(email: email, password: password);
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (message) {
        showAppSnackBar(context, message);
        // El OTP screen necesita email (verify) y password (resend).
        context.push(Routes.otp, extra: {'email': email, 'password': password});
      },
      error: (failure) => showAppSnackBar(context, failure.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Crear cuenta',
      subtitle: 'Te enviaremos un código de verificación a tu correo.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Correo institucional',
              controller: _email,
              validator: Validators.email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Contraseña',
              controller: _password,
              validator: Validators.password,
              obscure: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Confirmar contraseña',
              controller: _confirm,
              obscure: true,
              validator: (value) =>
                  value != _password.text ? 'Las contraseñas no coinciden.' : null,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Enviar código',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Ya tengo cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
