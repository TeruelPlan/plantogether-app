import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_member_model.dart';
import 'package:plantogether_app/features/trip/domain/repository/trip_repository.dart';
import 'package:plantogether_app/features/trip/presentation/bloc/member_list_bloc.dart';
import 'package:plantogether_app/features/trip/presentation/bloc/member_list_state.dart';
import 'package:plantogether_app/features/trip/presentation/widgets/remove_member_dialog.dart';

class MockTripRepository extends Mock implements TripRepository {}

void main() {
  late MockTripRepository mockRepository;
  late MemberListBloc bloc;

  const members = [
    TripMemberModel(
      deviceId: 'device-organizer',
      displayName: 'Alice',
      role: 'ORGANIZER',
      joinedAt: '2026-01-01T00:00:00Z',
    ),
    TripMemberModel(
      deviceId: 'device-participant',
      displayName: 'Bob',
      role: 'PARTICIPANT',
      joinedAt: '2026-01-02T00:00:00Z',
    ),
  ];

  setUp(() {
    mockRepository = MockTripRepository();
    when(() => mockRepository.getMembers(any()))
        .thenAnswer((_) async => members);
    bloc = MemberListBloc(mockRepository);
    bloc.emit(const MemberListState.loaded(members: members));
  });

  tearDown(() {
    bloc.close();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: BlocProvider<MemberListBloc>.value(
        value: bloc,
        child: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => RemoveMemberDialog.show(
                context,
                tripId: 'trip-1',
                deviceId: 'device-participant',
                displayName: 'Bob',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  group('RemoveMemberDialog', () {
    testWidgets('cancel closes dialog without changing state', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Remove Bob?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Remove Bob?'), findsNothing);
      // State still loaded with both members
      expect(
        bloc.state.whenOrNull(loaded: (m) => m.length),
        equals(2),
      );
    });

    testWidgets('confirm dispatches RemoveMember and closes dialog', (tester) async {
      when(() => mockRepository.removeMember('trip-1', 'device-participant'))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(find.text('Remove Bob?'), findsNothing);
    });
  });
}
