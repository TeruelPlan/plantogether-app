import '../../../../core/network/dio_client.dart';
import '../dto/destination_dto.dart';

class DestinationRemoteDatasource {
  final DioClient _dioClient;

  DestinationRemoteDatasource(this._dioClient);

  Future<List<DestinationDto>> list(String tripId) async {
    final response = await _dioClient.dio.get('/api/v1/trips/$tripId/destinations');
    return (response.data as List)
        .map((json) => DestinationDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<DestinationDto> propose(
    String tripId,
    ProposeDestinationRequestDto body,
  ) async {
    final response = await _dioClient.dio.post(
      '/api/v1/trips/$tripId/destinations',
      data: body.toJson(),
    );
    return DestinationDto.fromJson(response.data as Map<String, dynamic>);
  }
}
