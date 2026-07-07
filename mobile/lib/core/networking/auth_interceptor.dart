import 'package:dio/dio.dart';

/// Supplies the current access JWT; the real implementation lives in
/// core/session (vault-backed refresh token, DPoP-style device binding —
/// 09-mobile-architecture.md §5.3). Stubbed for the skeleton.
abstract interface class TokenProvider {
  /// Returns a valid access token, refreshing if expired; null when signed out.
  Future<String?> accessToken();
}

/// Skeleton token provider: always signed out.
class StubTokenProvider implements TokenProvider {
  const StubTokenProvider();

  @override
  Future<String?> accessToken() async => null;
}

/// Auth interceptor stub (09 core/networking):
/// - attaches `Authorization: Bearer <jwt>`;
/// - real version adds single-flight refresh on 401 + DPoP proof headers.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokens);

  final TokenProvider _tokens;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokens.accessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
