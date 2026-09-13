import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';

class SharedBottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const SharedBottomNavBar({
    super.key,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? const Color.fromARGB(255, 54, 37, 124).withOpacity(0.8)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 25,
              offset: const Offset(0, 10),
              spreadRadius: -5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1A34).withOpacity(0.85)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.7)
                      : Colors.black.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navItem(
                    context: context,
                    selectedIcon: Icons.manage_search,
                    unselectedIcon: Icons.restaurant,
                    label: "restaurants".tr(),
                    index: 1,
                    isDark: isDark,
                  ),
                  _navItem(
                    context: context,
                    selectedIcon: Icons.shopping_cart,
                    unselectedIcon: Icons.shopping_cart_outlined,
                    label: "cart".tr(),
                    index: 2,
                    isDark: isDark,
                  ),
                  _navItem(
                    context: context,
                    selectedIcon: Icons.home,
                    unselectedIcon: Icons.home_outlined,
                    label: "home".tr(),
                    index: 0,
                    isDark: isDark,
                  ),
                  _navItem(
                    context: context,
                    selectedIcon: Icons.receipt,
                    unselectedIcon: Icons.receipt_outlined,
                    label: "my_orders".tr(),
                    index: 3,
                    isDark: isDark,
                  ),
                  _navItem(
                    context: context,
                    selectedIcon: Icons.person,
                    unselectedIcon: Icons.person_outline,
                    label: "my_account".tr(),
                    index: 4,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required BuildContext context,
    required IconData selectedIcon,
    required IconData unselectedIcon,
    required String label,
    required int index,
    required bool isDark,
  }) {
    final isSelected = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isSelected) return;

          if (index == 0) {
            context.go('/home');
          } else if (index == 1) {
            context.go('/restaurants');
          } else if (index == 2) {
            context.push('/cart');
          } else if (index == 3) {
            context.go('/orders');
          } else if (index == 4) {
            context.go('/profile');
          }
        },
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      colors: [
                        Color(0xFF0F55E8),
                        Color.fromARGB(255, 130, 87, 199),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds);
                  },
                  child: Icon(selectedIcon, color: Colors.white, size: 26),
                )
              else
                Icon(
                  unselectedIcon,
                  color: isDark ? Colors.white54 : Colors.black54,
                  size: 26,
                ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: GoogleFonts.cairo(
                    color: isSelected
                        ? const Color(0xFF0F55E8)
                        : (isDark ? Colors.white54 : Colors.black54),
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
