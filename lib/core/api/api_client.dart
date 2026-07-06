import 'dart:io';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../error/exceptions.dart';

class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<T>(
        '${AppConfig.baseUrl}$path',
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Failure(e.toString());
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<T>(
        '${AppConfig.baseUrl}$path',
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Failure(e.toString());
    }
  }

  Future<Response<T>> postMultipart<T>(
    String path, {
    required Map<String, dynamic> data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final formData = FormData.fromMap(data);
      final response = await _dio.post<T>(
        '${AppConfig.baseUrl}$path',
        data: formData,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Failure(e.toString());
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch<T>(
        '${AppConfig.baseUrl}$path',
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Failure(e.toString());
    }
  }

  Failure _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.error is SocketException) {
      return const NetworkFailure('No internet connection. Please check your network.');
    }

    final response = error.response;
    if (response != null) {
      final statusCode = response.statusCode;
      final data = response.data;
      String message = 'Something went wrong';
      
      if (data is Map) {
        message = data['message'] ?? data['error'] ?? message;
        
        // Laravel validation errors format: { "message": "...", "errors": { "field": ["err1"] } }
        if (statusCode == 422 && data['errors'] is Map) {
          final validationErrors = <String, List<String>>{};
          (data['errors'] as Map).forEach((key, value) {
            if (value is List) {
              validationErrors[key] = value.map((e) => e.toString()).toList();
            } else if (value is String) {
              validationErrors[key] = [value];
            }
          });
          return ValidationFailure(message, statusCode: statusCode, errors: validationErrors);
        }
      }

      if (statusCode == 401 || statusCode == 403) {
        return AuthFailure(message, statusCode: statusCode);
      }

      return ServerFailure(message, statusCode: statusCode);
    }

    return const Failure('An unexpected error occurred');
  }
}
