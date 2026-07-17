import 'package:flutter/material.dart';

/// Campo de texto estándar de la app (estilos vienen del InputDecorationTheme).
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscure = false,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscure;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final void Function(String)? onSubmitted;
  final int maxLines;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      obscureText: _obscured,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onFieldSubmitted: widget.onSubmitted,
      maxLines: widget.obscure ? 1 : widget.maxLines,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(
                  _obscured ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
      ),
    );
  }
}
