import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_model.dart';
import 'package:plantogether_app/features/trip/domain/repository/trip_repository.dart';
import 'package:plantogether_app/features/trip/presentation/bloc/trip_detail_bloc.dart';
import 'package:plantogether_app/features/trip/presentation/widgets/trip_edit_sheet.dart';

class MockTripRepository extends Mock implements TripRepository {}

void main() {
  late MockTripRepository mockRepository;
  late TripDetailBloc bloc;

  const trip = TripModel(
    id: 'trip-1',
    title: 'Beach Trip',
    description: 'Fun at the beach',
    status: 'PLANNING',
    referenceCurrency: 'EUR',
    createdBy: 'device-1',
    createdAt: '2026-01-01T00:00:00Z',
    memberCount: 1,
  );

  setUp(() {
    mockRepository = MockTripRepository();
    bloc = TripDetailBloc(mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  Widget buildWidget() {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(
          value: bloc,
          child: Builder(
            builder: (context) => FilledButton(
              onPressed: () => TripEditSheet.show(context, trip),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('form is pre-populated with trip data', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Title field pre-populated
    expect(
      find.widgetWithText(TextFormField, 'Beach Trip'),
      findsOneWidget,
    );
    // Description field pre-populated
    expect(
      find.widgetWithText(TextFormField, 'Fun at the beach'),
      findsOneWidget,
    );
    // Currency field pre-populated (hint also says EUR, so expect 2 matches)
    expect(
      find.widgetWithText(TextFormField, 'EUR'),
      findsWidgets,
    );
  });

  testWidgets('save button validates empty title', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Clear the title field
    final titleField = find.widgetWithText(TextFormField, 'Beach Trip');
    await tester.enterText(titleField, '');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Title is required'), findsOneWidget);
  });
}
