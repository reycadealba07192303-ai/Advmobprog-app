import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../services/user_service.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await UserService().logoutSession();
    if (!context.mounted) return;
    context.read<UserProvider>().logout();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final themeModel = context.watch<ThemeProvider>();
    final userModel = context.watch<UserProvider>();
    final user = userModel.currentUser;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user != null) ...[
            _SectionTitle(title: 'Account', palette: palette),
            SizedBox(height: 12.h),
            GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 56.w,
                    height: 56.w,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    child: Center(
                      child: CustomText(
                        text: user.firstName.isNotEmpty
                            ? user.firstName[0].toUpperCase()
                            : '?',
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: user.fullName,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary,
                        ),
                        SizedBox(height: 4.h),
                        CustomText(
                          text: '@${user.username} • ${user.type}',
                          fontSize: 12.sp,
                          color: palette.textSecondary,
                        ),
                        SizedBox(height: 2.h),
                        CustomText(
                          text: user.email,
                          fontSize: 12.sp,
                          color: palette.textMuted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            SecondaryButton(
              label: 'Logout',
              icon: Icons.logout_rounded,
              onPressed: () => _handleLogout(context),
            ),
            SizedBox(height: 20.h),
          ],
          _SectionTitle(title: 'Appearance', palette: palette),
          SizedBox(height: 12.h),
          GlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: AppDecorations.secondaryButton(
                        context,
                        radius: 14,
                      ),
                      child: Icon(
                        themeModel.isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: AppColors.primaryEnd,
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: 'Dark Mode',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary,
                        ),
                        SizedBox(height: 4.h),
                        CustomText(
                          text: themeModel.isDark ? 'Enabled' : 'Disabled',
                          fontSize: 12.sp,
                          color: palette.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: themeModel.isDark,
                  onChanged: (_) => themeModel.toggleTheme(),
                  activeThumbColor: AppColors.primaryEnd,
                  activeTrackColor: AppColors.primaryStart.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          _SectionTitle(title: 'About', palette: palette),
          SizedBox(height: 12.h),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AboutRow(
                  label: 'App Version',
                  value: '1.0.0',
                  palette: palette,
                ),
                SizedBox(height: 12.h),
                Divider(color: palette.divider),
                SizedBox(height: 12.h),
                _AboutRow(
                  label: 'App Name',
                  value: 'Estrellon',
                  palette: palette,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.palette});

  final String title;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 16.h,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        SizedBox(width: 8.w),
        CustomText(
          text: title,
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
        ),
      ],
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.label,
    required this.value,
    required this.palette,
  });

  final String label;
  final String value;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          text: label,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: palette.textSecondary,
        ),
        CustomText(
          text: value,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
      ],
    );
  }
}
