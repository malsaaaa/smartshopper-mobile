import 'package:flutter/material.dart';
import 'package:smartshopper_mobile/screens/auth/index.dart';
import 'package:smartshopper_mobile/screens/auth/firebase_auth_screen.dart';
import 'package:smartshopper_mobile/screens/home/home_screen.dart';
import 'package:smartshopper_mobile/screens/products/index.dart';
import 'package:smartshopper_mobile/screens/profile/index.dart';
import 'package:smartshopper_mobile/screens/notifications/discount_notifications_demo.dart';

/// Central route configuration for the app
class RoutesConfig {
  // Private constructor
  RoutesConfig._();

  // ============== ROUTE PATHS ==============
  static const String firebaseAuth = '/firebase-auth';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String allPrices = '/all-prices';
  static const String accountSettings = '/account-settings';
  static const String notifications = '/notifications';
  static const String favorites = '/favorites';
  static const String discountNotificationsDemo = '/discount-notifications-demo';
  static const String about = '/about';
  static const String productSearch = '/product-search';
  static const String productDetails = '/product-details';

  /// Initial route
  static const String initialRoute = home;

  /// Generate routes dynamically
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Root route - redirect to home
      case '/':
        return _buildRoute(const HomeScreen(), 
          const RouteSettings(name: home));

      // Firebase Auth Route
      case firebaseAuth:
        return _buildRoute(const FirebaseAuthScreen(), settings);

      // Auth Routes
      case login:
        return _buildRoute(const LoginScreen(), settings);
      case register:
        return _buildRoute(const RegisterScreen(), settings);
      case forgotPassword:
        return _buildRoute(const ForgotPasswordScreen(), settings);

      // Home/Main Routes
      case home:
        final args = settings.arguments as Map<String, dynamic>?;
        final initialTab = args != null && args['initialTab'] is int ? args['initialTab'] as int : 0;
        return _buildRoute(HomeScreen(initialTab: initialTab), settings);

      // Product Routes
      case allPrices:
        return _buildRoute(const AllPricesScreen(), settings);
      case productSearch:
        return _buildRoute(const ProductSearchScreen(), settings);
      case productDetails:
        final productId = (settings.arguments as int?) ?? 1;
        return _buildRoute(
          ProductDetailsScreen(productId: productId),
          settings,
        );

      // Profile Routes
      case accountSettings:
        return _buildRoute(const AccountSettingsScreen(), settings);
      case favorites:
        return _buildRoute(const FavoritesScreen(), settings);
      case notifications:
        return _buildRoute(const NotificationsScreen(), settings);
      case discountNotificationsDemo:
        return _buildRoute(const DiscountNotificationsDemoScreen(), settings);
      case about:
        return _buildRoute(const AboutScreen(), settings);

      // 404 Not Found
      default:
        return _buildRoute(
          _NotFoundScreen(routeName: settings.name ?? 'Unknown'),
          settings,
        );
    }
  }

  /// Build a material page route with slide transition
  static MaterialPageRoute<T> _buildRoute<T>(
    Widget widget,
    RouteSettings settings,
  ) {
    return MaterialPageRoute(
      builder: (_) => widget,
      settings: settings,
      fullscreenDialog: false,
    );
  }

  /// Navigate to a route
  static void navigate(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replacement = false,
  }) {
    if (replacement) {
      Navigator.pushReplacementNamed(
        context,
        routeName,
        arguments: arguments,
      );
    } else {
      Navigator.pushNamed(
        context,
        routeName,
        arguments: arguments,
      );
    }
  }

  /// Pop current route
  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, result);
    }
  }

  /// Pop until specific route
  static void popUntil(BuildContext context, String routeName) {
    Navigator.popUntil(
      context,
      ModalRoute.withName(routeName),
    );
  }

  /// Check if can pop
  static bool canPop(BuildContext context) {
    return Navigator.canPop(context);
  }
}

/// Fallback screen for undefined routes
class _NotFoundScreen extends StatefulWidget {
  final String routeName;

  const _NotFoundScreen({required this.routeName});

  @override
  State<_NotFoundScreen> createState() => _NotFoundScreenState();
}

class _NotFoundScreenState extends State<_NotFoundScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Page Not Found'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Route not found: ${widget.routeName}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, RoutesConfig.home);
                },
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Route observer for logging navigation events
class AppRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    debugPrint('Route pushed: ${route.settings.name}');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    debugPrint('Route popped: ${route.settings.name}');
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    debugPrint('Route removed: ${route.settings.name}');
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    debugPrint('Route replaced: ${newRoute?.settings.name}');
  }
}
