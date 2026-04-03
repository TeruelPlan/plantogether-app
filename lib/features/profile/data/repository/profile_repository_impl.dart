import 'package:plantogether_app/features/profile/data/datasource/profile_remote_datasource.dart';
import 'package:plantogether_app/features/profile/domain/model/user_profile.dart';
import 'package:plantogether_app/features/profile/domain/repository/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource _remoteDatasource;

  ProfileRepositoryImpl(this._remoteDatasource);

  @override
  Future<UserProfile> getMyProfile() async {
    final dto = await _remoteDatasource.getMyProfile();
    return dto.toDomain();
  }

  @override
  Future<UserProfile> updateMyProfile(String displayName) async {
    final dto = await _remoteDatasource.updateMyProfile(displayName);
    return dto.toDomain();
  }
}
