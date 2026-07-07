import 'package:dio/dio.dart';

import 'auth_interceptor.dart';

/// Dio builder (09-mobile-architecture.md core/networking).
///
/// Takes primitives, not the FlavorConfig, so core/ never imports app/
/// (dependencies point inward). Cert pinning (§5.4) and RateLimit-* header
/// backoff attach here in later milestones.
Dio buildDio({required String baseUrl, required TokenProvider tokens}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(AuthInterceptor(tokens));
  return dio;
}
