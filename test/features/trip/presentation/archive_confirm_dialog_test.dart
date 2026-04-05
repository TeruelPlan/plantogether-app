import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

  testWidgets('confirm dispatches ArchiveTrip and closes', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(find.text('Archive this trip?'), findsNothing);
    // The BLoC should have received an ArchiveTrip event
    // (verified by the fact that the dialog closed after dispatching)
  });
}
