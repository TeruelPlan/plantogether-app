import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app.dart';
import 'core/utils/app_bloc_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initFirebase();
  Bloc.observer = AppBlocObserver();
  runApp(const PlanTogetherApp());
}

/// Initializes Firebase. Fails silently during development when platform config
/// files (google-services.json / GoogleService-Info.plist) are not yet present.
/// Run `flutterfire configure` to generate firebase_options.dart and the
/// platform files before enabling push notifications (Epic 8).
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // ignore: avoid_print
    print('[Firebase] Not configured — push notifications disabled. '
        'Run `flutterfire configure` to set up FCM. Error: $e');
  }
}
