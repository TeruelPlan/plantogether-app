import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/poll/data/datasource/poll_remote_datasource.dart';
import 'package:plantogether_app/features/poll/domain/repository/poll_repository.dart';
import 'package:plantogether_app/features/poll/presentation/bloc/poll_bloc.dart';
import 'package:plantogether_app/features/poll/presentation/widgets/create_poll_sheet.dart';

class MockPollRepository extends Mock implements PollRepository {}

class FakeSlotInput extends Fake implements SlotInput {}

void main() {
  late MockPollRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeSlotInput());
  });

  setUp(() {
    mockRepository = MockPollRepository();
  });

  const tripId = 'trip-1';

  Widget wrap(Widget child) {
    return MaterialApp(
      home: BlocProvider(
        create: (_) => PollBloc(mockRepository),
        child: Scaffold(body: child),
      ),
    );
  }

  testWidgets('submit with 0 slots shows inline error', (tester) async {
    await tester.pumpWidget(wrap(const CreatePollSheet(tripId: tripId)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Summer trip');
    await tester.tap(find.widgetWithText(FilledButton, 'Create poll'));
    await tester.pump();

    expect(find.text('At least 2 date slots are required'), findsOneWidget);
    verifyNever(() => mockRepository.createPoll(
          tripId: any(named: 'tripId'),
          title: any(named: 'title'),
          slots: any(named: 'slots'),
        ));
  });

  testWidgets('submit with no slots and no title shows slot-count error first',
      (tester) async {
    // Slot-count validation runs before the form validator, so submitting an
    // empty form surfaces the slot error rather than the title error.
    await tester.pumpWidget(wrap(const CreatePollSheet(tripId: tripId)));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Create poll'));
    await tester.pump();

    expect(find.text('At least 2 date slots are required'), findsOneWidget);
  });

  testWidgets('shows an "Add date slot" button so user can add slots',
      (tester) async {
    await tester.pumpWidget(wrap(const CreatePollSheet(tripId: tripId)));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'Add date slot'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Create poll'), findsOneWidget);
  });
}
