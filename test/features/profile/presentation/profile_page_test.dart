import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/profile/domain/model/user_profile.dart';
import 'package:plantogether_app/features/profile/domain/repository/profile_repository.dart';
import 'package:plantogether_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:plantogether_app/features/profile/presentation/bloc/profile_state.dart';
import 'package:plantogether_app/features/profile/presentation/page/profile_page.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  group('ProfilePage', () {
    late MockProfileRepository mockRepository;

    setUp(() {
      mockRepository = MockProfileRepository();
    });

    testWidgets('renders display name on profileLoaded', (WidgetTester tester) async {

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => ProfileBloc(mockRepository),
            child: const ProfilePage(),
          ),
        ),
      );

      // Initial state is loading
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Simulate BLoC state change
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => _TestProfileBloc(),
            child: const ProfilePage(),
          ),
        ),
      );

      // Wait for widget rebuild
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsWidgets);
    });

    testWidgets('save button is disabled when name is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => _TestProfileBloc(),
            child: const ProfilePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and clear the text field
      final textField = find.byType(TextField);
      await tester.enterText(textField, '');
      await tester.pumpAndSettle();

      // Save button should be disabled
      final saveButton = find.byType(ElevatedButton);
      expect(tester.widget<ElevatedButton>(saveButton).onPressed, isNull);
    });

    testWidgets('snackbar appears on profileUpdateSuccess',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => _UpdateSuccessProfileBloc(),
            child: const ProfilePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Profile updated'), findsOneWidget);
    });
  });
}

class _TestProfileBloc extends ProfileBloc {
  _TestProfileBloc()
      : super(MockProfileRepository() as ProfileRepository) {
    emit(const ProfileState.loaded(
      UserProfile(displayName: 'Alice', avatarUrl: null),
    ));
  }
}

class _UpdateSuccessProfileBloc extends ProfileBloc {
  _UpdateSuccessProfileBloc()
      : super(MockProfileRepository() as ProfileRepository) {
    emit(const ProfileState.updateSuccess(
      UserProfile(displayName: 'Alice', avatarUrl: null),
    ));
  }
}
