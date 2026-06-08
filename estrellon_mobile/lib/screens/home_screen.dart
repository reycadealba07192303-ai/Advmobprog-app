import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import '../widgets/custom_text.dart';
import 'article_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, this.username = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  static const _titles = ['Articles', 'Chats', 'Profile', 'Settings'];

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: _titles[_selectedIndex],
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (page) => setState(() => _selectedIndex = page),
        children: const [
          ArticleScreen(),
          ChatScreen(),
          ProfileScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: palette.cardBorder),
          boxShadow: [
            BoxShadow(
              color: palette.shadow,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NavIcon(
              icon: Icons.home_rounded,
              isSelected: _selectedIndex == 0,
              onTap: () => _onTappedBar(0),
              palette: palette,
            ),
            SizedBox(width: 24.w),
            _NavIcon(
              icon: Icons.chat_bubble_rounded,
              isSelected: _selectedIndex == 1,
              onTap: () => _onTappedBar(1),
              palette: palette,
            ),
            SizedBox(width: 24.w),
            _NavIcon(
              icon: Icons.person_rounded,
              isSelected: _selectedIndex == 2,
              onTap: () => _onTappedBar(2),
              palette: palette,
            ),
            SizedBox(width: 24.w),
            _NavIcon(
              icon: Icons.settings_rounded,
              isSelected: _selectedIndex == 3,
              onTap: () => _onTappedBar(3),
              palette: palette,
            ),
          ],
        ),
      ),
    );
  }

  void _onTappedBar(int value) {
    setState(() => _selectedIndex = value);
    _pageController.jumpToPage(value);
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.palette,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 48.w,
        height: 48.w,
        alignment: Alignment.center,
        decoration: isSelected
            ? BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryStart.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
            : null,
        child: Icon(
          icon,
          color: isSelected ? Colors.white : palette.textMuted,
          size: 24.sp,
        ),
      ),
    );
  }
}
