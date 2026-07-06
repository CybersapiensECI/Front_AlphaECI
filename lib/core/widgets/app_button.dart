import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Botón principal premium: gradiente de marca, glow suave,
/// microinteracción de press (escala) y estado de carga integrado.
/// Misma API de siempre: label, onPressed, loading, icon.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: _enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          duration: AppDurations.fast,
          opacity: _enabled || widget.loading ? 1 : 0.5,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: AppGradients.buttonOf(context),
              borderRadius: BorderRadius.circular(AppRadii.md),
              boxShadow: _enabled ? AppShadows.glow(scheme.primary) : null,
            ),
            child: Center(
              child: widget.loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 20, color: Colors.white),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
