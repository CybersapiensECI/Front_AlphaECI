import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_layout.dart';

/// Verificación OTP. Recibe por extra: {email, password}.
/// verify-otp devuelve tokens: al validar, el usuario queda autenticado
/// y se lo lleva a completar su perfil.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.email, required this.password});

  final String email;
  final String password;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _loading = false;
  bool _resending = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await ref.read(authControllerProvider.notifier).verifyOtp(
          email: widget.email,
          code: _code.text.trim(),
        );
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (_) => context.go(Routes.completeProfile, extra: widget.email),
      error: (failure) => showAppSnackBar(context, failure.message),
    );
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    final result = await ref.read(authControllerProvider.notifier).resendOtp(
          email: widget.email,
          password: widget.password,
        );
    if (!mounted) return;
    setState(() => _resending = false);
    showAppSnackBar(
      context,
      result.when(success: (m) => m, error: (f) => f.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Verifica tu correo',
      subtitle: 'Ingresa el código enviado a ${widget.email}.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Código de verificación',
              controller: _code,
              validator: Validators.otp,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Verificar',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _resending ? null : _resend,
              child: Text(_resending ? 'Enviando…' : 'Reenviar código'),
            ),
          ],
        ),
      ),
    );
  }
}
