import 'package:plantogether_app/features/profile/domain/model/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> getMyProfile();
  Future<UserProfile> updateMyProfile(String displayName);
}
