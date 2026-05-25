import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol/patrol.dart';
import 'package:plantogether_app/app.dart';
import 'package:plantogether_app/core/utils/app_bloc_observer.dart';

/// Boots the full PlanTogether app inside a Patrol test.
/// Firebase is not initialized — tests connect directly to the backend via HTTP.
///
/// When [resetState] is true, all on-device state is cleared before the app
/// boots: the device UUID, the local display name and any other entries in
/// flutter_secure_storage. Use this for tests that depend on a fresh
/// onboarding flow or a clean profile.
Future<void> launchApp(PatrolTester $, {bool resetState = false}) async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (resetState) {
    await _resetDeviceState();
  }
  Bloc.observer = AppBlocObserver();
  await $.pumpWidget(const PlanTogetherApp());
  await $.pumpAndSettle();
}

Future<void> _resetDeviceState() async {
  const storage = FlutterSecureStorage();
  await storage.deleteAll();
}
