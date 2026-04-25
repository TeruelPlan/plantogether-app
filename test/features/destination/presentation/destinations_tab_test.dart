import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/destination/domain/model/destination_model.dart';
import 'package:plantogether_app/features/destination/domain/model/vote_config_model.dart';
import 'package:plantogether_app/features/destination/domain/repository/destination_repository.dart';
import 'package:plantogether_app/features/destination/presentation/bloc/destination_bloc.dart';
import 'package:plantogether_app/features/destination/presentation/widgets/destination_proposal_card.dart';
import 'package:plantogether_app/features/destination/presentation/widgets/destinations_tab.dart';

class MockDestinationRepository extends Mock implements DestinationRepository {}

void main() {
  late MockDestinationRepository mockRepository;

  setUp(() {
    mockRepository = MockDestinationRepository();
    when(() => mockRepository.list(any()))
        .thenAnswer((_) async => const []);
    when(() => mockRepository.getVoteConfig(any())).thenAnswer(
      (_) async => VoteConfigModel(
        tripId: 'trip-1',
        mode: VoteMode.simple,
        updatedAt: DateTime.utc(2026, 4, 1),
      ),
    );
  });

  const tripId = 'trip-1';
  final sample = DestinationModel(
    id: 'd-1',
    tripId: tripId,
    name: 'Paris',
    description: 'City of lights',
    proposedByDeviceId: 'device-1',
    createdAt: DateTime.utc(2026, 4, 1),
    updatedAt: DateTime.utc(2026, 4, 1),
  );

  Widget buildWidget({bool isOrganizer = false}) {
    when(() => mockRepository.listComments(any()))
        .thenAnswer((_) async => const []);
    return MaterialApp(
      home: RepositoryProvider<DestinationRepository>.value(
        value: mockRepository,
        child: BlocProvider(
          create: (_) => DestinationBloc(mockRepository),
          child: DestinationsTab(tripId: tripId, isOrganizer: isOrganizer),
        ),
      ),
    );
  }

  testWidgets('renders empty state when no destinations', (tester) async {
    when(() => mockRepository.list(tripId)).thenAnswer((_) async => const []);

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(
      find.text('Where are you going? · Propose a destination'),
      findsOneWidget,
    );
    expect(find.text('Propose destination'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('renders one card per destination', (tester) async {
    when(() => mockRepository.list(tripId))
        .thenAnswer((_) async => [sample]);

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.byType(DestinationProposalCard), findsOneWidget);
    expect(find.text('Paris'), findsOneWidget);
  });

  testWidgets('renders loading indicator before data resolves',
      (tester) async {
    final completer = Completer<List<DestinationModel>>();
    when(() => mockRepository.list(tripId))
        .thenAnswer((_) => completer.future);

    await tester.pumpWidget(buildWidget());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(const []);
    await tester.pumpAndSettle();
  });

  testWidgets('shows Leading badge on the highest-voted card',
      (tester) async {
    final winner = DestinationModel(
      id: 'w',
      tripId: tripId,
      name: 'Winner',
      proposedByDeviceId: 'd1',
      createdAt: DateTime.utc(2026, 4, 1),
      updatedAt: DateTime.utc(2026, 4, 1),
      votes: const DestinationVotesModel(totalVotes: 3),
    );
    final loser = DestinationModel(
      id: 'l',
      tripId: tripId,
      name: 'Loser',
      proposedByDeviceId: 'd1',
      createdAt: DateTime.utc(2026, 4, 1),
      updatedAt: DateTime.utc(2026, 4, 1),
      votes: const DestinationVotesModel(totalVotes: 1),
    );
    when(() => mockRepository.list(tripId))
        .thenAnswer((_) async => [winner, loser]);

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('destination_leading_badge_w')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('destination_leading_badge_l')),
        findsNothing);
  });

  testWidgets('chosen_hidesProposeFab', (tester) async {
    final chosen = DestinationModel(
      id: 'c',
      tripId: tripId,
      name: 'Lisbon',
      proposedByDeviceId: 'device-1',
      createdAt: DateTime.utc(2026, 4, 1),
      updatedAt: DateTime.utc(2026, 4, 1),
      status: DestinationStatus.chosen,
      chosenAt: DateTime.utc(2026, 4, 2),
      chosenByDeviceId: 'device-1',
    );
    when(() => mockRepository.list(tripId))
        .thenAnswer((_) async => [chosen]);

    await tester.pumpWidget(buildWidget(isOrganizer: true));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('propose_destination_fab')),
        findsNothing);
    expect(find.byKey(const ValueKey('destination_chosen_badge_c')),
        findsOneWidget);
  });

  testWidgets('chosen_disablesVoteInputWidgets_withTooltip', (tester) async {
    final chosen = DestinationModel(
      id: 'c',
      tripId: tripId,
      name: 'Lisbon',
      proposedByDeviceId: 'device-1',
      createdAt: DateTime.utc(2026, 4, 1),
      updatedAt: DateTime.utc(2026, 4, 1),
      status: DestinationStatus.chosen,
      chosenAt: DateTime.utc(2026, 4, 2),
      chosenByDeviceId: 'device-1',
    );
    when(() => mockRepository.list(tripId))
        .thenAnswer((_) async => [chosen]);

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey('vote_input_disabled_${chosen.id}')),
      findsOneWidget,
    );
  });

  testWidgets('selectAction_showsConfirmationDialog_beforeDispatch',
      (tester) async {
    when(() => mockRepository.list(tripId))
        .thenAnswer((_) async => [sample]);

    await tester.pumpWidget(buildWidget(isOrganizer: true));
    await tester.pumpAndSettle();

    final selectButton = find.byKey(ValueKey('select_destination_button_${sample.id}'));
    expect(selectButton, findsOneWidget);

    await tester.tap(selectButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('select_destination_dialog')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('select_destination_dialog_confirm')),
        findsOneWidget);
  });

  testWidgets('participant_doesNotRenderSelectAction', (tester) async {
    when(() => mockRepository.list(tripId))
        .thenAnswer((_) async => [sample]);

    await tester.pumpWidget(buildWidget(isOrganizer: false));
    await tester.pumpAndSettle();

    expect(find.byKey(ValueKey('select_destination_button_${sample.id}')),
        findsNothing);
  });
}
