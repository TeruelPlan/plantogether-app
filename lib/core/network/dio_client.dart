import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../security/device_id_service.dart';

class DioClient {
  late final Dio _dio;
  final DeviceIdService _deviceIdService;

  DioClient(this._deviceIdService) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
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
