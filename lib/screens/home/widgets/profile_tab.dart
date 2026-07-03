import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smartshopper_mobile/config/app_strings.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/providers/index.dart';
import 'package:smartshopper_mobile/screens/support/contact_us_screen.dart';
import 'package:smartshopper_mobile/screens/support/help_center_screen.dart';
import 'package:smartshopper_mobile/widgets/ui_components.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(isUserLoggedInProvider);
    final s = ref.watch(stringsProvider);
    final langCode = ref.watch(languageProvider);

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
                        label: s.signedIn,
                        status: StatusType.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── Account ──────────────────────────────────────────────────
              _SectionHeader(label: s.sectionAccount),
              const SizedBox(height: AppSpacing.sm),
              _MenuCard(
                children: [
                  ListItemTile(
                    leading: const Icon(Icons.settings_outlined, color: AppTheme.primary),
                    title: s.accountSettings,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textTertiary),
                    onTap: () => Navigator.pushNamed(context, '/account-settings'),
                  ),
                  const Divider(height: 0, indent: 56),
                  ListItemTile(
                    leading: const Icon(Icons.favorite_border, color: Colors.pink),
                    title: s.favorites,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textTertiary),
                    onTap: () => Navigator.pushNamed(context, '/favorites'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Preferences ───────────────────────────────────────────────
              _SectionHeader(label: s.sectionPrefs),
              const SizedBox(height: AppSpacing.sm),
              _MenuCard(
                children: [
                  _ThemeToggleTile(),
                  const Divider(height: 0, indent: 56),
                  ListItemTile(
                    leading: const Icon(Icons.notifications_outlined, color: Color(0xFF8B5CF6)),
                    title: s.notifications,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textTertiary),
                    onTap: () => Navigator.pushNamed(context, '/notifications'),
                  ),
                  const Divider(height: 0, indent: 56),
                  _LanguageTile(
                    s: s,
                    currentCode: langCode,
                    onChanged: (code) =>
                        ref.read(languageProvider.notifier).setLanguage(code),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Support ───────────────────────────────────────────────────
              _SectionHeader(label: s.sectionSupport),
              const SizedBox(height: AppSpacing.sm),
              _MenuCard(
                children: [
                  ListItemTile(
                    leading: const Icon(Icons.help_outline_rounded, color: Color(0xFF10B981)),
                    title: s.helpCenter,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textTertiary),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => HelpCenterScreen(s: s),
                    )),
                  ),
                  const Divider(height: 0, indent: 56),
                  ListItemTile(
                    leading: const Icon(Icons.mail_outline_rounded, color: Color(0xFFF59E0B)),
                    title: s.contactUs,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textTertiary),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ContactUsScreen(s: s),
                    )),
                  ),
                  const Divider(height: 0, indent: 56),
                  ListItemTile(
                    leading: const Icon(Icons.info_outlined, color: Color(0xFF3B82F6)),
                    title: s.about,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textTertiary),
                    onTap: () => Navigator.pushNamed(context, '/about'),
                  ),
                  const Divider(height: 0, indent: 56),
                  ListItemTile(
                    leading: const Icon(Icons.logout, color: AppTheme.error),
                    title: s.signOut,
                    titleColor: AppTheme.error,
                    trailing: const SizedBox.shrink(),
                    onTap: () async {
                      final authService = ref.read(firestoreAuthServiceProvider);
                      await authService.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/firebase-auth');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
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

    // Request only the permission required for the chosen source.
    if (source == ImageSource.camera) {
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus.isPermanentlyDenied || cameraStatus.isDenied) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Camera Permission Required'),
              content: const Text('Please enable camera permission in settings to take a profile photo.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                TextButton(onPressed: () => openAppSettings(), child: const Text('Open Settings')),
              ],
            ),
          );
        }
        return;
      }
    }

    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 256,
      maxHeight: 256,
      imageQuality: 60,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final imageBytes = await image.readAsBytes();
      final userService = ref.read(firestoreUserServiceProvider);
      final userId = ref.read(firestoreAuthServiceProvider).getCurrentUserId();

      if (userId == null) return;

      final contentType = _contentTypeFromFileName(image.name);
      final pictureUrl = kIsWeb
          ? 'data:$contentType;base64,${base64Encode(imageBytes)}'
          : await ref.read(firebaseStorageServiceProvider).uploadProfilePicture(
              userId: userId,
              imageBytes: imageBytes,
              fileName: image.name,
            );

      if (pictureUrl != null) {
        // Update Firestore
        await userService.updateProfilePicture(userId, pictureUrl);
        
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

  String _contentTypeFromFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
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
              : _buildAvatarImage(photoUrl),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _isUploading ? null : _pickImage,
            child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
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

  Widget _buildAvatarImage(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return const Icon(Icons.person, size: 60, color: AppTheme.primary);
    }

    if (photoUrl.startsWith('data:image/')) {
      try {
        final base64Index = photoUrl.indexOf('base64,');
        if (base64Index == -1) {
          return const Icon(Icons.person, size: 60, color: AppTheme.primary);
        }

        final bytes = base64Decode(photoUrl.substring(base64Index + 7));
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.person, size: 60, color: AppTheme.primary),
        );
      } catch (_) {
        return const Icon(Icons.person, size: 60, color: AppTheme.primary);
      }
    }

    return Image.network(
      photoUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.person, size: 60, color: AppTheme.primary),
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

// ── Section header label ───────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.textTertiary,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}

// ── Card container grouping menu items ────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

// ── Language selector tile ─────────────────────────────────────────────────────
class _LanguageTile extends StatelessWidget {
  final AppStrings s;
  final String currentCode;   // 'en' or 'ms'
  final ValueChanged<String> onChanged;  // passes language code

  const _LanguageTile({
    required this.s,
    required this.currentCode,
    required this.onChanged,
  });

  static const _languages = [
    {'code': 'en', 'flag': '🇬🇧'},
    {'code': 'ms', 'flag': '🇲🇾'},
  ];

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(s.selectLanguage, style: AppTypography.headline3),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ..._languages.map((lang) {
                  final code = lang['code']!;
                  final flag = lang['flag']!;
                  final isSelected = currentCode == code;
                  final displayName = code == 'en' ? s.english : s.bahasaMalaysia;
                  return ListTile(
                    leading: Text(flag, style: const TextStyle(fontSize: 26)),
                    title: Text(
                      displayName,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary)
                        : const Icon(Icons.circle_outlined, color: AppTheme.textTertiary),
                    onTap: () {
                      onChanged(code);
                      Navigator.pop(context);
                    },
                  );
                }),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = currentCode == 'en' ? s.english : s.bahasaMalaysia;
    return InkWell(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing12,
        ),
        child: Row(
          children: [
            const Icon(Icons.language_outlined, color: Color(0xFF10B981)),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.language, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 2),
                  Text(
                    displayName,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }
}
