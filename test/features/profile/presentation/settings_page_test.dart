import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/profile/presentation/bloc/settings_bloc.dart';
import 'package:plantogether_app/features/profile/presentation/bloc/settings_event.dart';
import 'package:plantogether_app/features/profile/presentation/bloc/settings_state.dart';
import 'package:plantogether_app/features/profile/presentation/page/settings_page.dart';

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

Widget _buildPage(SettingsBloc bloc) {
  return MaterialApp(
    home: BlocProvider<SettingsBloc>.value(
      value: bloc,
      child: const SettingsPage(),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const LoadSettings());
  });

  group('SettingsPage', () {
    late MockSettingsBloc mockBloc;

    setUp(() {
      mockBloc = MockSettingsBloc();
    });

    tearDown(() {
      mockBloc.close();
    });

    testWidgets('renders TextField pre-filled on loaded state',
        (WidgetTester tester) async {
      when(() => mockBloc.state)
          .thenReturn(const SettingsState.initial());
      whenListen(
        mockBloc,
        Stream.fromIterable([
          const SettingsState.loading(),
          const SettingsState.loaded(displayName: 'Alice'),
        ]),
      );

      await tester.pumpWidget(_buildPage(mockBloc));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Alice'), findsOneWidget);
    });

    testWidgets('save button is disabled while in saving state',
        (WidgetTester tester) async {
      when(() => mockBloc.state)
          .thenReturn(const SettingsState.saving());
      whenListen(mockBloc, Stream<SettingsState>.empty());

      await tester.pumpWidget(_buildPage(mockBloc));
      await tester.pump();

      final saveButton = find.byType(ElevatedButton);
      expect(tester.widget<ElevatedButton>(saveButton).onPressed, isNull);
    });

    testWidgets('snackbar "Display name updated" shown on saved state',
        (WidgetTester tester) async {
      when(() => mockBloc.state)
          .thenReturn(const SettingsState.initial());
      whenListen(
        mockBloc,
        Stream.fromIterable([
          const SettingsState.saved(displayName: 'Bob'),
        ]),
      );

      await tester.pumpWidget(_buildPage(mockBloc));
      await tester.pumpAndSettle();

      expect(find.text('Display name updated'), findsOneWidget);
    });

    testWidgets(
        'error text "Display name is required" shown after typing then clearing',
        (WidgetTester tester) async {
      when(() => mockBloc.state)
          .thenReturn(const SettingsState.loaded(displayName: 'Alice'));
      whenListen(mockBloc, Stream<SettingsState>.empty());

      await tester.pumpWidget(_buildPage(mockBloc));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'something');
      await tester.pump();
      await tester.enterText(textField, '');
      await tester.pump();

      expect(find.text('Display name is required'), findsOneWidget);

      // AC3: tapping Save with empty field must NOT dispatch SaveDisplayName
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      verifyNever(() => mockBloc.add(any(that: isA<SaveDisplayName>())));
    });
  });
}
