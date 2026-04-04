import 'package:dio/dio.dart';
import '../security/device_id_service.dart';

class DioClient {
  late final Dio _dio;
  final DeviceIdService _deviceIdService;

  DioClient(this._deviceIdService) {
    _dio = Dio(BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://127.0.0.1:8081',
      ),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final deviceId = await _deviceIdService.getOrCreateDeviceId();
        options.headers['X-Device-Id'] = deviceId;
        handler.next(options);
      },
    ));
  }

  Dio get dio => _dio;
}
