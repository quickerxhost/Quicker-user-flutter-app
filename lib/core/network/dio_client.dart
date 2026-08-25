import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import 'api_endpoints.dart';
import 'network_exceptions.dart';

/// Wraps a configured [Dio] instance with:
/// - JWT bearer-token injection
/// - automatic access-token refresh on 401 (single retry)
/// - capped retry on transient/timeout failures
/// - request/response logging (dev only, see [AppConfig.enableNetworkLogs])
///
/// [AppConfig.baseUrl] and [ApiEndpoints.refreshToken] are currently blank —
/// this client is fully wired and will start working the moment those are
/// filled in.
class DioClient {
  DioClient(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        contentType: 'application/json',
      ),
    );

    _dio.interceptors.addAll([
      _authInterceptor(),
      _retryInterceptor(),
      if (AppConfig.enableNetworkLogs)
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          error: true,
          compact: true,
        ),
    ]);
  }

  late final Dio _dio;
  final SecureStorageService _secureStorage;
  bool _isRefreshing = false;

  Dio get instance => _dio;

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isUnauthorized = error.response?.statusCode == 401;
        final canRefresh = ApiEndpoints.refreshToken.isNotEmpty;

        if (isUnauthorized && canRefresh && !_isRefreshing) {
          _isRefreshing = true;
          try {
            final refreshToken = await _secureStorage.refreshToken;
            if (refreshToken == null) {
              _isRefreshing = false;
              return handler.next(error);
            }

            final refreshDio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
            final response = await refreshDio.post(
              ApiEndpoints.refreshToken,
              data: {'refreshToken': refreshToken},
            );

            final newAccessToken = response.data['access_token'] as String?;
            final newRefreshToken = response.data['refresh_token'] as String?;
            if (newAccessToken != null) {
              await _secureStorage.saveAccessToken(newAccessToken);
            }
            if (newRefreshToken != null) {
              await _secureStorage.saveRefreshToken(newRefreshToken);
            }

            // Retry the original request with the new token.
            final retryOptions = error.requestOptions;
            retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            final retryResponse = await _dio.fetch(retryOptions);
            _isRefreshing = false;
            return handler.resolve(retryResponse);
          } catch (_) {
            _isRefreshing = false;
            await _secureStorage.clearSession();
            return handler.next(error);
          }
        }

        handler.next(error);
      },
    );
  }

  InterceptorsWrapper _retryInterceptor({int maxRetries = 2}) {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        final requestOptions = error.requestOptions;
        final retryCount = (requestOptions.extra['retry_count'] as int?) ?? 0;

        final isRetryable = error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.connectionError;

        if (isRetryable && retryCount < maxRetries) {
          requestOptions.extra['retry_count'] = retryCount + 1;
          await Future.delayed(Duration(milliseconds: 400 * (retryCount + 1)));
          try {
            final response = await _dio.fetch(requestOptions);
            return handler.resolve(response);
          } catch (_) {
            // Fall through to propagate the original error.
          }
        }
        handler.next(error);
      },
    );
  }

  /// Runs [request] and maps any [DioException] to a typed [NetworkException],
  /// so repositories never deal with Dio directly.
  Future<T> guard<T>(Future<T> Function(Dio dio) request) async {
    try {
      return await request(_dio);
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    }
  }
}
