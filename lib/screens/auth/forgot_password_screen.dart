import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/providers/firestore_auth_provider.dart';
import 'package:smartshopper_mobile/widgets/ui_components.dart';

/// Forgot Password screen for email-based password reset
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late TextEditingController _emailController;
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  /// Handle password reset request
  void _handleResetPassword() async {
    final email = _emailController.text.trim();

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

    // Start loading
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(firestoreAuthServiceProvider);
      await authService.sendPasswordResetEmail(email);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: size.height * 0.05),

              if (!_emailSent) ...[
                // Header
                Text(
                  'Forgot Your Password?',
                  style: AppTypography.headline2.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Enter your email address and we\'ll send you a link to reset your password.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

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
                const SizedBox(height: AppSpacing.xl),

                // Reset Button
                PrimaryButton(
                  label: 'Send Reset Link',
                  isLoading: _isLoading,
                  onPressed: _handleResetPassword,
                ),
              ] else ...[
                // Success State
                Center(
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.1),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 48,
                          color: AppTheme.secondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Email Sent!',
                        style: AppTypography.headline2.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Check your email for a link to reset your password.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SecondaryButton(
                        label: 'Back to Login',
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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
