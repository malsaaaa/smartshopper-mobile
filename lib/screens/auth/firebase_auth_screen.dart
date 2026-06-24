import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/providers/firestore_auth_provider.dart';
import 'package:smartshopper_mobile/widgets/ui_components.dart';

/// Firebase Authentication Screen
/// Handles user signup and login with Firestore
class FirebaseAuthScreen extends ConsumerStatefulWidget {
  const FirebaseAuthScreen({super.key});

  @override
  ConsumerState<FirebaseAuthScreen> createState() => _FirebaseAuthScreenState();
}

class _FirebaseAuthScreenState extends ConsumerState<FirebaseAuthScreen> {
  bool isSignUp = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    setState(() => _errorMessage = null);

    try {
      if (isSignUp) {
        await ref.read(signUpProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
        );
      } else {
        await ref.read(signInProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      final errorMessage = e is Exception 
        ? e.toString().replaceAll('Exception: ', '')
        : e.toString();
      setState(() => _errorMessage = errorMessage);
      
      // Also print to console for debugging
      debugPrint('Auth error: $e');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _errorMessage = null);

    try {
      await ref.read(googleSignInProvider.notifier).signInWithGoogle();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      final errorMessage = e is Exception 
        ? e.toString().replaceAll('Exception: ', '')
        : e.toString();
      setState(() => _errorMessage = errorMessage);
      
      debugPrint('Google sign-in error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final signUpState = ref.watch(signUpProvider);
    final signInState = ref.watch(signInProvider);
    final isLoading =
        signUpState is AsyncLoading || signInState is AsyncLoading;

    return Scaffold(
      extendBodyBehindAppBar: true,
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
          // White Overlay for readability
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.white.withValues(alpha: 0.92),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100), // Space for AppBar
                
                // App Logo
                Center(
                  child: Container(
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
                ),
                const SizedBox(height: AppSpacing.xl),
                
                Center(
                  child: Text(
                    isSignUp
                        ? 'Create Account'
                        : 'Welcome Back',
                    style: AppTypography.headline1,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppTheme.error),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                  ),

                // Name field (only for signup)
                if (isSignUp) ...[
                  Text('Full Name', style: AppTypography.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter your full name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Email field
                Text('Email Address', style: AppTypography.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'you@example.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Password field
                Text('Password', style: AppTypography.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  obscureText: true,
                  enabled: !isLoading,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Forgot Password Link (only for Sign In mode)
                if (!isSignUp) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.pushNamed(context, '/forgot-password'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Forgot Password?',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ] else ...[
                  const SizedBox(height: AppSpacing.xl),
                ],

                // Submit button
                PrimaryButton(
                  label: isSignUp ? 'Create Account' : 'Sign In',
                  isLoading: isLoading,
                  onPressed: _handleAuth,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text('OR', style: AppTypography.labelSmall),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Google Sign-In Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isLoading ? null : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      side: BorderSide(color: Colors.grey[300]!),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/auth/google.png',
                          height: 24,
                          width: 24,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.g_mobiledata, color: Colors.blue, size: 28),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Continue with Google',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Toggle signup/signin
                Center(
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () => setState(() => isSignUp = !isSignUp),
                    child: Text(
                      isSignUp
                          ? 'Already have an account? Sign In'
                          : "Don't have an account? Create Account",
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
