import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/profile/domain/model/user_profile.dart';
import 'package:plantogether_app/features/profile/domain/repository/profile_repository.dart';
import 'package:plantogether_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:plantogether_app/features/profile/presentation/bloc/profile_event.dart';
import 'package:plantogether_app/features/profile/presentation/bloc/profile_state.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  group('ProfileBloc', () {
    late ProfileBloc profileBloc;
    late MockProfileRepository mockRepository;

    setUp(() {
      mockRepository = MockProfileRepository();
      profileBloc = ProfileBloc(mockRepository);
    });

    tearDown(() {
      profileBloc.close();
    });

    const testProfile = UserProfile(
      displayName: 'Alice',
      avatarUrl: null,
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [loading, loaded] when LoadProfile is added successfully',
      build: () {
        when(() => mockRepository.getMyProfile()).thenAnswer((_) async => testProfile);
        return profileBloc;
      },
      act: (bloc) => bloc.add(const LoadProfile()),
      expect: () => [
        const ProfileState.loading(),
        const ProfileState.loaded(testProfile),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [updating, updateSuccess] when UpdateDisplayName is added successfully',
      build: () {
        final updatedProfile = testProfile.copyWith(displayName: 'Bob');
        when(() => mockRepository.updateMyProfile('Bob'))
            .thenAnswer((_) async => updatedProfile);
        return profileBloc;
      },
      act: (bloc) => bloc.add(const UpdateDisplayName('Bob')),
      expect: () => [
        const ProfileState.updating(),
        isA<ProfileUpdateSuccess>(),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [loading, error] when LoadProfile fails',
      build: () {
        when(() => mockRepository.getMyProfile())
            .thenThrow(Exception('Network error'));
        return profileBloc;
      },
      act: (bloc) => bloc.add(const LoadProfile()),
      expect: () => [
        const ProfileState.loading(),
        isA<ProfileError>(),
      ],
    );
  });
}
