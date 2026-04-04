import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_invitation_model.dart';
import 'package:plantogether_app/features/trip/domain/repository/trip_repository.dart';
import 'package:plantogether_app/features/trip/presentation/bloc/invite_bloc.dart';
import 'package:plantogether_app/features/trip/presentation/bloc/invite_event.dart';
import 'package:plantogether_app/features/trip/presentation/bloc/invite_state.dart';

class MockTripRepository extends Mock implements TripRepository {}

void main() {
  group('InviteBloc', () {
    late InviteBloc bloc;
    late MockTripRepository mockRepository;

    setUp(() {
      mockRepository = MockTripRepository();
      bloc = InviteBloc(mockRepository);
    });

    tearDown(() {
      bloc.close();
    });

    const invitation = TripInvitationModel(
      inviteUrl: 'http://localhost/trips/123/join?token=abc',
      token: 'abc',
    );

    blocTest<InviteBloc, InviteState>(
      'emits [loading, loaded] when LoadInvitation succeeds',
      build: () {
        when(() => mockRepository.getInvitation('trip-1'))
            .thenAnswer((_) async => invitation);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadInvitation(tripId: 'trip-1')),
      expect: () => [
        const InviteState.loading(),
        const InviteState.loaded(invitation: invitation),
      ],
    );

    blocTest<InviteBloc, InviteState>(
      'emits [loading, failure] when LoadInvitation throws',
      build: () {
        when(() => mockRepository.getInvitation('trip-1'))
            .thenThrow(Exception('Forbidden'));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadInvitation(tripId: 'trip-1')),
      expect: () => [
        const InviteState.loading(),
        isA<InviteState>().having(
          (s) => s.whenOrNull(failure: (msg) => msg),
          'failure message',
          isNotNull,
        ),
      ],
    );
  });
}
