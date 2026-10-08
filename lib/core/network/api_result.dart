import 'network_exceptions.dart';

/// Lightweight Result type so repositories never throw across layers —
/// the presentation layer always pattern-matches on [ApiResult].
sealed class ApiResult<T> {
  const ApiResult();

  const factory ApiResult.success(T data) = ApiSuccess<T>;
  const factory ApiResult.failure(NetworkException error) = ApiFailure<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(NetworkException error) failure,
  }) {
    final self = this;
    if (self is ApiSuccess<T>) return success(self.data);
    if (self is ApiFailure<T>) return failure(self.error);
    throw StateError('Unreachable');
  }
}

final class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiSuccess(this.data);
}

final class ApiFailure<T> extends ApiResult<T> {
  final NetworkException error;
  const ApiFailure(this.error);
}
