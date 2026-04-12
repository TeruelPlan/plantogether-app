import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/core/constants/route_constants.dart';
import 'package:plantogether_app/core/router/app_router.dart';
import 'package:plantogether_app/core/security/device_id_service.dart';
import 'package:plantogether_app/features/trip/domain/repository/trip_repository.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockTripRepository extends Mock implements TripRepository {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late MockTripRepository mockTripRepository;
  late DeviceIdService deviceIdService;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    mockTripRepository = MockTripRepository();
    deviceIdService = DeviceIdService(storage: mockStorage);
    when(() => mockTripRepository.listTrips()).thenAnswer((_) async => []);
  });

  Widget buildWithRouter(AppRouter appRouter) => MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: deviceIdService),
          RepositoryProvider<TripRepository>.value(value: mockTripRepository),
        ],
        child: MaterialApp.router(routerConfig: appRouter.router),
      );

  group('AppRouter redirect guard', () {
    testWidgets('redirects to /onboarding on first launch (no display_name)',
        (tester) async {
      when(() => mockStorage.read(key: 'device_id'))
          .thenAnswer((_) async => 'existing-device-id');
      when(() => mockStorage.read(key: 'display_name'))
          .thenAnswer((_) async => null);

      final appRouter = AppRouter(deviceIdService: deviceIdService);
      addTearDown(appRouter.router.dispose);

      await tester.pumpWidget(buildWithRouter(appRouter));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to PlanTogether'), findsOneWidget);
    });

    testWidgets('navigates directly to /home when display_name is set',
        (tester) async {
      when(() => mockStorage.read(key: 'device_id'))
          .thenAnswer((_) async => 'existing-device-id');
      when(() => mockStorage.read(key: 'display_name'))
          .thenAnswer((_) async => 'Alice');

      final appRouter = AppRouter(deviceIdService: deviceIdService);
      addTearDown(appRouter.router.dispose);

      await tester.pumpWidget(buildWithRouter(appRouter));
      await tester.pumpAndSettle();

      expect(find.text('PlanTogether'), findsOneWidget);
    });

    testWidgets('redirects to /home after completing onboarding',
        (tester) async {
      when(() => mockStorage.read(key: 'device_id'))
          .thenAnswer((_) async => 'existing-device-id');
      when(() => mockStorage.read(key: 'display_name'))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(key: 'display_name', value: 'Bob'))
          .thenAnswer((_) async {});

      final appRouter = AppRouter(deviceIdService: deviceIdService);
      addTearDown(appRouter.router.dispose);

      await tester.pumpWidget(buildWithRouter(appRouter));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to PlanTogether'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Bob');
      await tester.pump();
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();

      expect(find.text('PlanTogether'), findsOneWidget);
    });
  });

  group('RouteConstants', () {
    test('splash route constant is /', () {
      expect(RouteConstants.splash, equals('/'));
    });

    test('onboarding route constant is /onboarding', () {
      expect(RouteConstants.onboarding, equals('/onboarding'));
    });

    test('home route constant is /home', () {
      expect(RouteConstants.home, equals('/home'));
    });
  });
}
