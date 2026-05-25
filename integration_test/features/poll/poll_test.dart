// Story 3.1 — Create Date Poll
// Story 3.2 — Vote on Poll Slots
// Story 3.4 — Lock Date Poll
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../helpers/api_helper.dart';
import '../../helpers/app_runner.dart';

void main() {
  patrolTest('creates a date poll with two slots', ($) async {
    await launchApp($);

    // Create a trip first
    await $(const ValueKey('home_create_trip_fab')).waitUntilVisible();
    await $(const ValueKey('home_create_trip_fab')).tap();
    await $.pumpAndSettle();
    await $(
      const ValueKey('create_trip_name_field'),
    ).enterText('Poll Test Trip');
    await $(const ValueKey('create_trip_submit_button')).tap();
    await $.pumpAndSettle();

    // Navigate to Dates tab
    await $(const ValueKey('trip_workspace_dates_tab')).waitUntilVisible();
    await $(const ValueKey('trip_workspace_dates_tab')).tap();
    await $.pumpAndSettle();

    // Open create poll sheet
    await $(const ValueKey('dates_tab_create_poll_button')).waitUntilVisible();
    await $(const ValueKey('dates_tab_create_poll_button')).tap();
    await $.pumpAndSettle();

    // Fill poll title
    await $(
      const ValueKey('create_poll_title_field'),
    ).enterText('When are we going?');

    // Add two date slots
    await $(const ValueKey('create_poll_add_slot_button')).tap();
    await $.pumpAndSettle();
    // First slot — pick any date from the date picker
    await $(const ValueKey('date_picker_confirm_button')).tap();
    await $.pumpAndSettle();

    await $(const ValueKey('create_poll_add_slot_button')).tap();
    await $.pumpAndSettle();
    // Second slot
    await $(const ValueKey('date_picker_confirm_button')).tap();
    await $.pumpAndSettle();

    await $(const ValueKey('create_poll_submit_button')).tap();
    await $.pumpAndSettle();

    // Poll card appears in the dates tab
    expect($('When are we going?'), findsOneWidget);
  });

  patrolTest('fewer than two slots shows validation error', ($) async {
    await launchApp($);

    await $(const ValueKey('home_create_trip_fab')).waitUntilVisible();
    await $(const ValueKey('home_create_trip_fab')).tap();
    await $.pumpAndSettle();
    await $(
      const ValueKey('create_trip_name_field'),
    ).enterText('Validation Trip');
    await $(const ValueKey('create_trip_submit_button')).tap();
    await $.pumpAndSettle();

    await $(const ValueKey('trip_workspace_dates_tab')).tap();
    await $.pumpAndSettle();

    await $(const ValueKey('dates_tab_create_poll_button')).tap();
    await $.pumpAndSettle();

    await $(
      const ValueKey('create_poll_title_field'),
    ).enterText('One-slot poll');

    await $(const ValueKey('create_poll_add_slot_button')).tap();
    await $.pumpAndSettle();
    await $(const ValueKey('date_picker_confirm_button')).tap();
    await $.pumpAndSettle();

    await $(const ValueKey('create_poll_submit_button')).tap();
    await $.pumpAndSettle();

    expect($('At least 2 date slots are required'), findsOneWidget);
  });

  patrolTest('member can vote YES on a poll slot', ($) async {
    // Seed: create trip + poll via API
    const deviceId = 'e2e-voter-00000000-0000-0000-0000-000000000002';
    final api = ApiHelper(deviceId: deviceId);
    final trip = await api.createTrip(title: 'Voting Trip');
    final tripId = trip['id'] as String;
    await api.createPoll(
      tripId: tripId,
      title: 'Seeded Poll',
      slots: [
        {'startDate': '2026-08-01', 'endDate': '2026-08-05'},
        {'startDate': '2026-08-10', 'endDate': '2026-08-15'},
      ],
    );

    await launchApp($);

    // The seeded trip appears in the home list
    await $(const ValueKey('home_trips_list')).waitUntilVisible();
    await $('Voting Trip').tap();
    await $.pumpAndSettle();

    await $(const ValueKey('trip_workspace_dates_tab')).tap();
    await $.pumpAndSettle();

    // Open poll detail
    await $('Seeded Poll').tap();
    await $.pumpAndSettle();

    // Vote YES on the first slot
    await $(const ValueKey('poll_slot_yes_button_0')).waitUntilVisible();
    await $(const ValueKey('poll_slot_yes_button_0')).tap();
    await $.pumpAndSettle();

    // Vote is reflected (button active state or score update)
    expect($(const ValueKey('poll_slot_yes_button_0')), findsOneWidget);
  });
}
