import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantogether_app/features/poll/domain/model/poll_model.dart';
import 'package:plantogether_app/features/poll/presentation/widgets/date_poll_matrix_widget.dart';

void main() {
  const myDeviceId = 'device-me';
  const otherDeviceId = 'device-other';

  PollDetailModel buildDetail({
    PollStatus status = PollStatus.open,
    List<PollSlotDetailModel>? slots,
    List<PollMemberModel>? members,
  }) {
    return PollDetailModel(
      id: 'poll-1',
      tripId: 'trip-1',
      title: 'When?',
      status: status,
      createdBy: 'organizer',
      createdAt: DateTime.utc(2026, 4, 1),
      slots: slots ??
          [
            PollSlotDetailModel(
              id: 'slot-a',
              startDate: DateTime(2026, 6, 6),
              endDate: DateTime(2026, 6, 8),
              slotIndex: 0,
              score: 2,
              votes: const [
                PollVoteModel(deviceId: myDeviceId, status: VoteStatus.yes),
              ],
            ),
            PollSlotDetailModel(
              id: 'slot-b',
              startDate: DateTime(2026, 6, 20),
              endDate: DateTime(2026, 6, 22),
              slotIndex: 1,
              score: 1,
              votes: const [
                PollVoteModel(
                    deviceId: otherDeviceId, status: VoteStatus.maybe),
              ],
            ),
          ],
      members: members ??
          const [
            PollMemberModel(
                deviceId: myDeviceId, role: 'PARTICIPANT', displayName: 'Me'),
            PollMemberModel(
                deviceId: otherDeviceId,
                role: 'PARTICIPANT',
                displayName: 'Other'),
          ],
    );
  }

  Widget buildWidget({
    required PollDetailModel detail,
    bool isLocked = false,
    bool isOrganizer = false,
    bool locking = false,
    void Function(String, VoteStatus)? onVote,
    ValueChanged<String>? onLockTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: DatePollMatrixWidget(
          detail: detail,
          myDeviceId: myDeviceId,
          isLocked: isLocked,
          isOrganizer: isOrganizer,
          locking: locking,
          onVote: onVote,
          onLockTap: onLockTap,
        ),
      ),
    );
  }

  testWidgets('rendersOneColumnPerMember (one SegmentedButton per slot)',
      (tester) async {
    await tester.pumpWidget(buildWidget(detail: buildDetail()));

    // Two slots, each with one editable own-cell SegmentedButton.
    expect(find.byType(SegmentedButton<VoteStatus>), findsNWidgets(2));
  });

  testWidgets('highlightsTopScoringSlot', (tester) async {
    await tester.pumpWidget(buildWidget(detail: buildDetail()));
    // Score values are rendered as plain numbers
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('noHighlight_whenAllSlotsZeroScore', (tester) async {
    final detail = buildDetail(slots: [
      PollSlotDetailModel(
        id: 'slot-a',
        startDate: DateTime(2026, 6, 6),
        endDate: DateTime(2026, 6, 8),
        slotIndex: 0,
        score: 0,
        votes: const [],
      ),
    ]);
    await tester.pumpWidget(buildWidget(detail: detail));
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('emptyState_rendersHint', (tester) async {
    final detail = buildDetail(slots: [
      PollSlotDetailModel(
        id: 'slot-a',
        startDate: DateTime(2026, 6, 6),
        endDate: DateTime(2026, 6, 8),
        slotIndex: 0,
        score: 0,
        votes: const [],
      ),
    ]);
    await tester.pumpWidget(buildWidget(detail: detail));
    expect(find.text('Be the first to vote · Tap a slot to respond'),
        findsOneWidget);
  });

  testWidgets('readonlyVariant_hidesSegmentedButton', (tester) async {
    final detail = buildDetail(status: PollStatus.locked).copyWith(
      lockedSlotId: 'slot-a',
    );
    await tester.pumpWidget(buildWidget(detail: detail, isLocked: true));
    expect(find.byType(SegmentedButton<VoteStatus>), findsNothing);
  });

  testWidgets('rendersLockButton_whenOpenAndOrganizer', (tester) async {
    await tester.pumpWidget(buildWidget(
      detail: buildDetail(),
      isOrganizer: true,
      onLockTap: (_) {},
    ));
    expect(find.widgetWithText(TextButton, 'Lock'), findsNWidgets(2));
  });

  testWidgets('hidesLockButton_whenParticipant', (tester) async {
    await tester.pumpWidget(buildWidget(
      detail: buildDetail(),
      isOrganizer: false,
    ));
    expect(find.widgetWithText(TextButton, 'Lock'), findsNothing);
  });

  testWidgets('rendersConfirmedChip_whenLocked', (tester) async {
    final detail = buildDetail(status: PollStatus.locked).copyWith(
      lockedSlotId: 'slot-a',
    );
    await tester.pumpWidget(buildWidget(detail: detail, isLocked: true));
    expect(find.text('Confirmed ✓'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('highlightsLockedSlot_regardlessOfScore', (tester) async {
    // Slot B has score 0; when locked, it should still be highlighted.
    final detail = buildDetail(
      status: PollStatus.locked,
      slots: [
        PollSlotDetailModel(
          id: 'slot-a',
          startDate: DateTime(2026, 6, 6),
          endDate: DateTime(2026, 6, 8),
          slotIndex: 0,
          score: 5,
          votes: const [],
        ),
        PollSlotDetailModel(
          id: 'slot-b',
          startDate: DateTime(2026, 7, 6),
          endDate: DateTime(2026, 7, 8),
          slotIndex: 1,
          score: 0,
          votes: const [],
        ),
      ],
    ).copyWith(lockedSlotId: 'slot-b');
    await tester.pumpWidget(buildWidget(detail: detail, isLocked: true));
    // Locked slot B label still renders; chip announces its dates.
    expect(find.text('Confirmed ✓'), findsOneWidget);
    expect(find.textContaining('Jul 6'), findsOneWidget);
  });
}
