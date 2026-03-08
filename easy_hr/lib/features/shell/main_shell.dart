import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/localization/app_strings.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/') return 0;
    if (location == '/attendance') return 1;
    if (location == '/payroll') return 2;
    if (location == '/leave') return 3;
    if (location == '/profile') return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _getSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);
    final s = AppStrings.get(lang);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) {
            switch (index) {
              case 0: context.go('/'); break;
              case 1: context.go('/attendance'); break;
              case 2: context.go('/payroll'); break;
              case 3: context.go('/leave'); break;
              case 4: context.go('/profile'); break;
            }
          },
          items: [
            BottomNavigationBarItem(icon: const Icon(Iconsax.home_2), activeIcon: const Icon(Iconsax.home_25), label: s['nav_home']),
            BottomNavigationBarItem(icon: const Icon(Iconsax.clock), activeIcon: const Icon(Iconsax.clock5), label: s['nav_attendance']),
            BottomNavigationBarItem(icon: const Icon(Iconsax.money_send), activeIcon: const Icon(Iconsax.money_send), label: s['nav_payroll']),
            BottomNavigationBarItem(icon: const Icon(Iconsax.calendar_1), activeIcon: const Icon(Iconsax.calendar5), label: s['nav_leave']),
            BottomNavigationBarItem(icon: const Icon(Iconsax.user), activeIcon: const Icon(Iconsax.user5), label: s['nav_profile']),
          ],
        ),
      ),
    );
  }
}