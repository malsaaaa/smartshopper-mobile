import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/providers/index.dart';
import 'package:smartshopper_mobile/widgets/ui_components.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isUserLoggedInProvider);

    if (!isLoggedIn) {
      return _LoginPrompt();
    }

    final userAsync = ref.watch(firestoreUserNotifierProvider);

    return userAsync.when(
      data: (user) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // ----- Profile Header -----
              Center(
                child: Column(
                  children: [
                    _ProfileAvatar(user: user),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      user?.name ?? 'User',
                      style: AppTypography.headline2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      user?.email ?? 'email@example.com',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: StatusBadge(
                        label: 'Signed In',
                        status: StatusType.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ----- Theme Toggle -----
              _ThemeToggleTile(),
              const Divider(height: 0),

              // ----- Menu Items -----
              ListItemTile(
                leading: const Icon(Icons.settings_outlined),
                title: 'Account Settings',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () =>
                    Navigator.pushNamed(context, '/account-settings'),
              ),
              const Divider(height: 0),
              ListItemTile(
                leading: const Icon(Icons.notifications_outlined),
                title: 'Notifications',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () =>
                    Navigator.pushNamed(context, '/notifications'),
              ),
              const Divider(height: 0),
              ListItemTile(
                leading: const Icon(Icons.info_outlined),
                title: 'About SmartShopper',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.pushNamed(context, '/about'),
              ),
              const Divider(height: 0),
              ListItemTile(
                leading:
                    const Icon(Icons.logout, color: AppTheme.error),
                title: 'Sign Out',
                trailing: const SizedBox.shrink(),
                onTap: () async {
                  final authService =
                      ref.read(firestoreAuthServiceProvider);
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(
                        context, '/firebase-auth');
                  }
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: AppSpacing.md),
            Text('Error loading profile', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () =>
                  ref.invalidate(firestoreUserNotifierProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Profile Avatar with Image Picking ----------

class _ProfileAvatar extends ConsumerStatefulWidget {
  final dynamic user;
  const _ProfileAvatar({this.user});

  @override
  ConsumerState<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends ConsumerState<_ProfileAvatar> {
  bool _isUploading = false;

  Future<void> _pickImage() async {
    // Request permissions first
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.photos,
      Permission.storage,
    ].request();

    if (statuses[Permission.camera]!.isPermanentlyDenied || 
        statuses[Permission.photos]!.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissions Required'),
            content: const Text('Please enable camera and photo permissions in settings to change your profile picture.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(onPressed: () => openAppSettings(), child: const Text('Open Settings')),
            ],
          ),
        );
      }
      return;
    }

    final ImagePicker picker = ImagePicker();
    
    // Show dialog to choose between camera and gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final storageService = ref.read(firebaseStorageServiceProvider);
      final userService = ref.read(firestoreUserServiceProvider);
      final userId = ref.read(firestoreAuthServiceProvider).getCurrentUserId();

      if (userId == null) return;

      // Upload to Storage
      final downloadUrl = await storageService.uploadProfilePicture(
        userId: userId,
        imageFile: File(image.path),
      );

      if (downloadUrl != null) {
        // Update Firestore
        await userService.updateProfilePicture(userId, downloadUrl);
        
        // Refresh profile info
        ref.invalidate(firestoreUserNotifierProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile picture: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = widget.user?.profilePicture;

    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryLight,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: _isUploading
              ? const Center(child: CircularProgressIndicator())
              : photoUrl != null && photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, size: 60, color: AppTheme.primary),
                    )
                  : const Icon(Icons.person, size: 60, color: AppTheme.primary),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _isUploading ? null : _pickImage,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------- Theme Toggle Row ----------

class _ThemeToggleTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return ListTile(
      leading: Icon(
        isDark ? Icons.dark_mode : Icons.light_mode,
        color: AppTheme.primary,
      ),
      title: Text(
        isDark ? 'Dark Mode' : 'Light Mode',
        style: AppTypography.bodyMedium,
      ),
      subtitle: Text(
        themeMode == ThemeMode.system ? 'Following system' : 'Manual',
        style: AppTypography.bodySmall,
      ),
      trailing: Switch(
        value: isDark,
        activeColor: AppTheme.primary,
        onChanged: (_) {
          ref.read(themeModeProvider.notifier).toggle(context);
        },
      ),
    );
  }
}

// ---------- Login Prompt ----------

class _LoginPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/logo/app_icon.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.shopping_bag, size: 40, color: AppTheme.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Login Required',
              style: AppTypography.headline2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Sign in to view your profile and manage your account',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              label: 'Sign In',
              onPressed: () =>
                  Navigator.pushNamed(context, '/firebase-auth'),
            ),
          ],
        ),
      ),
    );
  }
}
