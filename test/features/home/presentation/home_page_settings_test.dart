import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:plantogether_app/features/home/presentation/bloc/home_event.dart';
import 'package:plantogether_app/features/home/presentation/bloc/home_state.dart';
import 'package:plantogether_app/features/home/presentation/pages/home_page.dart';

/// Acceptance tests for Story 1.3 — AC4:
/// A gear icon (Settings) must be visible in the Home AppBar and
/// must be present so the user can navigate to /settings.
class MockHomeBloc extends MockBloc<HomeEvent, HomeState>
    implements HomeBloc {}

Widget _buildHomePage(HomeBloc bloc) {
  return MaterialApp(
    home: BlocProvider<HomeBloc>.value(
      value: bloc,
      child: const HomePage(),
    ),
  );
}

void main() {
  group('HomePage — Settings gear icon (AC4)', () {
    late MockHomeBloc mockBloc;

    setUp(() {
      mockBloc = MockHomeBloc();
    });

    tearDown(() {
      mockBloc.close();
    });

    testWidgets(
        '[1.3-WIDGET-005] gear icon (Icons.settings) is visible in AppBar',
        (WidgetTester tester) async {
      when(() => mockBloc.state)
          .thenReturn(const HomeState.loaded(trips: []));
      whenListen(mockBloc, Stream<HomeState>.empty());

      await tester.pumpWidget(_buildHomePage(mockBloc));
      await tester.pump();

      expect(
        find.byIcon(Icons.settings),
        findsOneWidget,
        reason: 'Settings gear icon must be present in the AppBar (AC4)',
      );
    });

    testWidgets(
        '[1.3-WIDGET-005] gear icon has tooltip "Settings"',
        (WidgetTester tester) async {
      when(() => mockBloc.state)
          .thenReturn(const HomeState.loaded(trips: []));
      whenListen(mockBloc, Stream<HomeState>.empty());

      await tester.pumpWidget(_buildHomePage(mockBloc));
      await tester.pump();

      final iconButton = find.widgetWithIcon(IconButton, Icons.settings);
      expect(iconButton, findsOneWidget);

      final widget = tester.widget<IconButton>(iconButton);
      expect(
        widget.tooltip,
        equals('Settings'),
        reason: 'Settings icon button must have tooltip "Settings"',
      );
    });

    testWidgets(
        '[1.3-WIDGET-005] gear icon is tappable (onPressed is not null)',
        (WidgetTester tester) async {
      when(() => mockBloc.state)
          .thenReturn(const HomeState.loaded(trips: []));
      whenListen(mockBloc, Stream<HomeState>.empty());

      await tester.pumpWidget(_buildHomePage(mockBloc));
      await tester.pump();

      final iconButton = find.widgetWithIcon(IconButton, Icons.settings);
      final widget = tester.widget<IconButton>(iconButton);

      expect(
        widget.onPressed,
        isNotNull,
        reason: 'Settings icon button must be enabled (onPressed not null)',
      );
    });
  });
}
