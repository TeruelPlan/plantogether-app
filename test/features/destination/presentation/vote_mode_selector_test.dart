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
import 'package:plantogether_app/features/destination/presentation/widgets/vote_mode_selector.dart';

class MockDestinationBloc
    extends MockBloc<DestinationEvent, DestinationState>
    implements DestinationBloc {}

class FakeDestinationEvent extends Fake implements DestinationEvent {}

DestinationModel _buildDestination({int totalVotes = 0}) {
  return DestinationModel(
    id: 'd1',
    tripId: 't1',
    name: 'Paris',
    proposedByDeviceId: 'dev',
    createdAt: DateTime.utc(2026, 4, 1),
    updatedAt: DateTime.utc(2026, 4, 1),
    votes: DestinationVotesModel(totalVotes: totalVotes),
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

  testWidgets('organizer sees SegmentedButton with 3 segments',
      (tester) async {
    await tester.pumpWidget(wrap(VoteModeSelector(
      tripId: 't1',
      currentMode: VoteMode.simple,
      isOrganizer: true,
      destinations: const [],
    )));
    expect(find.byType(SegmentedButton<VoteMode>), findsOneWidget);
    expect(find.text('Simple'), findsOneWidget);
    expect(find.text('Approval'), findsOneWidget);
    expect(find.text('Ranking'), findsOneWidget);
  });

  testWidgets('participant sees a read-only Chip', (tester) async {
    await tester.pumpWidget(wrap(VoteModeSelector(
      tripId: 't1',
      currentMode: VoteMode.approval,
      isOrganizer: false,
      destinations: const [],
    )));
    expect(find.byType(SegmentedButton<VoteMode>), findsNothing);
    expect(find.byType(Chip), findsOneWidget);
    expect(find.textContaining('Approval'), findsOneWidget);
  });

  testWidgets(
      'switching from RANKING to SIMPLE with existing votes shows confirmation dialog',
      (tester) async {
    final destWithVotes = _buildDestination(totalVotes: 3);
    await tester.pumpWidget(wrap(VoteModeSelector(
      tripId: 't1',
      currentMode: VoteMode.ranking,
      isOrganizer: true,
      destinations: [destWithVotes],
    )));

    // Tap the "Simple" segment.
    await tester.tap(find.text('Simple'));
    await tester.pumpAndSettle();

    expect(find.text('Switch vote mode?'), findsOneWidget);
    // No event dispatched yet — waiting for confirmation.
    verifyNever(() => bloc.add(any()));

    // Confirm.
    await tester.tap(find.text('Switch'));
    await tester.pumpAndSettle();

    verify(() => bloc.add(
          const UpdateVoteConfig(tripId: 't1', mode: VoteMode.simple),
        )).called(1);
  });
}
