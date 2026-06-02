import 'package:flutter/material.dart';
import 'package:smartshopper_mobile/config/routes.dart';

/// Extension methods for easier navigation using RoutesConfig
extension NavigationExtension on BuildContext {
  /// Navigate to login screen
  void toLogin({bool replacement = false}) {
    RoutesConfig.navigate(this, RoutesConfig.login, replacement: replacement);
  }

  /// Navigate to register screen
  void toRegister({bool replacement = false}) {
    RoutesConfig.navigate(this, RoutesConfig.register, replacement: replacement);
  }

  /// Navigate to forgot password screen
  void toForgotPassword({bool replacement = false}) {
    RoutesConfig.navigate(
      this,
      RoutesConfig.forgotPassword,
      replacement: replacement,
    );
  }

  /// Navigate to home screen
  void toHome({bool replacement = true}) {
    RoutesConfig.navigate(this, RoutesConfig.home, replacement: replacement);
  }

  /// Navigate to product search screen
  void toProductSearch({bool replacement = false}) {
    RoutesConfig.navigate(
      this,
      RoutesConfig.productSearch,
      replacement: replacement,
    );
  }

  /// Navigate to product details screen
  void toProductDetails(int productId, {bool replacement = false}) {
    RoutesConfig.navigate(
      this,
      RoutesConfig.productDetails,
      arguments: productId,
      replacement: replacement,
    );
  }

  /// Pop current route
  void pop<T extends Object?>([T? result]) {
    RoutesConfig.pop(this, result);
  }

  /// Check if can pop
  bool canPop() {
    return RoutesConfig.canPop(this);
  }
}
