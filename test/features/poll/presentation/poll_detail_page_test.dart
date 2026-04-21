import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/core/network/stomp_client_manager.dart';
import 'package:plantogether_app/core/security/device_id_service.dart';
import 'package:plantogether_app/features/poll/domain/model/poll_model.dart';
import 'package:plantogether_app/features/poll/domain/repository/poll_repository.dart';
import 'package:plantogether_app/features/poll/presentation/bloc/poll_detail_bloc.dart';
import 'package:plantogether_app/features/poll/presentation/pages/poll_detail_page.dart';
import 'package:plantogether_app/features/poll/presentation/widgets/date_poll_matrix_widget.dart';

class MockPollRepository extends Mock implements PollRepository {}

class MockDeviceIdService extends Mock implements DeviceIdService {}

class FakeStompClientManager implements StompClientManager {
  @override
  Future<TripStompSubscription> connect({
    required String endpointPath,
    required String tripId,
    required void Function(Map<String, dynamic>) onTripUpdate,
  }) async {
    return _NoopSubscription();
  }
}

class _NoopSubscription implements TripStompSubscription {
  @override
  Stream<StompConnectionState> get connectionState => const Stream.empty();

  @override
  void disconnect() {}
}

void main() {
  late MockPollRepository mockRepository;
  late MockDeviceIdService mockDeviceIdService;
  late FakeStompClientManager fakeStomp;

  const pollId = 'poll-1';
  const tripId = 'trip-1';
  const myDeviceId = 'device-me';
  const slotId = 'slot-a';

  PollDetailModel buildDetail({
    PollStatus status = PollStatus.open,
    String role = 'PARTICIPANT',
    String? lockedSlotId,
  }) {
    return PollDetailModel(
      id: pollId,
      tripId: tripId,
      title: 'Summer?',
      status: status,
      lockedSlotId: lockedSlotId,
      createdBy: 'organizer',
      createdAt: DateTime.utc(2026, 4, 1),
      slots: [
        PollSlotDetailModel(
          id: slotId,
          startDate: DateTime(2026, 6, 6),
          endDate: DateTime(2026, 6, 8),
          slotIndex: 0,
          score: 0,
          votes: const [],
        ),
      ],
      members: [
        PollMemberModel(
            deviceId: myDeviceId, role: role, displayName: 'Me'),
      ],
    );
  }

  setUp(() {
    mockRepository = MockPollRepository();
    mockDeviceIdService = MockDeviceIdService();
    fakeStomp = FakeStompClientManager();
    when(() => mockDeviceIdService.getOrCreateDeviceId())
        .thenAnswer((_) async => myDeviceId);
  });

  Widget buildPage() => MaterialApp(
        home: BlocProvider(
          create: (_) =>
              PollDetailBloc(mockRepository, mockDeviceIdService, fakeStomp),
          child: const PollDetailPage(pollId: pollId),
        ),
      );

  testWidgets('renders matrix when state is loaded', (tester) async {
    when(() => mockRepository.getPollDetail(pollId))
        .thenAnswer((_) async => buildDetail());

    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    expect(find.byType(DatePollMatrixWidget), findsOneWidget);
    expect(find.text('Summer?'), findsOneWidget);
    expect(find.text('OPEN'), findsOneWidget);
  });

  testWidgets('LOCKED poll hides SegmentedButton (readonly variant)',
      (tester) async {
    when(() => mockRepository.getPollDetail(pollId)).thenAnswer((_) async =>
        buildDetail(status: PollStatus.locked, lockedSlotId: slotId));

    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    expect(find.text('LOCKED'), findsOneWidget);
    expect(find.byType(SegmentedButton<VoteStatus>), findsNothing);
    expect(find.text('Confirmed ✓'), findsOneWidget);
  });

  testWidgets('tapLock_showsConfirmationDialog', (tester) async {
    when(() => mockRepository.getPollDetail(pollId))
        .thenAnswer((_) async => buildDetail(role: 'ORGANIZER'));

    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Lock'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('Lock '), findsWidgets);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('cancelDialog_doesNotDispatch', (tester) async {
    when(() => mockRepository.getPollDetail(pollId))
        .thenAnswer((_) async => buildDetail(role: 'ORGANIZER'));

    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Lock'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() =>
        mockRepository.lockPoll(pollId: any(named: 'pollId'), slotId: any(named: 'slotId')));
  });

  testWidgets('confirmDialog_dispatchesLockPoll', (tester) async {
    when(() => mockRepository.getPollDetail(pollId))
        .thenAnswer((_) async => buildDetail(role: 'ORGANIZER'));
    when(() => mockRepository.lockPoll(pollId: pollId, slotId: slotId))
        .thenAnswer((_) async =>
            buildDetail(status: PollStatus.locked, lockedSlotId: slotId));

    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Lock'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Lock'));
    await tester.pumpAndSettle();

    verify(() => mockRepository.lockPoll(pollId: pollId, slotId: slotId))
        .called(1);
  });

  testWidgets('lockedPoll_hidesAllLockButtons', (tester) async {
    when(() => mockRepository.getPollDetail(pollId)).thenAnswer((_) async =>
        buildDetail(
            status: PollStatus.locked,
            role: 'ORGANIZER',
            lockedSlotId: slotId));

    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextButton, 'Lock'), findsNothing);
  });
}
