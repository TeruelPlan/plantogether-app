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
    void Function(String, VoteStatus)? onVote,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: DatePollMatrixWidget(
          detail: detail,
          myDeviceId: myDeviceId,
          isLocked: isLocked,
          onVote: onVote,
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

  testWidgets('LOCKED poll disables SegmentedButton', (tester) async {
    await tester.pumpWidget(buildWidget(
      detail: buildDetail(status: PollStatus.locked),
      isLocked: true,
    ));
    final segment = tester.widget<SegmentedButton<VoteStatus>>(
        find.byType(SegmentedButton<VoteStatus>).first);
    expect(segment.onSelectionChanged, isNull);
  });
}
