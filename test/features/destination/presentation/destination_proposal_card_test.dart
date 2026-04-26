import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantogether_app/features/destination/domain/model/destination_model.dart';
import 'package:plantogether_app/features/destination/presentation/widgets/destination_proposal_card.dart';

void main() {
  final baseDestination = DestinationModel(
    id: 'd-1',
    tripId: 'trip-1',
    name: 'Lisbon',
    proposedByDeviceId: 'device-1',
    createdAt: DateTime.utc(2026, 4, 1),
    updatedAt: DateTime.utc(2026, 4, 1),
  );

  Widget buildCard(DestinationModel destination, {Widget? organizerAction}) {
    return MaterialApp(
      home: Scaffold(
        body: DestinationProposalCard(
          destination: destination,
          organizerAction: organizerAction,
        ),
      ),
    );
  }

  testWidgets('chosen_rendersSelectedBadge', (tester) async {
    final chosen = baseDestination.copyWith(
      status: DestinationStatus.chosen,
      chosenAt: DateTime.utc(2026, 4, 2),
      chosenByDeviceId: 'device-1',
    );

    await tester.pumpWidget(buildCard(chosen));

    expect(
      find.byKey(ValueKey('destination_chosen_badge_${chosen.id}')),
      findsOneWidget,
    );
    expect(find.text('Selected ✓'), findsOneWidget);
  });

  testWidgets('organizer_noChosen_rendersSelectAction', (tester) async {
    final selectButton = TextButton(
      key: ValueKey('select_destination_button_${baseDestination.id}'),
      onPressed: () {},
      child: const Text('Select this destination'),
    );

    await tester.pumpWidget(buildCard(baseDestination, organizerAction: selectButton));

    expect(
      find.byKey(ValueKey('select_destination_button_${baseDestination.id}')),
      findsOneWidget,
    );
    expect(find.text('Select this destination'), findsOneWidget);
  });

  testWidgets('participant_noChosen_doesNotRenderSelectAction', (tester) async {
    await tester.pumpWidget(buildCard(baseDestination));

    expect(find.text('Select this destination'), findsNothing);
  });

  testWidgets('organizer_anotherIsChosen_rendersSelectActionOnNonChosenCards',
      (tester) async {
    final nonChosen = baseDestination;
    final selectButton = TextButton(
      key: ValueKey('select_destination_button_${nonChosen.id}'),
      onPressed: () {},
      child: const Text('Select this destination'),
    );

    await tester.pumpWidget(buildCard(nonChosen, organizerAction: selectButton));

    expect(
      find.byKey(ValueKey('select_destination_button_${nonChosen.id}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('destination_chosen_badge_${nonChosen.id}')),
      findsNothing,
    );
  });
}
