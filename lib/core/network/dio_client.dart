import 'package:dio/dio.dart';
import '../security/auth_service.dart';

class DioClient {
  late final Dio _dio;
  final AuthService _authService;

  DioClient(this._authService) {
    _dio = Dio(BaseOptions(
      baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8080'),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getAccessToken();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
    ));
  }

  Dio get dio => _dio;
}
