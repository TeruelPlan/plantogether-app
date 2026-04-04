import '../../../../core/network/dio_client.dart';
import '../dto/trip_dto.dart';

class TripRemoteDatasource {
  final DioClient _dioClient;

  TripRemoteDatasource(this._dioClient);

  Future<TripDto> getTrip(String tripId) async {
    final response = await _dioClient.dio.get('/api/v1/trips/$tripId');
    return TripDto.fromJson(response.data);
  }

  Future<TripDto> createTrip({
    required String title,
    String? description,
    String? currency,
  }) async {
    final response = await _dioClient.dio.post(
      '/api/v1/trips',
      data: {
        'title': title,
        if (description != null) 'description': description,
        if (currency != null) 'currency': currency,
      },
    );
    return TripDto.fromJson(response.data);
  }
}
