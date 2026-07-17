import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/failures.dart';
import 'error_view.dart';

/// Renderiza un `AsyncValue<T>` de Riverpod con loading/error/data uniforme.
/// Evita repetir el mismo switch en cada pantalla.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
    this.errorBuilder,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  /// Widget de carga custom (ej. SkeletonList). Default: spinner.
  final Widget? loading;

  /// Override del error por defecto (ej. registro incompleto -> botón para
  /// terminarlo en vez del ErrorView genérico con "Reintentar"). Devolver
  /// null para casos no manejados: cae al ErrorView por defecto.
  final Widget? Function(Failure error)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () =>
          loading ?? const Center(child: CircularProgressIndicator()),
      error: (error, _) {
        final failure =
            error is Failure ? error : const UnknownFailure();
        final custom = errorBuilder?.call(failure);
        if (custom != null) return custom;
        return ErrorView(message: failure.message, onRetry: onRetry);
      },
      data: data,
    );
  }
}
