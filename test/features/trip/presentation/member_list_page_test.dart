import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_member_model.dart';
import 'package:plantogether_app/features/trip/domain/repository/trip_repository.dart';
import 'package:plantogether_app/features/trip/presentation/bloc/member_list_bloc.dart';
import 'package:plantogether_app/features/trip/presentation/bloc/member_list_state.dart';
import 'package:plantogether_app/features/trip/presentation/pages/member_list_page.dart';

class MockTripRepository extends Mock implements TripRepository {}

class FakeMemberListBloc extends MemberListBloc {
  final MemberListState _state;

  FakeMemberListBloc(this._state) : super(MockTripRepository());

  @override
  MemberListState get state => _state;

  @override
  Stream<MemberListState> get stream => Stream.value(_state);
}

const _organizer = TripMemberModel(
  memberId: 'member-organizer',
  displayName: 'Alice',
  role: 'ORGANIZER',
  joinedAt: '2026-01-01T00:00:00Z',
  isMe: true,
);

const _participant = TripMemberModel(
  memberId: 'member-participant',
  displayName: 'Bob',
  role: 'PARTICIPANT',
  joinedAt: '2026-01-02T00:00:00Z',
  isMe: false,
);

Widget buildTestWidget({required MemberListBloc bloc}) {
  return MaterialApp(
    home: BlocProvider<MemberListBloc>.value(
      value: bloc,
      child: const MemberListPage(tripId: 'trip-1'),
    ),
  );
}

void main() {
  late MockTripRepository mockRepository;

  setUp(() {
    mockRepository = MockTripRepository();
    when(() => mockRepository.getMembers(any()))
        .thenAnswer((_) async => [_organizer, _participant]);
  });

  group('MemberListPage', () {
    testWidgets('renders member list with avatars and role badges', (tester) async {
      final bloc = MemberListBloc(mockRepository);
      await tester.pumpWidget(buildTestWidget(bloc: bloc));
      await tester.pump();
      await tester.pump();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Organizer'), findsOneWidget);
      expect(find.text('Member'), findsOneWidget);
    });

    testWidgets('remove button only visible for organizer on participant rows', (tester) async {
      final bloc = MemberListBloc(mockRepository);
      await tester.pumpWidget(buildTestWidget(bloc: bloc));
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.person_remove_outlined), findsOneWidget);
    });

    testWidgets('remove button not shown when current user is participant', (tester) async {
      const participantAsMe = TripMemberModel(
        memberId: 'member-participant',
        displayName: 'Bob',
        role: 'PARTICIPANT',
        joinedAt: '2026-01-02T00:00:00Z',
        isMe: true,
      );
      const organizerNotMe = TripMemberModel(
        memberId: 'member-organizer',
        displayName: 'Alice',
        role: 'ORGANIZER',
        joinedAt: '2026-01-01T00:00:00Z',
        isMe: false,
      );
      when(() => mockRepository.getMembers(any()))
          .thenAnswer((_) async => [organizerNotMe, participantAsMe]);

      final bloc = MemberListBloc(mockRepository);
      await tester.pumpWidget(buildTestWidget(bloc: bloc));
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.person_remove_outlined), findsNothing);
    });

    testWidgets('remove button not shown on organizer row even when caller is organizer', (tester) async {
      final bloc = MemberListBloc(mockRepository);
      await tester.pumpWidget(buildTestWidget(bloc: bloc));
      await tester.pump();
      await tester.pump();

      // Only one remove button (for participant), not for organizer row
      expect(find.byIcon(Icons.person_remove_outlined), findsOneWidget);
    });
  });
}
