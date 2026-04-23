import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/destination/domain/model/destination_model.dart';
import 'package:plantogether_app/features/destination/domain/model/vote_config_model.dart';
import 'package:plantogether_app/features/destination/presentation/bloc/destination_bloc.dart';
import 'package:plantogether_app/features/destination/presentation/bloc/destination_event.dart';
import 'package:plantogether_app/features/destination/presentation/bloc/destination_state.dart';
import 'package:plantogether_app/features/destination/presentation/widgets/vote_input_widget.dart';

class MockDestinationBloc
    extends MockBloc<DestinationEvent, DestinationState>
    implements DestinationBloc {}

class FakeDestinationEvent extends Fake implements DestinationEvent {}

DestinationModel _buildDestination(String id) {
  return DestinationModel(
    id: id,
    tripId: 't1',
    name: 'Dest $id',
    proposedByDeviceId: 'dev',
    createdAt: DateTime.utc(2026, 4, 1),
    updatedAt: DateTime.utc(2026, 4, 1),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDestinationEvent());
  });

  late MockDestinationBloc bloc;

  setUp(() {
    bloc = MockDestinationBloc();
    when(() => bloc.state).thenReturn(const DestinationState.initial());
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<DestinationBloc>.value(value: bloc, child: child),
      ),
    );
  }

  testWidgets('SIMPLE tap dispatches CastVote(destId, rank:null)',
      (tester) async {
    final dest = _buildDestination('d1');
    await tester.pumpWidget(wrap(VoteInputWidget(
      tripId: 't1',
      destination: dest,
      mode: VoteMode.simple,
      totalDestinationCount: 1,
    )));

    await tester.tap(find.byIcon(Icons.radio_button_unchecked));
    await tester.pump();

    verify(() => bloc.add(
          const CastVote(tripId: 't1', destinationId: 'd1'),
        )).called(1);
  });

  testWidgets('SIMPLE tap-again dispatches RetractVote(destId)',
      (tester) async {
    final dest = _buildDestination('d1');
    await tester.pumpWidget(wrap(VoteInputWidget(
      tripId: 't1',
      destination: dest,
      mode: VoteMode.simple,
      totalDestinationCount: 1,
      isMySimpleChoice: true,
    )));

    await tester.tap(find.byIcon(Icons.radio_button_checked));
    await tester.pump();

    verify(() => bloc.add(
          const RetractVote(tripId: 't1', destinationId: 'd1'),
        )).called(1);
  });

  testWidgets('APPROVAL checkbox toggles correctly for two destinations',
      (tester) async {
    final d1 = _buildDestination('d1');
    final d2 = _buildDestination('d2');
    await tester.pumpWidget(wrap(Column(children: [
      VoteInputWidget(
        tripId: 't1',
        destination: d1,
        mode: VoteMode.approval,
        totalDestinationCount: 2,
        isMyApproval: false,
      ),
      VoteInputWidget(
        tripId: 't1',
        destination: d2,
        mode: VoteMode.approval,
        totalDestinationCount: 2,
        isMyApproval: true,
      ),
    ])));

    final checkboxes = find.byType(Checkbox);
    expect(checkboxes, findsNWidgets(2));

    // Tap the first (currently false) -> expect CastVote for d1.
    await tester.tap(checkboxes.first);
    await tester.pump();
    verify(() => bloc.add(
          const CastVote(tripId: 't1', destinationId: 'd1'),
        )).called(1);

    // Tap the second (currently true) -> expect RetractVote for d2.
    await tester.tap(checkboxes.at(1));
    await tester.pump();
    verify(() => bloc.add(
          const RetractVote(tripId: 't1', destinationId: 'd2'),
        )).called(1);
  });

  testWidgets('RANKING dropdown dispatches CastVote with rank', (tester) async {
    final dest = _buildDestination('d1');
    await tester.pumpWidget(wrap(VoteInputWidget(
      tripId: 't1',
      destination: dest,
      mode: VoteMode.ranking,
      totalDestinationCount: 3,
    )));

    await tester.tap(find.byType(DropdownButton<int?>));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rank 2').last);
    await tester.pumpAndSettle();

    verify(() => bloc.add(
          const CastVote(tripId: 't1', destinationId: 'd1', rank: 2),
        )).called(1);
  });
}
