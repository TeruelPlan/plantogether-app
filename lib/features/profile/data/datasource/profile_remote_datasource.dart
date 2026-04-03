import 'package:plantogether_app/core/network/dio_client.dart';
import 'package:plantogether_app/features/profile/data/dto/user_profile_dto.dart';

class ProfileRemoteDatasource {
  final DioClient _dioClient;

  ProfileRemoteDatasource(this._dioClient);

  Future<UserProfileDto> getMyProfile() async {
    final response = await _dioClient.dio.get('/api/v1/users/me');
    return UserProfileDto.fromJson(response.data);
  }

  Future<UserProfileDto> updateMyProfile(String displayName) async {
    final response = await _dioClient.dio.put(
      '/api/v1/users/me',
      data: {'displayName': displayName},
    );
    return UserProfileDto.fromJson(response.data);
  }
}
