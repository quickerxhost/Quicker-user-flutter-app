import 'package:dio/dio.dart';

/// Normalized failure type surfaced to the UI layer. Screens should switch
/// on [type], not on raw Dio/HTTP details.
enum NetworkFailureType {
  noInternet,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  server,
  cancelled,
  unknown,
}

class NetworkException implements Exception {
  final NetworkFailureType type;
  final String message;
  final int? statusCode;
  final Map<String, List<String>>? fieldErrors;

  const NetworkException({
    required this.type,
    required this.message,
    this.statusCode,
    this.fieldErrors,
  });

  factory NetworkException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
        return const NetworkException(
          type: NetworkFailureType.noInternet,
          message: 'No internet connection. Please check your network and try again.',
        );
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          type: NetworkFailureType.timeout,
          message: 'The request timed out. Please try again.',
        );
      case DioExceptionType.cancel:
        return const NetworkException(
          type: NetworkFailureType.cancelled,
          message: 'Request was cancelled.',
        );
      case DioExceptionType.badResponse:
        return _fromStatusCode(e);
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return NetworkException(
          type: NetworkFailureType.unknown,
          message: e.message ?? 'Something went wrong. Please try again.',
        );
      default:
        // Covers any DioExceptionType values added in newer Dio releases
        // (e.g. transformTimeout) without requiring an app update just to
        // keep this switch exhaustive.
        return NetworkException(
          type: NetworkFailureType.unknown,
          message: e.message ?? 'Something went wrong. Please try again.',
        );
    }
  }

  static NetworkException _fromStatusCode(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String message = 'Something went wrong. Please try again.';
    Map<String, List<String>>? fieldErrors;

    if (data is Map) {
      if (data['message'] is String) message = data['message'] as String;
      final errors = data['errors'];
      if (errors is Map) {
        fieldErrors = errors.map(
          (key, value) => MapEntry(
            key.toString(),
            (value is List) ? value.map((v) => v.toString()).toList() : [value.toString()],
          ),
        );
      }
    }

    switch (status) {
      case 400:
        return NetworkException(
          type: NetworkFailureType.validation,
          message: message,
          statusCode: status,
          fieldErrors: fieldErrors,
        );
      case 401:
        return NetworkException(
          type: NetworkFailureType.unauthorized,
          message: 'Your session has expired. Please log in again.',
          statusCode: status,
        );
      case 403:
        return NetworkException(
          type: NetworkFailureType.forbidden,
          message: message,
          statusCode: status,
        );
      case 404:
        return NetworkException(
          type: NetworkFailureType.notFound,
          message: message,
          statusCode: status,
        );
      default:
        if (status != null && status >= 500) {
          return NetworkException(
            type: NetworkFailureType.server,
            message: 'Our servers are having trouble. Please try again shortly.',
            statusCode: status,
          );
        }
        return NetworkException(
          type: NetworkFailureType.unknown,
          message: message,
          statusCode: status,
          fieldErrors: fieldErrors,
        );
    }
  }

  @override
  String toString() => 'NetworkException($type, $message)';
}
