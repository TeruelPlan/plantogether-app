import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/core/network/stomp_client_manager.dart';
import 'package:plantogether_app/core/security/device_id_service.dart';
import 'package:plantogether_app/features/destination/domain/model/destination_model.dart';
import 'package:plantogether_app/features/destination/domain/repository/destination_repository.dart';
import 'package:plantogether_app/features/destination/presentation/bloc/destination_bloc.dart';
import 'package:plantogether_app/features/destination/presentation/bloc/destination_event.dart';
import 'package:plantogether_app/features/destination/presentation/bloc/destination_state.dart';

import '../../../helpers/fake_stomp_client_manager.dart';

class _MockRepository extends Mock implements DestinationRepository {}

class _MockDeviceIdService extends Mock implements DeviceIdService {}

void main() {
  const tripId = 'trip-1';
  final destination = DestinationModel(
    id: 'dest-1',
    tripId: tripId,
    name: 'Paris',
    proposedByDeviceId: 'device-1',
    createdAt: DateTime.utc(2026, 4, 1),
    updatedAt: DateTime.utc(2026, 4, 1),
  );

  late _MockRepository repo;
  late _MockDeviceIdService deviceIdService;
  late FakeStompClientManager fakeStomp;

  setUp(() {
    repo = _MockRepository();
    deviceIdService = _MockDeviceIdService();
    fakeStomp = FakeStompClientManager();

    when(() => repo.list(tripId)).thenAnswer((_) async => [destination]);
    when(() => deviceIdService.getOrCreateDeviceId())
        .thenAnswer((_) async => 'device-me');
  });

  DestinationBloc buildBloc() => DestinationBloc(
        repo,
        deviceIdService: deviceIdService,
        stompClientManager: fakeStomp,
      );

  Future<void> waitForLoaded(DestinationBloc bloc) async {
    await bloc.stream.firstWhere((s) => s is! _Nothing && s.maybeWhen(
          loaded: (_, _, _, _, _) => true,
          orElse: () => false,
        ));
    // Give _ensureStompSubscription a chance to complete (async gap after
    // the loaded emit) so the fake STOMP connection-state listener is wired.
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }

  test('DESTINATION_VOTE_CAST frame triggers a single reload after debounce',
      () async {
    final bloc = buildBloc();
    bloc.add(const LoadDestinations(tripId));
    await waitForLoaded(bloc);
    verify(() => repo.list(tripId)).called(1);

    fakeStomp.lastCallback!({
      'type': 'DESTINATION_VOTE_CAST',
      'tripId': tripId,
      'destinationId': destination.id,
    });

    await Future<void>.delayed(const Duration(milliseconds: 100));
    verifyNever(() => repo.list(tripId));

    await Future<void>.delayed(const Duration(milliseconds: 250));
    verify(() => repo.list(tripId)).called(1);

    await bloc.close();
  });

  test('bursts of frames coalesce into a single reload', () async {
    final bloc = buildBloc();
    bloc.add(const LoadDestinations(tripId));
    await waitForLoaded(bloc);
    clearInteractions(repo);
    when(() => repo.list(tripId)).thenAnswer((_) async => [destination]);

    for (int i = 0; i < 10; i++) {
      fakeStomp.lastCallback!({
        'type': 'DESTINATION_VOTE_CAST',
        'tripId': tripId,
        'destinationId': destination.id,
      });
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    await Future<void>.delayed(const Duration(milliseconds: 350));
    verify(() => repo.list(tripId)).called(1);

    await bloc.close();
  });

  test('frames for a different tripId are ignored', () async {
    final bloc = buildBloc();
    bloc.add(const LoadDestinations(tripId));
    await waitForLoaded(bloc);
    clearInteractions(repo);
    when(() => repo.list(tripId)).thenAnswer((_) async => [destination]);

    fakeStomp.lastCallback!({
      'type': 'DESTINATION_VOTE_CAST',
      'tripId': 'other-trip',
      'destinationId': destination.id,
    });

    await Future<void>.delayed(const Duration(milliseconds: 350));
    verifyNever(() => repo.list(any()));

    await bloc.close();
  });

  test('unknown event type is ignored', () async {
    final bloc = buildBloc();
    bloc.add(const LoadDestinations(tripId));
    await waitForLoaded(bloc);
    clearInteractions(repo);
    when(() => repo.list(tripId)).thenAnswer((_) async => [destination]);

    fakeStomp.lastCallback!({
      'type': 'POLL_VOTE_CAST',
      'tripId': tripId,
    });

    await Future<void>.delayed(const Duration(milliseconds: 350));
    verifyNever(() => repo.list(any()));

    await bloc.close();
  });

  test('reconnecting sets the connection banner', () async {
    final bloc = buildBloc();
    bloc.add(const LoadDestinations(tripId));
    await waitForLoaded(bloc);

    fakeStomp.stateController.add(StompConnectionState.reconnecting);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(
      bloc.state.maybeWhen(
        loaded: (_, _, _, banner, _) => banner,
        orElse: () => null,
      ),
      'Reconnecting…',
    );

    await bloc.close();
  });

  test('reconnect after drop triggers a reload and clears the banner',
      () async {
    final bloc = buildBloc();
    bloc.add(const LoadDestinations(tripId));
    await waitForLoaded(bloc);
    clearInteractions(repo);
    when(() => repo.list(tripId)).thenAnswer((_) async => [destination]);

    fakeStomp.stateController.add(StompConnectionState.reconnecting);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    fakeStomp.stateController.add(StompConnectionState.connected);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    verify(() => repo.list(tripId)).called(1);
    expect(
      bloc.state.maybeWhen(
        loaded: (_, _, _, banner, _) => banner,
        orElse: () => 'x',
      ),
      isNull,
    );

    await bloc.close();
  });

  test('initial connected after connecting does NOT trigger a second reload',
      () async {
    final bloc = buildBloc();
    bloc.add(const LoadDestinations(tripId));
    await waitForLoaded(bloc);
    clearInteractions(repo);
    when(() => repo.list(tripId)).thenAnswer((_) async => [destination]);

    fakeStomp.stateController.add(StompConnectionState.connecting);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    fakeStomp.stateController.add(StompConnectionState.connected);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    verifyNever(() => repo.list(any()));

    await bloc.close();
  });

  test('close() disconnects the STOMP subscription', () async {
    final bloc = buildBloc();
    bloc.add(const LoadDestinations(tripId));
    await waitForLoaded(bloc);

    final sub = fakeStomp.lastSubscription!;
    expect(sub.disconnectCalled, isFalse);

    await bloc.close();
    expect(sub.disconnectCalled, isTrue);
  });
}

class _Nothing {}
