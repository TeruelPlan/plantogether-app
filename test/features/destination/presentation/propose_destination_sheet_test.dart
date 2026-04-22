import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/destination/domain/model/destination_model.dart';
import 'package:plantogether_app/features/destination/domain/repository/destination_repository.dart';
import 'package:plantogether_app/features/destination/presentation/bloc/destination_bloc.dart';
import 'package:plantogether_app/features/destination/presentation/widgets/propose_destination_sheet.dart';

class MockDestinationRepository extends Mock implements DestinationRepository {}

class FakeProposeInput extends Fake implements ProposeDestinationInput {}

void main() {
  late MockDestinationRepository mockRepository;
  late DestinationBloc bloc;

  setUpAll(() {
    registerFallbackValue(FakeProposeInput());
  });

  setUp(() {
    mockRepository = MockDestinationRepository();
    bloc = DestinationBloc(mockRepository);
  });

  tearDown(() => bloc.close());

  const tripId = 'trip-1';

  Widget buildWidget() {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(
          value: bloc,
          child: const ProposeDestinationSheet(tripId: tripId),
        ),
      ),
    );
  }

  testWidgets('shows inline error when name is blank and does not dispatch',
      (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.tap(find.text('Propose'));
    await tester.pump();

    expect(find.text('Destination name is required'), findsOneWidget);
    verifyNever(() => mockRepository.propose(any(), any()));
  });

  testWidgets('dispatches ProposeDestination event when name is valid',
      (tester) async {
    final destination = DestinationModel(
      id: 'd-1',
      tripId: tripId,
      name: 'Paris',
      proposedByDeviceId: 'device-1',
      createdAt: DateTime.utc(2026, 4, 1),
      updatedAt: DateTime.utc(2026, 4, 1),
    );
    when(() => mockRepository.propose(tripId, any()))
        .thenAnswer((_) async => destination);
    when(() => mockRepository.list(tripId))
        .thenAnswer((_) async => [destination]);

    await tester.pumpWidget(buildWidget());
    await tester.enterText(find.byType(TextFormField).first, 'Paris');

    await tester.tap(find.text('Propose'));
    await tester.pump();
    await tester.pump();

    final captured = verify(
      () => mockRepository.propose(tripId, captureAny()),
    ).captured;
    expect(captured, hasLength(1));
    final input = captured.single as ProposeDestinationInput;
    expect(input.name, 'Paris');
  });
}
