import 'package:dio/dio.dart';

import '../errors/app_exception.dart';

/// RFC 9457 Problem Details parsing + mapping to the sealed [AppException]
/// taxonomy (shared-context §5: "Errors: RFC 9457 Problem Details JSON
/// everywhere").
class ProblemDetails {
  const ProblemDetails({
    required this.type,
    required this.title,
    required this.status,
    this.detail = '',
  });

  factory ProblemDetails.fromJson(Map<String, dynamic> json) => ProblemDetails(
        type: json['type'] as String? ?? 'about:blank',
        title: json['title'] as String? ?? 'Unknown problem',
        status: json['status'] as int? ?? 0,
        detail: json['detail'] as String? ?? '',
      );

  final String type;
  final String title;
  final int status;
  final String detail;
}

/// Maps any [DioException] to an [AppException]. The single choke point:
/// nothing above the data layer ever sees a DioException.
AppException mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const TimeoutException();
    case DioExceptionType.connectionError:
      return const NetworkUnavailableException();
    case DioExceptionType.badResponse:
      final response = e.response;
      if (response == null) return UnknownException(e.message ?? 'No response');
      if (response.statusCode == 401) return const UnauthorizedException();
      final problem = _problemFrom(response);
      return ApiProblemException(
        type: problem.type,
        status: response.statusCode ?? problem.status,
        detail: problem.detail.isEmpty ? problem.title : problem.detail,
        retryAfter: _retryAfterFrom(response),
      );
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return UnknownException(e.message ?? 'Unknown network error');
  }
}

ProblemDetails _problemFrom(Response<dynamic> response) {
  final data = response.data;
  if (data is Map<String, dynamic>) return ProblemDetails.fromJson(data);
  return ProblemDetails(
    type: 'about:blank',
    title: response.statusMessage ?? 'HTTP ${response.statusCode}',
    status: response.statusCode ?? 0,
  );
}

Duration? _retryAfterFrom(Response<dynamic> response) {
  final header = response.headers.value('retry-after');
  if (header == null) return null;
  final seconds = int.tryParse(header);
  return seconds == null ? null : Duration(seconds: seconds);
}
