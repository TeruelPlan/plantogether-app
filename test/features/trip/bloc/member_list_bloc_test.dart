import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_member_model.dart';
import 'package:plantogether_app/features/trip/domain/repository/trip_repository.dart';
import 'package:plantogether_app/features/trip/presentation/bloc/member_list_bloc.dart';
import 'package:plantogether_app/features/trip/presentation/bloc/member_list_event.dart';
import 'package:plantogether_app/features/trip/presentation/bloc/member_list_state.dart';

class MockTripRepository extends Mock implements TripRepository {}

const _tripId = 'trip-1';

final _organizer = TripMemberModel(
  memberId: 'member-organizer',
  displayName: 'Alice',
  role: 'ORGANIZER',
  joinedAt: DateTime.utc(2026, 1, 1),
  isMe: true,
);

final _participant = TripMemberModel(
  memberId: 'member-participant',
  displayName: 'Bob',
  role: 'PARTICIPANT',
  joinedAt: DateTime.utc(2026, 1, 2),
  isMe: false,
);

void main() {
  late MockTripRepository mockRepository;

  setUp(() {
    mockRepository = MockTripRepository();
  });

  group('MemberListBloc - LoadMembers', () {
    blocTest<MemberListBloc, MemberListState>(
      'emits [loading, loaded] when LoadMembers succeeds',
      build: () {
        when(() => mockRepository.getMembers(_tripId))
            .thenAnswer((_) async => [_organizer, _participant]);
        return MemberListBloc(mockRepository);
      },
      act: (bloc) => bloc.add(const LoadMembers(_tripId)),
      expect: () => [
        const MemberListState.loading(),
        MemberListState.loaded(members: [_organizer, _participant]),
      ],
    );

    blocTest<MemberListBloc, MemberListState>(
      'emits [loading, failure] when LoadMembers throws',
      build: () {
        when(() => mockRepository.getMembers(_tripId))
            .thenThrow(Exception('Network error'));
        return MemberListBloc(mockRepository);
      },
      act: (bloc) => bloc.add(const LoadMembers(_tripId)),
      expect: () => [
        const MemberListState.loading(),
        isA<MemberListState>().having(
          (s) => s.whenOrNull(failure: (m) => m),
          'failure message',
          contains('Network error'),
        ),
      ],
    );
  });

  group('MemberListBloc - RemoveMember', () {
    blocTest<MemberListBloc, MemberListState>(
      'emits loaded without removed member (optimistic update)',
      build: () {
        when(() => mockRepository.removeMember(_tripId, 'member-participant'))
            .thenAnswer((_) async {});
        return MemberListBloc(mockRepository);
      },
      seed: () => MemberListState.loaded(
        members: [_organizer, _participant],
      ),
      act: (bloc) => bloc.add(const RemoveMember(
        tripId: _tripId,
        memberId: 'member-participant',
      )),
      expect: () => [
        MemberListState.loaded(members: [_organizer]),
      ],
    );

    blocTest<MemberListBloc, MemberListState>(
      'reverts to previous list and emits failure when removeMember throws',
      build: () {
        when(() => mockRepository.removeMember(_tripId, 'member-participant'))
            .thenThrow(Exception('Server error'));
        return MemberListBloc(mockRepository);
      },
      seed: () => MemberListState.loaded(
        members: [_organizer, _participant],
      ),
      act: (bloc) => bloc.add(const RemoveMember(
        tripId: _tripId,
        memberId: 'member-participant',
      )),
      expect: () => [
        MemberListState.loaded(members: [_organizer]),
        MemberListState.loaded(members: [_organizer, _participant]),
        isA<MemberListState>().having(
          (s) => s.whenOrNull(failure: (m) => m),
          'failure message',
          contains('Server error'),
        ),
      ],
    );
  });
}
