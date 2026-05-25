// Story 1.1 — Device Identity & Flutter Core Wiring
// Story 1.3 — Display Name Update
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../helpers/app_runner.dart';

void main() {
  patrolTest(
    'first launch shows onboarding, sets display name, lands on home',
    ($) async {
      await launchApp($);

      // Splash resolves → onboarding (no prior device state in a fresh install)
      await $(const ValueKey('onboarding_name_field')).waitUntilVisible();

      await $(const ValueKey('onboarding_name_field')).enterText('Alice');
      await $(const ValueKey('onboarding_continue_button')).tap();
      await $.pumpAndSettle();

      // After onboarding completes the router sends the user to /home
      expect($(const ValueKey('home_create_trip_fab')), findsOneWidget);
    },
  );

  patrolTest('settings screen shows current display name pre-filled', (
    $,
  ) async {
    await launchApp($);

    // Assume onboarding already done (app state from previous test or seed)
    await $(const ValueKey('home_settings_button')).waitUntilVisible();
    await $(const ValueKey('home_settings_button')).tap();
    await $.pumpAndSettle();

    // The settings field must be pre-filled with the stored name
    final field = $(const ValueKey('settings_display_name_field'));
    await field.waitUntilVisible();
    expect(field.text, isNotEmpty);
  });

  patrolTest('empty display name on settings shows validation error', (
    $,
  ) async {
    await launchApp($);

    await $(const ValueKey('home_settings_button')).waitUntilVisible();
    await $(const ValueKey('home_settings_button')).tap();
    await $.pumpAndSettle();

    await $(const ValueKey('settings_display_name_field')).enterText('');
    await $(const ValueKey('settings_save_button')).tap();
    await $.pumpAndSettle();

    expect($('Display name is required'), findsOneWidget);
  });
}
