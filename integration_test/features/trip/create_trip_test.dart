// Story 2.1 — Trip Creation
// Story 2.3 — Trip Dashboard & Overview
// Story 2.4 — Trip Metadata Update & Archive
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../helpers/app_runner.dart';

void main() {
  patrolTest('creates a trip and sees it in the home list', ($) async {
    await launchApp($);

    await $(const ValueKey('home_create_trip_fab')).waitUntilVisible();
    await $(const ValueKey('home_create_trip_fab')).tap();
    await $.pumpAndSettle();

    await $(
      const ValueKey('create_trip_name_field'),
    ).enterText('E2E Summer Trip');
    await $(
      const ValueKey('create_trip_description_field'),
    ).enterText('Test description');

    await $(const ValueKey('create_trip_currency_dropdown')).tap();
    await $.pumpAndSettle();
    await $('EUR').tap();
    await $.pumpAndSettle();

    await $(const ValueKey('create_trip_submit_button')).tap();
    await $.pumpAndSettle();

    // Trip workspace opens after creation
    expect($(const ValueKey('trip_workspace_overview_tab')), findsOneWidget);
  });

  patrolTest('empty trip name shows validation error', ($) async {
    await launchApp($);

    await $(const ValueKey('home_create_trip_fab')).waitUntilVisible();
    await $(const ValueKey('home_create_trip_fab')).tap();
    await $.pumpAndSettle();

    await $(const ValueKey('create_trip_submit_button')).tap();
    await $.pumpAndSettle();

    expect($('Trip name is required'), findsOneWidget);
  });

  patrolTest('organizer can edit trip title', ($) async {
    await launchApp($);

    // Create a trip first then open it
    await $(const ValueKey('home_create_trip_fab')).waitUntilVisible();
    await $(const ValueKey('home_create_trip_fab')).tap();
    await $.pumpAndSettle();
    await $(
      const ValueKey('create_trip_name_field'),
    ).enterText('Editable Trip');
    await $(const ValueKey('create_trip_submit_button')).tap();
    await $.pumpAndSettle();

    // Open edit sheet from workspace
    await $(const ValueKey('trip_workspace_edit_button')).waitUntilVisible();
    await $(const ValueKey('trip_workspace_edit_button')).tap();
    await $.pumpAndSettle();

    await $(const ValueKey('trip_edit_title_field')).enterText('Renamed Trip');
    await $(const ValueKey('trip_edit_save_button')).tap();
    await $.pumpAndSettle();

    expect($('Renamed Trip'), findsOneWidget);
  });

  patrolTest('organizer can archive a trip', ($) async {
    await launchApp($);

    // Create then archive
    await $(const ValueKey('home_create_trip_fab')).waitUntilVisible();
    await $(const ValueKey('home_create_trip_fab')).tap();
    await $.pumpAndSettle();
    await $(
      const ValueKey('create_trip_name_field'),
    ).enterText('Trip to Archive');
    await $(const ValueKey('create_trip_submit_button')).tap();
    await $.pumpAndSettle();

    await $(const ValueKey('trip_workspace_edit_button')).waitUntilVisible();
    await $(const ValueKey('trip_workspace_edit_button')).tap();
    await $.pumpAndSettle();

    await $(const ValueKey('trip_edit_archive_button')).tap();
    await $.pumpAndSettle();

    // Confirm dialog
    await $(const ValueKey('archive_confirm_button')).tap();
    await $.pumpAndSettle();

    // Navigated back to home; trip should appear under Archived section
    await $(const ValueKey('home_trips_list')).waitUntilVisible();
    expect($('ARCHIVED'), findsOneWidget);
  });
}
