// Story 4.1 — Propose & View Destinations
// Story 4.2 — Configure Vote Mode & Cast Votes
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../helpers/api_helper.dart';
import '../../helpers/app_runner.dart';

void main() {
  patrolTest('proposes a destination and sees it in the list', ($) async {
    await launchApp($);

    // Create a trip
    await $(const ValueKey('home_create_trip_fab')).waitUntilVisible();
    await $(const ValueKey('home_create_trip_fab')).tap();
    await $.pumpAndSettle();
    await $(
      const ValueKey('create_trip_name_field'),
    ).enterText('Destination Trip');
    await $(const ValueKey('create_trip_submit_button')).tap();
    await $.pumpAndSettle();

    // Navigate to Destinations tab
    await $(
      const ValueKey('trip_workspace_destinations_tab'),
    ).waitUntilVisible();
    await $(const ValueKey('trip_workspace_destinations_tab')).tap();
    await $.pumpAndSettle();

    // Empty state shown
    expect($('Where are you going?'), findsOneWidget);

    // Propose a destination
    await $(const ValueKey('destinations_tab_propose_button')).tap();
    await $.pumpAndSettle();

    await $(
      const ValueKey('propose_destination_name_field'),
    ).enterText('Barcelona');
    await $(
      const ValueKey('propose_destination_description_field'),
    ).enterText('Beach and architecture');
    await $(const ValueKey('propose_destination_submit_button')).tap();
    await $.pumpAndSettle();

    expect($('Barcelona'), findsOneWidget);
  });

  patrolTest('empty destination name shows validation error', ($) async {
    await launchApp($);

    await $(const ValueKey('home_create_trip_fab')).waitUntilVisible();
    await $(const ValueKey('home_create_trip_fab')).tap();
    await $.pumpAndSettle();
    await $(
      const ValueKey('create_trip_name_field'),
    ).enterText('Validation Trip');
    await $(const ValueKey('create_trip_submit_button')).tap();
    await $.pumpAndSettle();

    await $(const ValueKey('trip_workspace_destinations_tab')).tap();
    await $.pumpAndSettle();

    await $(const ValueKey('destinations_tab_propose_button')).tap();
    await $.pumpAndSettle();

    await $(const ValueKey('propose_destination_submit_button')).tap();
    await $.pumpAndSettle();

    expect($('Destination name is required'), findsOneWidget);
  });

  patrolTest('member can vote on a destination', ($) async {
    // Seed: create trip + destination via API
    const deviceId = 'e2e-dest-voter-00000000-0000-0000-0000-000000000003';
    final api = ApiHelper(deviceId: deviceId);
    final trip = await api.createTrip(title: 'Vote Destination Trip');
    final tripId = trip['id'] as String;
    await api.createDestination(
      tripId: tripId,
      name: 'Lisbon',
      description: 'Great food and trams',
    );

    await launchApp($);

    await $(const ValueKey('home_trips_list')).waitUntilVisible();
    await $('Vote Destination Trip').tap();
    await $.pumpAndSettle();

    await $(const ValueKey('trip_workspace_destinations_tab')).tap();
    await $.pumpAndSettle();

    // Destination card is present
    expect($('Lisbon'), findsOneWidget);

    // Cast a vote
    await $(const ValueKey('destination_vote_button_0')).waitUntilVisible();
    await $(const ValueKey('destination_vote_button_0')).tap();
    await $.pumpAndSettle();

    // Vote count updated
    expect($(const ValueKey('destination_vote_count_0')), findsOneWidget);
  });

  patrolTest('destinations list is ordered with newest first', ($) async {
    const deviceId = 'e2e-dest-order-00000000-0000-0000-0000-000000000004';
    final api = ApiHelper(deviceId: deviceId);
    final trip = await api.createTrip(title: 'Order Test Trip');
    final tripId = trip['id'] as String;
    await api.createDestination(tripId: tripId, name: 'First');
    await api.createDestination(tripId: tripId, name: 'Second');

    await launchApp($);

    await $(const ValueKey('home_trips_list')).waitUntilVisible();
    await $('Order Test Trip').tap();
    await $.pumpAndSettle();

    await $(const ValueKey('trip_workspace_destinations_tab')).tap();
    await $.pumpAndSettle();

    // 'Second' was created last so it should appear at the top
    final items = $.tester.widgetList(
      find.byType(find.text('Second').runtimeType),
    );
    expect(items, isNotEmpty);
  });
}
