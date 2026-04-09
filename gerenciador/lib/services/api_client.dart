import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../models/pagination.dart';

class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await _dio.get<dynamic>(path, queryParameters: query);
      return response.data;
    } on DioException catch (error) {
      throw ApiException(_parseError(error));
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<dynamic>(path, data: jsonEncode(body));
      return response.data;
    } on DioException catch (error) {
      throw ApiException(_parseError(error));
    }
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch<dynamic>(path, data: jsonEncode(body));
      return response.data;
    } on DioException catch (error) {
      throw ApiException(_parseError(error));
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete<dynamic>(path);
    } on DioException catch (error) {
      throw ApiException(_parseError(error));
    }
  }

  PaginatedResponse<T> toPaginated<T>(
    dynamic data,
    T Function(Map<String, dynamic>) mapper,
  ) {
    final map = data as Map<String, dynamic>;
    final list = ((map['data'] ?? const []) as List)
        .map((raw) => mapper(raw as Map<String, dynamic>))
        .toList();

    return PaginatedResponse<T>(
      data: list,
      pagination: PaginationMeta.fromJson(map['pagination'] as Map<String, dynamic>),
    );
  }

  String _parseError(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'];
      if (message is String) {
        return message;
      }

      if (message is List) {
        return message.join(', ');
      }
    }

    if (error.message != null && error.message!.trim().isNotEmpty) {
      return error.message!;
    }

    return 'Request failed';
  }
}
