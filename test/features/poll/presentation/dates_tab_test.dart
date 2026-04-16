import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/poll/domain/model/poll_model.dart';
import 'package:plantogether_app/features/poll/domain/repository/poll_repository.dart';
import 'package:plantogether_app/features/poll/presentation/bloc/poll_bloc.dart';
import 'package:plantogether_app/features/poll/presentation/widgets/dates_tab.dart';
import 'package:plantogether_app/features/poll/presentation/widgets/poll_card.dart';

class MockPollRepository extends Mock implements PollRepository {}

void main() {
  late MockPollRepository mockRepository;

  setUp(() {
    mockRepository = MockPollRepository();
  });

  const tripId = 'trip-1';
  const samplePoll = PollModel(
    id: 'poll-1',
    tripId: tripId,
    title: 'When to leave?',
    status: PollStatus.open,
    createdBy: 'device-1',
    createdAt: '2026-04-01T00:00:00Z',
    slots: [
      PollSlotModel(
          id: 's1', startDate: '2026-06-01', endDate: '2026-06-07', slotIndex: 0),
      PollSlotModel(
          id: 's2', startDate: '2026-06-15', endDate: '2026-06-21', slotIndex: 1),
    ],
  );

  Widget buildWidget() {
    return MaterialApp(
      home: BlocProvider(
        create: (_) => PollBloc(mockRepository),
        child: const DatesTab(tripId: tripId),
      ),
    );
  }

  testWidgets('renders empty state when no polls', (tester) async {
    when(() => mockRepository.getPollsForTrip(tripId))
        .thenAnswer((_) async => const []);

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('No date poll yet'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('renders PollCard for each poll when loaded', (tester) async {
    when(() => mockRepository.getPollsForTrip(tripId))
        .thenAnswer((_) async => const [samplePoll]);

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.byType(PollCard), findsOneWidget);
    expect(find.text('When to leave?'), findsOneWidget);
  });

  testWidgets('shows progress indicator while loading', (tester) async {
    when(() => mockRepository.getPollsForTrip(tripId))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return const [samplePoll];
    });

    await tester.pumpWidget(buildWidget());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
  });
}
