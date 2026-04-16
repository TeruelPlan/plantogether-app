import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_model.dart';
import 'package:plantogether_app/features/trip/domain/repository/trip_repository.dart';
import 'package:plantogether_app/features/trip/presentation/bloc/trip_detail_bloc.dart';
import 'package:plantogether_app/features/trip/presentation/widgets/archive_confirm_dialog.dart';

class MockTripRepository extends Mock implements TripRepository {}

void main() {
  late MockTripRepository mockRepository;
  late TripDetailBloc bloc;

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
              onPressed: () => ArchiveConfirmDialog.show(context, 'trip-1'),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('cancel closes dialog without dispatching', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Archive this trip?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Archive this trip?'), findsNothing);
  });

  testWidgets('confirm dispatches ArchiveTrip and shows loading',
      (tester) async {
    // archiveTrip never completes — simulates in-flight request
    when(() => mockRepository.archiveTrip('trip-1'))
        .thenAnswer((_) async => Future<TripModel>.delayed(
              const Duration(seconds: 10),
              () => TripModel(
                id: 'trip-1',
                title: 'Trip',
                status: 'ARCHIVED',
                referenceCurrency: 'EUR',
                createdBy: 'device-1',
                createdAt: DateTime.utc(2026, 1, 1),
                memberCount: 1,
              ),
            ));

    await tester.pumpWidget(buildWidget());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Archive'));
    await tester.pump();

    // Dialog stays open with loading indicator
    expect(find.text('Archive this trip?'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
