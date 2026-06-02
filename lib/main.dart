import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/config/firebase_config.dart';
import 'package:smartshopper_mobile/config/routes.dart';
import 'package:smartshopper_mobile/providers/firestore_auth_provider.dart';
import 'package:smartshopper_mobile/providers/theme_provider.dart';
import 'package:smartshopper_mobile/screens/home/home_screen.dart';
import 'package:smartshopper_mobile/screens/auth/firebase_auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'SmartShopper',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      onGenerateRoute: RoutesConfig.generateRoute,
      home: const AuthGuard(),
      navigatorObservers: [AppRouteObserver()],
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Auth Guard - Shows appropriate screen based on auth state
class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(firestoreAuthStateProvider);

    return authState.when(
      data: (user) {
        // We always show HomeScreenWrapper now. 
        // Inside HomeScreen, we handle the Guest vs Logged-in UI.
        return const HomeScreenWrapper();
      },
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Connection Error',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unable to reach Firebase. Check your internet connection and try again.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Invalidate the auth provider to retry the stream
                      ref.invalidate(firestoreAuthStateProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Home Screen Wrapper
class HomeScreenWrapper extends StatelessWidget {
  const HomeScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}

/// Firebase Auth Screen Wrapper
class FirebaseAuthScreenWrapper extends StatelessWidget {
  const FirebaseAuthScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const FirebaseAuthScreen();
  }
}
