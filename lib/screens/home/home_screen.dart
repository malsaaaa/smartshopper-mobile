import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/screens/home/widgets/budget_tab.dart';
import 'package:smartshopper_mobile/screens/home/widgets/home_tab.dart';
import 'package:smartshopper_mobile/screens/home/widgets/notification_button.dart';
import 'package:smartshopper_mobile/screens/home/widgets/profile_tab.dart';
import 'package:smartshopper_mobile/screens/home/widgets/search_tab.dart';
import 'package:smartshopper_mobile/screens/home/widgets/shopping_tab.dart';

/// Main home screen with tabbed navigation.
/// Each tab is a self-contained widget in screens/home/widgets/.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedTab = 0;

  static const _tabs = [
    HomeTab(),
    SearchTab(),
    ShoppingTab(),
    BudgetTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
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
      body: _tabs[_selectedTab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Shopping',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wallet_outlined),
            activeIcon: Icon(Icons.wallet),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
