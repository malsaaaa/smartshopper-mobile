import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/providers/firestore_auth_provider.dart';
import 'package:smartshopper_mobile/widgets/ui_components.dart';

/// Login screen for user authentication
/// Allows users to sign in with email and password
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  /// Handle login action
  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Clear previous error
    setState(() => _errorMessage = null);

    // Validation
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Email is required');
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    if (password.isEmpty) {
      setState(() => _errorMessage = 'Password is required');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    // Start loading
    setState(() => _isLoading = true);

    try {
      await ref.read(signInProvider.notifier).signIn(
        email: email,
        password: password,
      );
      // AuthGuard listens to the Firebase auth stream and will
      // automatically navigate to HomeScreen on success.
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Login failed: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Fixed Background Image that won't shrink
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Image.asset(
              'assets/images/auth/auth-bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
          // Dark Overlay for readability
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.white.withValues(alpha: 0.92), // High opacity white for readability on auth pages
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: size.height * 0.08),

                  // Header Section
                  _buildHeader(),

                  SizedBox(height: AppSpacing.xxl),

                  // Error Message
                  if (_errorMessage != null) ...[
                    _buildErrorMessage(),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Email Field
                  CustomTextField(
                    label: 'Email Address',
                    hint: 'you@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Password Field
                  CustomTextField(
                    label: 'Password',
                    hint: 'Enter your password',
                    controller: _passwordController,
                    prefixIcon: Icons.lock_outlined,
                    isPassword: true,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextIconButton(
                      label: 'Forgot Password?',
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgot-password');
                      },
                      textColor: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Login Button
                  PrimaryButton(
                    label: 'Sign In',
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Divider
                  const DividerWithText(text: 'New to SmartShopper?'),
                  const SizedBox(height: AppSpacing.lg),

                  // Sign Up Button
                  SecondaryButton(
                    label: 'Create Account',
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                  ),
                  SizedBox(height: size.height * 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build header with title and subtitle
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Image.asset(
            'assets/images/logo/app_icon.png',
            height: 60,
            width: 60,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.shopping_bag, size: 60, color: AppTheme.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Welcome Back',
          style: AppTypography.headline1.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Sign in to your account to continue shopping',
          style: AppTypography.bodyMedium.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Build error message container
  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppTheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.error,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
