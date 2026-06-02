import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Initialize Firebase with platform-specific options
Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
