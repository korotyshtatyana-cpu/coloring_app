/// Result type representing either a successful value or a failure message.
sealed class Result<T> {
  /// Base constructor for [Result].
  const Result();
}

/// Successful result containing a value of type [T].
final class Success<T> extends Result<T> {
  /// The success value.
  final T data;

  /// Creates a success result with the given [data].
  const Success(this.data);
}

/// Failure result containing an error message and optional raw error.
final class Failure<T> extends Result<T> {
  /// Human-readable error message.
  final String message;

  /// Optional raw error object.
  final dynamic error;

  /// Creates a failure result with the given [message] and optional [error].
  const Failure(this.message, {this.error});
}
