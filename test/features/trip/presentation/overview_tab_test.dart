import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_member_model.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_model.dart';
import 'package:plantogether_app/features/trip/presentation/widgets/overview_tab.dart';
import 'package:plantogether_app/features/trip/presentation/widgets/trip_summary_card.dart';
import 'package:plantogether_app/shared/widgets/member_avatar_stack.dart';

void main() {
  const tripWithMembers = TripModel(
    id: 'trip-1',
    title: 'Beach Trip',
    status: 'PLANNING',
    createdBy: 'device-1',
    createdAt: '2026-01-01T00:00:00Z',
    memberCount: 3,
    members: [
      TripMemberModel(
          memberId: 'member-1', displayName: 'Alice', role: 'OWNER', joinedAt: '2026-01-01', isMe: true),
      TripMemberModel(
          memberId: 'member-2', displayName: 'Bob', role: 'MEMBER', joinedAt: '2026-01-02', isMe: false),
      TripMemberModel(
          memberId: 'member-3', displayName: 'Charlie', role: 'MEMBER', joinedAt: '2026-01-03', isMe: false),
    ],
  );

  const tripNoDates = TripModel(
    id: 'trip-2',
    title: 'No Date Trip',
    status: 'PLANNING',
    createdBy: 'device-1',
    createdAt: '2026-01-01T00:00:00Z',
    memberCount: 1,
    members: [
      TripMemberModel(
          memberId: 'member-1', displayName: 'Alice', role: 'OWNER', joinedAt: '2026-01-01', isMe: true),
    ],
  );

  Widget buildTestWidget(TripModel trip) {
    return MaterialApp(
      home: DefaultTabController(
        length: 5,
        child: Scaffold(body: OverviewTab(trip: trip)),
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
  });
}
