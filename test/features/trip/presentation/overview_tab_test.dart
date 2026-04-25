import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_member_model.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_model.dart';
import 'package:plantogether_app/features/trip/presentation/widgets/overview_tab.dart';
import 'package:plantogether_app/features/trip/presentation/widgets/trip_progress_indicator.dart';
import 'package:plantogether_app/features/trip/presentation/widgets/trip_summary_card.dart';
import 'package:plantogether_app/shared/widgets/member_avatar_stack.dart';

void main() {
  final tripWithMembers = TripModel(
    id: 'trip-1',
    title: 'Beach Trip',
    status: 'PLANNING',
    createdBy: 'device-1',
    createdAt: DateTime.utc(2026, 1, 1),
    startDate: DateTime(2026, 6, 1),
    endDate: DateTime(2026, 6, 7),
    memberCount: 3,
    members: [
      TripMemberModel(
          memberId: 'member-1',
          displayName: 'Alice',
          role: 'OWNER',
          joinedAt: DateTime(2026, 1, 1),
          isMe: true),
      TripMemberModel(
          memberId: 'member-2',
          displayName: 'Bob',
          role: 'MEMBER',
          joinedAt: DateTime(2026, 1, 2),
          isMe: false),
      TripMemberModel(
          memberId: 'member-3',
          displayName: 'Charlie',
          role: 'MEMBER',
          joinedAt: DateTime(2026, 1, 3),
          isMe: false),
    ],
  );

  final tripNoDates = TripModel(
    id: 'trip-2',
    title: 'No Date Trip',
    status: 'PLANNING',
    createdBy: 'device-1',
    createdAt: DateTime.utc(2026, 1, 1),
    memberCount: 1,
    members: [
      TripMemberModel(
          memberId: 'member-1',
          displayName: 'Alice',
          role: 'OWNER',
          joinedAt: DateTime(2026, 1, 1),
          isMe: true),
    ],
  );

  Widget buildTestWidget(TripModel trip, {String? chosenDestinationName}) {
    return MaterialApp(
      home: DefaultTabController(
        length: 5,
        child: Scaffold(
          body: OverviewTab(
            trip: trip,
            chosenDestinationName: chosenDestinationName,
          ),
        ),
      ),
    );
  }

  group('OverviewTab', () {
    testWidgets('renders 4 summary cards', (tester) async {
      await tester.pumpWidget(buildTestWidget(tripWithMembers));

      expect(find.byType(TripSummaryCard), findsNWidgets(4));
    });

    testWidgets('shows empty states when no dates are set', (tester) async {
      await tester.pumpWidget(buildTestWidget(tripNoDates));

      expect(find.text('Create a date poll'), findsOneWidget);
      expect(find.text('Propose a destination'), findsOneWidget);
      expect(find.text('Add the first expense'), findsOneWidget);
      expect(find.text('Add a task'), findsOneWidget);
    });

    testWidgets('displays MemberAvatarStack', (tester) async {
      await tester.pumpWidget(buildTestWidget(tripWithMembers));

      expect(find.byType(MemberAvatarStack), findsOneWidget);
      expect(find.text('3 members'), findsOneWidget);
    });

    testWidgets('formats date range with MMM d pattern', (tester) async {
      await tester.pumpWidget(buildTestWidget(tripWithMembers));

      expect(find.text('Jun 1 — Jun 7'), findsOneWidget);
    });

    testWidgets('renders_destinationName_whenChosenProvided',
        (tester) async {
      await tester.pumpWidget(
          buildTestWidget(tripWithMembers, chosenDestinationName: 'Lisbon'));

      expect(find.text('Lisbon'), findsOneWidget);
      expect(find.text('Propose a destination'), findsNothing);
    });

    testWidgets('renders_emptyStateCta_whenChosenNull', (tester) async {
      await tester.pumpWidget(buildTestWidget(tripWithMembers));

      expect(find.text('Propose a destination'), findsOneWidget);
    });

    testWidgets('progressIndicator_destinationChosen_trueWhenChosenProvided',
        (tester) async {
      await tester.pumpWidget(
          buildTestWidget(tripWithMembers, chosenDestinationName: 'Lisbon'));

      final indicator = tester.widget<TripProgressIndicator>(
          find.byType(TripProgressIndicator));
      expect(indicator.destinationChosen, isTrue);
    });
  });
}
