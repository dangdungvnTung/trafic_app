import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import '../../routes/app_pages.dart';
import '../../services/storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  final StorageService _storageService = Get.find<StorageService>();

  ApiService._internal() {
    final baseUrl = dotenv.env['BASE_URL'] ?? '';
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _storageService.getToken();
          final isAuthEndpoint =
              options.path.contains('/auth/login') ||
              options.path.contains('/auth/register');
          if (token != null && token.isNotEmpty && !isAuthEndpoint) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Try to login again
            final credentials = _storageService.getCredentials();
            if (credentials != null) {
              try {
                // Prevent infinite loop if login itself fails
                if (e.requestOptions.path.contains('/auth/login')) {
                  _storageService.removeToken();
                  _storageService.clearCredentials();
                  if (Get.context != null) {
                    Get.offAllNamed(Routes.LOGIN);
                  }
                  return handler.next(e);
                }

                final response = await _dio.post(
                  '/auth/login',
                  data: {
                    'username': credentials['username'],
                    'password': credentials['password'],
                  },
                );

                if (response.data['success'] == true &&
                    response.data['data'] != null) {
                  final newToken = response.data['data'];
                  setToken(newToken);

                  // Retry original request
                  final opts = e.requestOptions;
                  opts.headers['Authorization'] = 'Bearer $newToken';

                  final clonedRequest = await _dio.request(
                    opts.path,
                    options: Options(
                      method: opts.method,
                      headers: opts.headers,
                      contentType: opts.contentType,
                      responseType: opts.responseType,
                    ),
                    data: opts.data,
                    queryParameters: opts.queryParameters,
                  );

                  return handler.resolve(clonedRequest);
                }
              } catch (loginError) {
                // Login failed, proceed to logout
              }
            }

            // Token expired or invalid and auto-login failed
            _storageService.removeToken();
            _storageService.clearCredentials();
            if (Get.context != null) {
              Get.offAllNamed(Routes.LOGIN);
            }
            // Get.snackbar('Phiên đăng nhập hết hạn', 'Vui lòng đăng nhập lại');
          }
          return handler.next(e);
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  void setToken(String token) {
    _storageService.setToken(token);
  }

  void clearToken() {
    _storageService.removeToken();
  }

  Dio get dio => _dio;
}
