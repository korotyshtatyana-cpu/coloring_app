/// Synchronous use case interface.
abstract class UseCase<Input, Output> {
  /// Executes the use case with optional [params].
  Output execute([Input? params]);
}

/// Asynchronous use case interface.
abstract class FutureUseCase<Input, Output> {
  /// Executes the use case asynchronously with optional [params].
  Future<Output> execute([Input? params]);
}

/// Stream-based use case interface.
abstract class StreamUseCase<Input, Output> {
  /// Executes the use case returning a stream with optional [params].
  Stream<Output> execute([Input? params]);
}

/// Placeholder class for use cases that do not require parameters.
class NoParams {
  /// Creates a [NoParams] instance.
  const NoParams();
}
