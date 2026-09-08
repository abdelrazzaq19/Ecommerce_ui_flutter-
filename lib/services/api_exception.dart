/// What went wrong when talking to the store API.
///
/// The kind drives what the UI offers the user: a timeout or network failure is
/// worth a Retry button, a decoding failure is not the user's problem to retry.
enum ApiErrorKind { network, timeout, server, decoding }

/// A failure from the store API, carrying a message safe to show a shopper.
///
/// Every network path in the app throws this and nothing else, so callers never
/// have to guess between `SocketException`, `TimeoutException`, `FormatException`
/// and a raw `Exception('Failed to load products')`.
class ApiException implements Exception {
  const ApiException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.cause,
  });

  factory ApiException.timeout() => const ApiException(
        kind: ApiErrorKind.timeout,
        message: 'The store took too long to respond. '
            'Check your connection and try again.',
      );

  factory ApiException.server(int statusCode) => ApiException(
        kind: ApiErrorKind.server,
        statusCode: statusCode,
        message: 'The store is unavailable right now '
            '(error $statusCode). Please try again shortly.',
      );

  factory ApiException.decoding([Object? cause]) => ApiException(
        kind: ApiErrorKind.decoding,
        cause: cause,
        message: 'The store sent data this app could not read. '
            'Please try again later.',
      );

  factory ApiException.network([Object? cause]) => ApiException(
        kind: ApiErrorKind.network,
        cause: cause,
        message: 'Could not reach the store. '
            'Check your internet connection and try again.',
      );

  final ApiErrorKind kind;

  /// User-facing text. Safe to render directly in an error state.
  final String message;

  /// HTTP status, when the failure came from a response.
  final int? statusCode;

  /// The underlying error, kept for logs — never shown to the user.
  final Object? cause;

  /// Whether offering the user a Retry button makes sense.
  bool get isRetryable =>
      kind == ApiErrorKind.timeout ||
      kind == ApiErrorKind.network ||
      kind == ApiErrorKind.server;

  @override
  String toString() => 'ApiException(${kind.name}, $message)';
}
