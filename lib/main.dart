import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/config/firebase_config.dart';
import 'package:smartshopper_mobile/config/routes.dart';
import 'package:smartshopper_mobile/providers/firestore_auth_provider.dart';
import 'package:smartshopper_mobile/providers/notification_preferences_provider.dart';
import 'package:smartshopper_mobile/providers/notifications_provider.dart';
import 'package:smartshopper_mobile/providers/theme_provider.dart';
import 'package:smartshopper_mobile/services/fcm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartshopper_mobile/screens/home/home_screen.dart';
import 'package:smartshopper_mobile/screens/auth/firebase_auth_screen.dart';

// Global navigatorKey for handling push notification navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global container for FCM initialization before ProviderScope
late final ProviderContainer _container;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  
  // Create a container to access providers before the app starts
  _container = ProviderContainer();

  await _container.read(notificationPreferencesProvider.notifier).loadFromStorage();
  final notificationPreferences = _container.read(notificationPreferencesProvider);
  
  // Initialize FCM with notification handling
  await initializeFCM(
    onNotificationTap: _handleNotificationTap,
    preferences: notificationPreferences,
    onNotificationReceived: (notification) {
      final preferences = _container.read(notificationPreferencesProvider);
      if (!preferences.allowsNotificationType(notification.type)) {
        return;
      }

      _container.read(notificationsProvider.notifier).addNotification(notification);
    },
  );

  await _maybeGenerateWeeklyDigest();
  
  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _maybeGenerateWeeklyDigest() async {
  final preferences = _container.read(notificationPreferencesProvider);
  if (!preferences.weeklyDigest) return;

  final prefs = await SharedPreferences.getInstance();
  const lastDigestKey = 'weekly_digest_last_sent_at';
  final lastDigestIso = prefs.getString(lastDigestKey);
  final now = DateTime.now();

  if (lastDigestIso != null) {
    final lastDigest = DateTime.tryParse(lastDigestIso);
    if (lastDigest != null && now.difference(lastDigest).inDays < 7) {
      return;
    }
  }

  final userIdString = _container.read(currentUserIdProvider) ?? '';

  _container.read(notificationsProvider.notifier).addWeeklyDigestNotification(
        userId: int.tryParse(userIdString) ?? 0,
      );

  await prefs.setString(lastDigestKey, now.toIso8601String());
}

/// Handle notification tap navigation
void _handleNotificationTap(String? route, Map<String, dynamic>? data) {
  if (route == null) return;
  
  print('🔔 Handling notification tap: $route');
  
  // Navigate to the appropriate screen
  navigatorKey.currentState?.pushNamed(
    route,
    arguments: data,
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(notificationPreferencesProvider, (previous, next) {
      FCMService().updatePreferences(next);
    });

    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'SmartShopper',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      onGenerateRoute: RoutesConfig.generateRoute,
      home: const AuthGuard(),
      navigatorKey: navigatorKey,
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
