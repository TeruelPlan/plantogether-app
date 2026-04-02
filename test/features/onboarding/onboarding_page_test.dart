import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/core/security/device_id_service.dart';
import 'package:plantogether_app/features/onboarding/presentation/pages/onboarding_page.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

Widget buildTestWidget({
  required DeviceIdService deviceIdService,
  required VoidCallback onComplete,
}) {
  final router = GoRouter(
    initialLocation: '/test',
    routes: [
      GoRoute(
        path: '/test',
        builder: (ctx, state) => RepositoryProvider.value(
          value: deviceIdService,
          child: OnboardingPage(onComplete: onComplete),
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (ctx, state) =>
            const Scaffold(body: Text('Home')),
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late DeviceIdService deviceIdService;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    deviceIdService = DeviceIdService(storage: mockStorage);
  });

  testWidgets('renders text field and Get started button', (tester) async {
    await tester.pumpWidget(buildTestWidget(
      deviceIdService: deviceIdService,
      onComplete: () {},
    ));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('submit button is disabled when text field is empty',
      (tester) async {
    await tester.pumpWidget(buildTestWidget(
      deviceIdService: deviceIdService,
      onComplete: () {},
    ));
    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Get started'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('shows validator error when name exceeds 50 characters',
      (tester) async {
    await tester.pumpWidget(buildTestWidget(
      deviceIdService: deviceIdService,
      onComplete: () {},
    ));
    await tester.pumpAndSettle();

    final longName = 'A' * 51;
    await tester.enterText(find.byType(TextFormField), longName);
    await tester.pump();

    // Trigger form validation by tapping the button (now enabled since text is non-empty)
    await tester.tap(find.widgetWithText(ElevatedButton, 'Get started'));
    await tester.pump();

    expect(find.text('Max 50 characters'), findsOneWidget);
  });

  testWidgets('submit button remains disabled when only whitespace is entered',
      (tester) async {
    await tester.pumpWidget(buildTestWidget(
      deviceIdService: deviceIdService,
      onComplete: () {},
    ));
    await tester.pumpAndSettle();

    // A whitespace-only entry trims to empty, so the button should stay disabled
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.pump();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Get started'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('calls setDisplayName and onComplete on valid submit',
      (tester) async {
    when(() => mockStorage.write(
          key: 'display_name',
          value: 'Alice',
        )).thenAnswer((_) async {});

    var onCompleteCalled = false;

    await tester.pumpWidget(buildTestWidget(
      deviceIdService: deviceIdService,
      onComplete: () => onCompleteCalled = true,
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Alice');
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Get started'));
    await tester.pumpAndSettle();

    verify(() => mockStorage.write(key: 'display_name', value: 'Alice'))
        .called(1);
    expect(onCompleteCalled, isTrue);
  });
}
