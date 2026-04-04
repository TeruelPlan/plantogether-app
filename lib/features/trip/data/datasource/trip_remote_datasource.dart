import '../../../../core/network/dio_client.dart';
import '../dto/trip_dto.dart';
import '../dto/trip_invitation_dto.dart';
import '../dto/trip_preview_dto.dart';

class TripRemoteDatasource {
  final DioClient _dioClient;

  TripRemoteDatasource(this._dioClient);

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

  Future<TripInvitationDto> getInvitation(String tripId) async {
    final response = await _dioClient.dio.get(
      '/api/v1/trips/$tripId/invitation',
    );
    return TripInvitationDto.fromJson(response.data);
  }

  Future<TripPreviewDto> getTripPreview(String tripId, String token) async {
    final response = await _dioClient.dio.get(
      '/api/v1/trips/$tripId/preview',
      queryParameters: {'token': token},
    );
    return TripPreviewDto.fromJson(response.data);
  }

  Future<TripDto> joinTrip(String tripId, String token) async {
    final response = await _dioClient.dio.post(
      '/api/v1/trips/$tripId/join',
      data: {'token': token},
    );
    return TripDto.fromJson(response.data);
  }
}
