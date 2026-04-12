import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/profile/domain/model/user_profile.dart';
import 'package:plantogether_app/features/profile/domain/repository/profile_repository.dart';
import 'package:plantogether_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:plantogether_app/features/profile/presentation/page/profile_page.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

const _alice = UserProfile(displayName: 'Alice', avatarUrl: null);

void main() {
  group('ProfilePage', () {
    late MockProfileRepository mockRepository;

    setUp(() {
      mockRepository = MockProfileRepository();
    });

    testWidgets('renders display name on profileLoaded', (WidgetTester tester) async {
      when(() => mockRepository.getMyProfile()).thenAnswer((_) async => _alice);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => ProfileBloc(mockRepository),
            child: const ProfilePage(),
          ),
        ),
      );

      // Let the post-frame callback fire and the BLoC load the profile.
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsWidgets);
    });

    testWidgets('save button is disabled when name is empty',
        (WidgetTester tester) async {
      when(() => mockRepository.getMyProfile()).thenAnswer((_) async => _alice);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => ProfileBloc(mockRepository),
            child: const ProfilePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Clear the text field.
      final textField = find.byType(TextField);
      await tester.enterText(textField, '');
      await tester.pumpAndSettle();

      // Save button should be disabled when the field is empty.
      final saveButton = find.byType(ElevatedButton);
      expect(tester.widget<ElevatedButton>(saveButton).onPressed, isNull);
    });

    testWidgets('snackbar appears on profileUpdateSuccess',
        (WidgetTester tester) async {
      when(() => mockRepository.getMyProfile()).thenAnswer((_) async => _alice);
      when(() => mockRepository.updateMyProfile('Alice'))
          .thenAnswer((_) async => _alice);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => ProfileBloc(mockRepository),
            child: const ProfilePage(),
          ),
        ),
      );

      // Wait for profile to load (text field will contain 'Alice').
      await tester.pumpAndSettle();

      // Tap save — name is non-empty so the button is enabled.
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Profile updated'), findsOneWidget);
    });
  });
}
