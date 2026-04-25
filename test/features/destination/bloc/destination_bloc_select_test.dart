import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/destination/domain/model/destination_model.dart';
import 'package:plantogether_app/features/destination/domain/repository/destination_repository.dart';
import 'package:plantogether_app/features/destination/presentation/bloc/destination_bloc.dart';
import 'package:plantogether_app/features/destination/presentation/bloc/destination_event.dart';
import 'package:plantogether_app/features/destination/presentation/bloc/destination_state.dart';

class MockDestinationRepository extends Mock implements DestinationRepository {}

DestinationModel _destination(String id, {DestinationStatus status = DestinationStatus.proposed}) {
  return DestinationModel(
    id: id,
    tripId: 'trip-1',
    name: 'Dest $id',
    proposedByDeviceId: 'device-1',
    createdAt: DateTime.utc(2026, 4, 1),
    updatedAt: DateTime.utc(2026, 4, 1),
    status: status,
  );
}

void main() {
  late MockDestinationRepository repo;

  setUp(() {
    repo = MockDestinationRepository();
  });

  const tripId = 'trip-1';
  const destId = 'dest-1';
  const otherId = 'dest-2';

  group('DestinationBloc.SelectDestination', () {
    blocTest<DestinationBloc, DestinationState>(
      'selectDestination_success_emitsLoadedWithChosenStatus',
      build: () {
        when(() => repo.selectDestination(destId))
            .thenAnswer((_) async => _destination(destId, status: DestinationStatus.chosen));
        when(() => repo.list(tripId)).thenAnswer((_) async => [
              _destination(destId, status: DestinationStatus.chosen),
              _destination(otherId),
            ]);
        return DestinationBloc(repo);
      },
      act: (bloc) => bloc.add(
        const SelectDestination(tripId: tripId, destinationId: destId),
      ),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final chosen = bloc.state.chosenDestination;
        expect(chosen, isNotNull);
        expect(chosen!.id, destId);
      },
    );

    blocTest<DestinationBloc, DestinationState>(
      'selectDestination_switch_demotesPreviousInReloadedState',
      build: () {
        when(() => repo.selectDestination(otherId))
            .thenAnswer((_) async => _destination(otherId, status: DestinationStatus.chosen));
        when(() => repo.list(tripId)).thenAnswer((_) async => [
              _destination(destId), // demoted
              _destination(otherId, status: DestinationStatus.chosen),
            ]);
        return DestinationBloc(repo);
      },
      act: (bloc) => bloc.add(
        const SelectDestination(tripId: tripId, destinationId: otherId),
      ),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final chosen = bloc.state.chosenDestination;
        expect(chosen?.id, otherId);
      },
    );

    blocTest<DestinationBloc, DestinationState>(
      'selectDestination_409_emitsErrorThenKeepsState',
      build: () {
        // First seed the bloc into loaded state via LoadDestinations.
        when(() => repo.list(tripId)).thenAnswer((_) async => [_destination(destId)]);
        when(() => repo.selectDestination(destId)).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 409,
            ),
            type: DioExceptionType.badResponse,
          ),
        );
        return DestinationBloc(repo);
      },
      act: (bloc) async {
        bloc.add(const LoadDestinations(tripId));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const SelectDestination(tripId: tripId, destinationId: destId));
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        // After 409, transientError should be set on a loaded state.
        final transient = bloc.state.maybeWhen(
          loaded: (_, _, _, _, transientError) => transientError,
          orElse: () => null,
        );
        expect(transient, isNotNull);
      },
    );

    blocTest<DestinationBloc, DestinationState>(
      'selectDestination_nonOrganizerReceives403_emitsErrorState',
      build: () {
        when(() => repo.selectDestination(destId)).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 403,
            ),
            type: DioExceptionType.badResponse,
          ),
        );
        return DestinationBloc(repo);
      },
      act: (bloc) => bloc.add(
        const SelectDestination(tripId: tripId, destinationId: destId),
      ),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final isError = bloc.state.maybeWhen(
          error: (_) => true,
          orElse: () => false,
        );
        expect(isError, isTrue);
      },
    );
  });
}
