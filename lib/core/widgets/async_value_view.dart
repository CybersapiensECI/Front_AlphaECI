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
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  /// Widget de carga custom (ej. SkeletonList). Default: spinner.
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () =>
          loading ?? const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(
        message: error is Failure ? error.message : 'Error inesperado.',
        onRetry: onRetry,
      ),
      data: data,
    );
  }
}
