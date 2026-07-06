import 'failures.dart';

/// Resultado de una operación: éxito con dato o fallo tipado.
/// Los repositories devuelven siempre Result<T> — nunca lanzan excepciones
/// hacia la capa de presentación.
sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) error,
  }) {
    final self = this;
    return switch (self) {
      Success<T>() => success(self.data),
      Error<T>() => error(self.failure),
    };
  }

  bool get isSuccess => this is Success<T>;

  T? get dataOrNull => switch (this) {
        Success<T>(data: final d) => d,
        Error<T>() => null,
      };

  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        Error<T>(failure: final f) => f,
      };
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class Error<T> extends Result<T> {
  const Error(this.failure);
  final Failure failure;
}
