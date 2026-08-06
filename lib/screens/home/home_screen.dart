import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/providers/index.dart';
import 'package:smartshopper_mobile/services/location_service.dart';
import 'package:smartshopper_mobile/screens/home/widgets/budget_tab.dart';
import 'package:smartshopper_mobile/screens/home/widgets/home_tab.dart';
import 'package:smartshopper_mobile/screens/home/widgets/notification_button.dart';
import 'package:smartshopper_mobile/screens/home/widgets/profile_tab.dart';
import 'package:smartshopper_mobile/screens/home/widgets/search_tab.dart';
import 'package:smartshopper_mobile/screens/home/widgets/shopping_tab.dart';

/// Main home screen with tabbed navigation.
/// Each tab is a self-contained widget in screens/home/widgets/.
class HomeScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const HomeScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  @override
  void initState() {
    super.initState();
    LocationService.clearCache(); // Force-clear coordinates cache to resolve any stale or incorrect POI mappings!
    // Pre-cache the welcome header background so it doesn't flash the green gradient
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/images/backgrounds/main-bg.png'), context);
      ref.read(homeTabIndexProvider.notifier).state = widget.initialTab;
    });
  }

  static const _tabs = [
    HomeTab(),
    SearchTab(),
    ShoppingTab(),
    BudgetTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(homeTabIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Image.asset(
                'assets/images/logo/app_icon.png',
                height: 24,
                width: 24,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.shopping_cart, size: 24),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('SmartShopper'),
          ],
        ),
        elevation: 1,
        automaticallyImplyLeading: false,
        actions: const [
          NotificationButton(),
          SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: _tabs[selectedTab],
      bottomNavigationBar: _CustomNavBar(
        selectedIndex: selectedTab,
        onTap: (i) => ref.read(homeTabIndexProvider.notifier).state = i,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom bottom nav bar with a raised circular Shopping FAB in the centre
// ─────────────────────────────────────────────────────────────────────────────

class _CustomNavBar extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _CustomNavBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final selectedColor = AppTheme.primary;
    const unselectedColor = AppTheme.textTertiary;
    final bgColor = Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: SizedBox(
        height: 64,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Four regular nav items arranged around the centre gap ──────
            Row(
              children: [
                // Home
                Expanded(
                  child: _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: s.navHome,
                    isSelected: selectedIndex == 0,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    onTap: () => onTap(0),
                  ),
                ),
                // Search
                Expanded(
                  child: _NavItem(
                    icon: Icons.search_outlined,
                    activeIcon: Icons.search,
                    label: s.navSearch,
                    isSelected: selectedIndex == 1,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    onTap: () => onTap(1),
                  ),
                ),
                // Centre gap for the circular button
                const SizedBox(width: 72),
                // Budget
                Expanded(
                  child: _NavItem(
                    icon: Icons.wallet_outlined,
                    activeIcon: Icons.wallet,
                    label: s.navBudget,
                    isSelected: selectedIndex == 3,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    onTap: () => onTap(3),
                  ),
                ),
                // Profile
                Expanded(
                  child: _NavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: s.navProfile,
                    isSelected: selectedIndex == 4,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    onTap: () => onTap(4),
                  ),
                ),
              ],
            ),

            // ── Raised circular Shopping button ────────────────────────────
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () => onTap(2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selectedIndex == 2
                        ? AppTheme.primaryDark
                        : AppTheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.40),
                        blurRadius: 10,
                        spreadRadius: selectedIndex == 2 ? 2 : 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    selectedIndex == 2
                        ? Icons.shopping_cart
                        : Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single nav bar item (non-FAB).
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? selectedColor : unselectedColor,
            size: 24,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? selectedColor : unselectedColor,
            ),
          ),
        ],
      ),
    );
  }
}
