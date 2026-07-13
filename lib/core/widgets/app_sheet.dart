import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Contenedor ESTÁNDAR para todos los bottom sheets de la app:
/// dos tercios de la pantalla (los constraints del modal lo encogen solo
/// cuando el teclado no deja espacio), superficie con radio XL, borde
/// sutil, drag handle y padding uniforme.
///
/// Abrir siempre con [showAppSheet] — así cualquier sheet nuevo queda
/// automáticamente igual a los demás.
class AppSheet extends StatelessWidget {
  const AppSheet({super.key, required this.child});

  /// Contenido del sheet. Recibe el alto completo: estructura típica
  /// `Column[... Expanded(lista/scroll) ..., acciones fijas]`.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: MediaQuery.of(context).size.height * 2 / 3,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.xl),
        ),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outline.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// Abre un [AppSheet] modal (sube con el teclado).
Future<T?> showAppSheet<T>(BuildContext context, {required Widget child}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: AppSheet(child: child),
    ),
  );
}
