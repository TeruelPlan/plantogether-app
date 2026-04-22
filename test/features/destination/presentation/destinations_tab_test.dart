import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/destination/domain/model/destination_model.dart';
import 'package:plantogether_app/features/destination/domain/repository/destination_repository.dart';
import 'package:plantogether_app/features/destination/presentation/bloc/destination_bloc.dart';
import 'package:plantogether_app/features/destination/presentation/widgets/destination_proposal_card.dart';
import 'package:plantogether_app/features/destination/presentation/widgets/destinations_tab.dart';

class MockDestinationRepository extends Mock implements DestinationRepository {}

void main() {
  late MockDestinationRepository mockRepository;

  setUp(() {
    mockRepository = MockDestinationRepository();
  });

  const tripId = 'trip-1';
  final sample = DestinationModel(
    id: 'd-1',
    tripId: tripId,
    name: 'Paris',
    description: 'City of lights',
    proposedByDeviceId: 'device-1',
    createdAt: DateTime.utc(2026, 4, 1),
    updatedAt: DateTime.utc(2026, 4, 1),
  );

  Widget buildWidget() {
    return MaterialApp(
      home: BlocProvider(
        create: (_) => DestinationBloc(mockRepository),
        child: const DestinationsTab(tripId: tripId),
      ),
    );
  }

  testWidgets('renders empty state when no destinations', (tester) async {
    when(() => mockRepository.list(tripId)).thenAnswer((_) async => const []);

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(
      find.text('Where are you going? · Propose a destination'),
      findsOneWidget,
    );
    expect(find.text('Propose destination'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('renders one card per destination', (tester) async {
    when(() => mockRepository.list(tripId))
        .thenAnswer((_) async => [sample]);

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.byType(DestinationProposalCard), findsOneWidget);
    expect(find.text('Paris'), findsOneWidget);
  });

  testWidgets('renders loading indicator before data resolves',
      (tester) async {
    final completer = Completer<List<DestinationModel>>();
    when(() => mockRepository.list(tripId))
        .thenAnswer((_) => completer.future);

    await tester.pumpWidget(buildWidget());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(const []);
    await tester.pumpAndSettle();
  });
}
