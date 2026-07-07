import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/networking/problem_details.dart';

/// Remote source stub — will wrap the generated `trustos_api` ReferralsApi.
/// Maps RFC 9457 problems to the [AppException] taxonomy at this boundary;
/// nothing above ever sees a DioException (09 §2.1).
class ReferralRemoteSource {
  ReferralRemoteSource(this._dio);

  final Dio _dio;

  /// POST /v1/referrals with the client-minted id as `Idempotency-Key` —
  /// retries after a lost response are exact replays (shared-context §5).
  Future<Map<String, dynamic>> submit(
    Map<String, dynamic> createRequest, {
    required String idempotencyKey,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/referrals',
        data: createRequest,
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      );
      return response.data ?? const {};
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
