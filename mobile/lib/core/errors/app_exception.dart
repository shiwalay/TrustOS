/// AppException taxonomy (09-mobile-architecture.md core/errors).
///
/// Sealed so every handler exhaustively distinguishes terminal vs retryable
/// (10-ux-design.md §7 error standards). RFC 9457 problems map into
/// [ApiProblemException] via `core/networking/problem_details.dart`.
sealed class AppException implements Exception {
  const AppException(this.message, {required this.retryable});

  /// Developer-facing message; user copy comes from l10n keys, never this.
  final String message;

  /// Retryable → inline retry + backoff; terminal → plain-language reason.
  final bool retryable;

  @override
  String toString() => '$runtimeType: $message';
}

/// No connectivity / DNS / socket-level failure. Always retryable.
final class NetworkUnavailableException extends AppException {
  const NetworkUnavailableException([super.message = 'Network unavailable'])
      : super(retryable: true);
}

/// Request timed out (connect/send/receive).
final class TimeoutException extends AppException {
  const TimeoutException([super.message = 'Request timed out'])
      : super(retryable: true);
}

/// Session invalid — triggers re-auth flow, never a naked error card.
final class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Not authenticated'])
      : super(retryable: false);
}

/// Server answered with an RFC 9457 Problem Details body.
final class ApiProblemException extends AppException {
  const ApiProblemException({
    required this.type,
    required this.status,
    required String detail,
    this.retryAfter,
  }) : super(detail, retryable: !(status >= 400 && status < 500) || status == 429);

  /// Problem `type` URI — the machine-readable error class (e.g.
  /// `https://trustos.app/problems/referral-ineligible`).
  final String type;
  final int status;

  /// Honored by the sync-engine backoff (09 §4.3).
  final Duration? retryAfter;

  /// Terminal problems (422 ineligible / 409 duplicate / campaign closed)
  /// trigger the compensating rollback path (09 §3.4).
  bool get isTerminal => !retryable;
}

/// Domain validation failed before anything was written.
final class ValidationException extends AppException {
  const ValidationException(this.code)
      : super('Validation failed: $code', retryable: false);

  /// Stable code, used as an l10n key suffix (e.g. `consent_required`).
  final String code;
}

/// Local persistence failure (Drift/SQLCipher).
final class StorageException extends AppException {
  const StorageException(super.message) : super(retryable: false);
}

/// Anything unmapped — reported to Sentry, shown as generic retryable.
final class UnknownException extends AppException {
  const UnknownException(super.message) : super(retryable: true);
}
