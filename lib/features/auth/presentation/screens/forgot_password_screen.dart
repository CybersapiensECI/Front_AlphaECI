import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_layout.dart';

/// Recuperación en dos pasos sobre la misma pantalla:
/// 1) POST /forgot-password (envía código al correo)
/// 2) POST /reset-password {email, code, newPassword}
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _newPassword = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final controller = ref.read(authControllerProvider.notifier);

    if (!_codeSent) {
      final result =
          await controller.forgotPassword(email: _email.text.trim());
      if (!mounted) return;
      setState(() => _loading = false);
      result.when(
        success: (message) {
          setState(() => _codeSent = true);
          showAppSnackBar(context, message);
        },
        error: (failure) => showAppSnackBar(context, failure.message),
      );
      return;
    }

    final result = await controller.resetPassword(
      email: _email.text.trim(),
      code: _code.text.trim(),
      newPassword: _newPassword.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (message) {
        showAppSnackBar(context, message);
        context.pop();
      },
      error: (failure) => showAppSnackBar(context, failure.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Recuperar contraseña',
      subtitle: _codeSent
          ? 'Ingresa el código que llegó a tu correo y tu nueva contraseña.'
          : 'Te enviaremos un código de recuperación.',
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
            if (_codeSent) ...[
              const SizedBox(height: 16),
              AppTextField(
                label: 'Código',
                controller: _code,
                validator: Validators.otp,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Nueva contraseña',
                controller: _newPassword,
                validator: Validators.password,
                obscure: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
            ],
            const SizedBox(height: 24),
            AppButton(
              label: _codeSent ? 'Restablecer contraseña' : 'Enviar código',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
