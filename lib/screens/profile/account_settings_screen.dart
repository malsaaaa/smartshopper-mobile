import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/providers/index.dart';
import 'package:smartshopper_mobile/widgets/ui_components.dart';

/// Account settings screen
/// Allows users to update their profile information and password
class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;
  bool _showPasswordSection = false;

  @override
  void initState() {
    super.initState();
    // Initialize text controllers
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    
    // Load user data from Firebase after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  /// Load user data from Firestore
  void _loadUserData() {
    final userAsync = ref.read(firestoreUserNotifierProvider);
    userAsync.whenData((user) {
      if (mounted) {
        _nameController.text = user?.name ?? 'User';
        _emailController.text = user?.email ?? 'email@example.com';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  /// Handle profile update
  void _handleUpdateProfile() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    // Validation
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Name is required');
      return;
    }

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
      // Update Firestore profile data
      final notifier = ref.read(firestoreUserNotifierProvider.notifier);
      
      if (name.isNotEmpty) {
        await notifier.updateName(name);
      }
      
      if (email.isNotEmpty) {
        await notifier.updateEmail(email);
      }

      // Refresh user data to ensure UI updates
      await notifier.refreshUser();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _successMessage = 'Profile updated successfully';
        });

        // Clear success message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _successMessage = null);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to update profile: $e';
        });
      }
    }
  }

  /// Handle password change
  void _handleChangePassword() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validation
    if (currentPassword.isEmpty) {
      setState(() => _errorMessage = 'Current password is required');
      return;
    }

    if (newPassword.isEmpty) {
      setState(() => _errorMessage = 'New password is required');
      return;
    }

    if (newPassword.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    if (newPassword == currentPassword) {
      setState(() => _errorMessage = 'New password must be different');
      return;
    }

    // Start loading
    setState(() => _isLoading = true);

    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _successMessage = 'Password changed successfully';
          _showPasswordSection = false;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });

        // Clear success message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _successMessage = null);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Message
            if (_successMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppTheme.secondary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.secondary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Error Message
            if (_errorMessage != null) ...[
              Container(
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
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Profile Section
            Text(
              'Profile Information',
              style: AppTypography.headline3,
            ),
            const SizedBox(height: AppSpacing.md),

            // Name Field
            CustomTextField(
              label: 'Full Name',
              hint: 'Enter your full name',
              controller: _nameController,
              prefixIcon: Icons.person_outlined,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Email Field
            CustomTextField(
              label: 'Email Address',
              hint: 'you@example.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Update Profile Button
            PrimaryButton(
              label: 'Save Profile Changes',
              isLoading: _isLoading && !_showPasswordSection,
              onPressed: _handleUpdateProfile,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Password Section
            Text(
              'Security',
              style: AppTypography.headline3,
            ),
            const SizedBox(height: AppSpacing.md),

            // Change Password Button
            SecondaryButton(
              label: _showPasswordSection ? 'Cancel' : 'Change Password',
              onPressed: () {
                setState(() => _showPasswordSection = !_showPasswordSection);
                if (_showPasswordSection) {
                  _currentPasswordController.clear();
                  _newPasswordController.clear();
                  _confirmPasswordController.clear();
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Password Fields (only show when toggled)
            if (_showPasswordSection) ...[
              CustomTextField(
                label: 'Current Password',
                hint: 'Enter your current password',
                controller: _currentPasswordController,
                prefixIcon: Icons.lock_outlined,
                isPassword: true,
              ),
              const SizedBox(height: AppSpacing.lg),

              CustomTextField(
                label: 'New Password',
                hint: 'Enter your new password',
                controller: _newPasswordController,
                prefixIcon: Icons.lock_outlined,
                isPassword: true,
              ),
              const SizedBox(height: AppSpacing.lg),

              CustomTextField(
                label: 'Confirm Password',
                hint: 'Confirm your new password',
                controller: _confirmPasswordController,
                prefixIcon: Icons.lock_outlined,
                isPassword: true,
              ),
              const SizedBox(height: AppSpacing.lg),

              PrimaryButton(
                label: 'Update Password',
                isLoading: _isLoading && _showPasswordSection,
                onPressed: _handleChangePassword,
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),

            // Additional Settings
            Text(
              'Account',
              style: AppTypography.headline3,
            ),
            const SizedBox(height: AppSpacing.md),

            BaseCard(
              child: ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.error,
                ),
                title: Text(
                  'Delete Account',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppTheme.error,
                  ),
                ),
                subtitle: Text(
                  'Permanently delete your account and data',
                  style: AppTypography.bodySmall,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Show delete account confirmation dialog
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
