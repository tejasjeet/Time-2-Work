import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import '../storage/local_store.dart';
import 'api_exception.dart';

final localStoreProvider = Provider<LocalStore>((ref) => LocalStore());

final apiBaseProvider = StateProvider<String>((ref) => ApiConstants.defaultBaseUrl());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref);
});

class ApiClient {
  ApiClient(this._ref) {
    _dio = Dio(
      BaseOptions(
        baseUrl: _ref.read(apiBaseProvider),
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.baseUrl = _ref.read(apiBaseProvider);
          final token = await _ref.read(localStoreProvider).getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  final Ref _ref;
  late final Dio _dio;

  Dio get dio => _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    return _send(() => _dio.get(path, queryParameters: query));
  }

  Future<dynamic> post(String path, {Object? data, Map<String, dynamic>? query}) async {
    return _send(() => _dio.post(path, data: data, queryParameters: query));
  }

  Future<dynamic> postMultipart(String path, FormData data) async {
    return _send(
      () => _dio.post(
        path,
        data: data,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      ),
    );
  }

  Future<dynamic> patch(String path, {Object? data}) async {
    return _send(() => _dio.patch(path, data: data));
  }

  Future<dynamic> put(String path, {Object? data}) async {
    return _send(() => _dio.put(path, data: data));
  }

  Future<dynamic> delete(String path) async {
    return _send(() => _dio.delete(path));
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() call) async {
    try {
      final res = await call();
      return res.data;
    } on DioException catch (e) {
      throw ApiException(_messageOf(e), statusCode: e.response?.statusCode);
    }
  }

  String _messageOf(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      if (data['error'] is Map) {
        final nested = data['error'] as Map;
        if (nested['message'] != null) return nested['message'].toString();
      }
      for (final key in ['message', 'error', 'msg']) {
        if (data[key] != null && data[key] is! Map) return data[key].toString();
      }
    }
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
      return 'No internet or app service unavailable. Check your connection and try again.';
    }
    return e.message ?? 'Something went wrong';
  }
}
