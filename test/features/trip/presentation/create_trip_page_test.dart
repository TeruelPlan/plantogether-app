import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/trip/domain/repository/trip_repository.dart';
import 'package:plantogether_app/features/trip/presentation/bloc/create_trip_bloc.dart';
import 'package:plantogether_app/features/trip/presentation/pages/create_trip_page.dart';

class MockTripRepository extends Mock implements TripRepository {}

void main() {
  late MockTripRepository mockRepository;

  setUp(() {
    mockRepository = MockTripRepository();
  });

  Widget buildPage() {
    return MaterialApp(
      home: BlocProvider(
        create: (_) => CreateTripBloc(mockRepository),
        child: const CreateTripPage(),
      ),
    );
  }

  group('CreateTripPage', () {
    testWidgets('shows validation error when title is empty',
        (tester) async {
      await tester.pumpWidget(buildPage());

      // Tap submit without entering title
      await tester.tap(find.text('Create Trip'));
      await tester.pumpAndSettle();

      expect(find.text('Trip name is required'), findsOneWidget);
    });

    testWidgets('submit button is present', (tester) async {
      await tester.pumpWidget(buildPage());

      expect(find.text('Create Trip'), findsOneWidget);
    });

    testWidgets('currency dropdown shows options', (tester) async {
      await tester.pumpWidget(buildPage());

      await tester.tap(find.text('Currency (optional)'));
      await tester.pumpAndSettle();

      expect(find.text('EUR'), findsWidgets);
      expect(find.text('USD'), findsWidgets);
    });
  });
}
