// Story 2.2 — Trip Invitation: Generate Link, Join Trip
// Story 2.5 — Member List & Organizer Controls
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../helpers/api_helper.dart';
import '../../helpers/app_runner.dart';

void main() {
  patrolTest('invite screen shows QR code and copy button', ($) async {
    await launchApp($);

    // Create a trip
    await $(const ValueKey('home_create_trip_fab')).waitUntilVisible();
    await $(const ValueKey('home_create_trip_fab')).tap();
    await $.pumpAndSettle();
    await $(
      const ValueKey('create_trip_name_field'),
    ).enterText('Invite Test Trip');
    await $(const ValueKey('create_trip_submit_button')).tap();
    await $.pumpAndSettle();

    // Open invite screen
    await $(const ValueKey('trip_workspace_invite_button')).waitUntilVisible();
    await $(const ValueKey('trip_workspace_invite_button')).tap();
    await $.pumpAndSettle();

    expect($(const ValueKey('invite_qr_code')), findsOneWidget);
    expect($(const ValueKey('invite_copy_link_button')), findsOneWidget);
  });

  patrolTest('joining via invite link adds user as member', ($) async {
    // Seed: organizer creates trip and invitation via API
    const organizerDeviceId =
        'e2e-organizer-00000000-0000-0000-0000-000000000001';
    final api = ApiHelper(deviceId: organizerDeviceId);
    final trip = await api.createTrip(title: 'Join E2E Trip');
    final tripId = trip['id'] as String;
    final invitation = await api.getInvitation(tripId);
    final inviteUrl = invitation['inviteUrl'] as String;

    // Boot app as a different device (the joiner)
    await launchApp($);

    // Paste invite link through the home dialog
    await $(const ValueKey('home_join_link_button')).waitUntilVisible();
    await $(const ValueKey('home_join_link_button')).tap();
    await $.pumpAndSettle();

    await $(const ValueKey('home_join_link_field')).enterText(inviteUrl);
    await $(const ValueKey('home_join_submit_button')).tap();
    await $.pumpAndSettle();

    // Trip preview page opens
    await $(const ValueKey('trip_preview_join_button')).waitUntilVisible();
    await $(const ValueKey('trip_preview_join_button')).tap();
    await $.pumpAndSettle();

    // After joining, workspace opens
    expect($(const ValueKey('trip_workspace_overview_tab')), findsOneWidget);
  });

  patrolTest('invalid invite link shows error snackbar', ($) async {
    await launchApp($);

    await $(const ValueKey('home_join_link_button')).waitUntilVisible();
    await $(const ValueKey('home_join_link_button')).tap();
    await $.pumpAndSettle();

    await $(
      const ValueKey('home_join_link_field'),
    ).enterText('https://not-a-valid-link');
    await $(const ValueKey('home_join_submit_button')).tap();
    await $.pumpAndSettle();

    expect($('Invalid invitation link'), findsOneWidget);
  });

  patrolTest('member list shows all members', ($) async {
    await launchApp($);

    // Create a trip
    await $(const ValueKey('home_create_trip_fab')).waitUntilVisible();
    await $(const ValueKey('home_create_trip_fab')).tap();
    await $.pumpAndSettle();
    await $(const ValueKey('create_trip_name_field')).enterText('Members Trip');
    await $(const ValueKey('create_trip_submit_button')).tap();
    await $.pumpAndSettle();

    // Open member list
    await $(const ValueKey('trip_workspace_members_button')).waitUntilVisible();
    await $(const ValueKey('trip_workspace_members_button')).tap();
    await $.pumpAndSettle();

    // The creator is listed as ORGANIZER
    expect($(const ValueKey('member_list_page')), findsOneWidget);
    expect($('ORGANIZER'), findsOneWidget);
  });
}
