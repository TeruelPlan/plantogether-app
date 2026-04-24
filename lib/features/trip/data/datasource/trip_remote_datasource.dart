import '../../../../core/network/dio_client.dart';
import '../dto/trip_dto.dart';
import '../dto/trip_invitation_dto.dart';
import '../dto/trip_member_dto.dart';
import '../dto/trip_preview_dto.dart';

class TripRemoteDatasource {
  final DioClient _dioClient;

  TripRemoteDatasource(this._dioClient);

  Future<List<TripDto>> listTrips() async {
    final response = await _dioClient.dio.get('/api/v1/trips');
    return (response.data as List)
        .map((json) => TripDto.fromJson(json))
        .toList();
  }

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
        'description': ?description,
        'currency': ?currency,
      },
    );
    return TripDto.fromJson(response.data);
  }

  Future<TripDto> updateTrip(
    String tripId, {
    required String title,
    String? description,
    String? currency,
  }) async {
    final response = await _dioClient.dio.put(
      '/api/v1/trips/$tripId',
      data: {
        'title': title,
        'description': description ?? '',
        'referenceCurrency': ?currency,
      },
    );
    return TripDto.fromJson(response.data);
  }

  Future<TripDto> archiveTrip(String tripId) async {
    final response = await _dioClient.dio.patch(
      '/api/v1/trips/$tripId/archive',
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

  Future<List<TripMemberDto>> getMembers(String tripId) async {
    final response = await _dioClient.dio.get('/api/v1/trips/$tripId/members');
    return (response.data as List)
        .map((json) => TripMemberDto.fromJson(json))
        .toList();
  }

  Future<void> removeMember(String tripId, String memberId) async {
    await _dioClient.dio.delete('/api/v1/trips/$tripId/members/$memberId');
  }
}
