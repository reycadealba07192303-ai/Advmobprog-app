import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/login_type.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  final _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    await _userService.refreshFirebaseTokenIfNeeded();
    final data = await _userService.getUserData();
    if (!mounted) return;
    setState(() {
      _userData = data;
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    await _userService.logoutSession();
    if (!mounted) return;
    context.read<UserProvider>().logout();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<void> _showUpdateUsernameDialog(
    User user,
    LoginType loginType,
  ) async {
    final controller = TextEditingController(text: user.username);
    final palette = AppPalette.of(context);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        title: Text('Update Username', style: TextStyle(color: palette.textPrimary)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Username'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    try {
      await _userService.updateUsernameForSession(
        username: controller.text.trim(),
        loginType: loginType,
        uid: user.uid,
      );
      await _loadUserData();
      if (!mounted) return;
      context.read<UserProvider>().setUser(
            userFromStoredData(_userData),
            token: _userData['token']?.toString(),
            loginType: loginType,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(e, loginType))),
      );
    }
  }

  Future<void> _showChangePasswordDialog(
    User user,
    LoginType loginType,
  ) async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final palette = AppPalette.of(context);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        title: Text('Change Password', style: TextStyle(color: palette.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Current password'),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'New password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    try {
      await _userService.changePasswordForSession(
        loginType: loginType,
        email: user.email,
        currentPassword: currentController.text.trim(),
        newPassword: newController.text.trim(),
        uid: user.uid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(e, loginType))),
      );
    }
  }

  Future<void> _showDeleteAccountDialog(
    User user,
    LoginType loginType,
  ) async {
    final passwordController = TextEditingController();
    final palette = AppPalette.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        title: Text('Delete Account', style: TextStyle(color: palette.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This action is permanent. Enter your password to confirm.',
              style: TextStyle(color: palette.textSecondary, fontSize: 13.sp),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _userService.deleteAccountForSession(
        loginType: loginType,
        email: user.email,
        password: passwordController.text.trim(),
        uid: user.uid,
      );
      if (!mounted) return;
      context.read<UserProvider>().logout();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(e, loginType))),
      );
    }
  }

  String _initials(User? user) {
    if (user == null) return '?';
    final first = user.firstName.isNotEmpty ? user.firstName[0] : '';
    final last = user.lastName.isNotEmpty ? user.lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final providerUser = context.watch<UserProvider>().currentUser;
    final user = providerUser ?? userFromStoredData(_userData);
    final loginType =
        LoginTypeX.from(_userData['loginType']?.toString());
    final isMongo = loginType == LoginType.mongo;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryEnd),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserData,
      color: AppColors.primaryEnd,
      backgroundColor: palette.surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileHeroCard(
              user: user,
              initials: _initials(user),
              palette: palette,
              loginType: loginType,
            ),
            SizedBox(height: 20.h),
            _SectionTitle(title: 'Personal Info', palette: palette),
            SizedBox(height: 10.h),
            GlassCard(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Column(
                children: [
                  ProfileInfoRow(
                    icon: Icons.login_rounded,
                    label: 'Login Type',
                    value: loginType.label,
                  ),
                  _divider(palette),
                  ProfileInfoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Full Name',
                    value: user.fullName,
                  ),
                  _divider(palette),
                  ProfileInfoRow(
                    icon: Icons.alternate_email_rounded,
                    label: 'Username',
                    value: '@${user.username}',
                  ),
                  _divider(palette),
                  ProfileInfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user.email,
                  ),
                  if (isMongo) ...[
                    _divider(palette),
                    ProfileInfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Account Type',
                      value: user.type,
                    ),
                  ],
                ],
              ),
            ),
            if (isMongo) ...[
              SizedBox(height: 16.h),
              _SectionTitle(title: 'Contact Details', palette: palette),
              SizedBox(height: 10.h),
              GlassCard(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Column(
                  children: [
                    ProfileInfoRow(
                      icon: Icons.cake_outlined,
                      label: 'Age',
                      value: user.age,
                    ),
                    _divider(palette),
                    ProfileInfoRow(
                      icon: Icons.wc_outlined,
                      label: 'Gender',
                      value: user.gender,
                    ),
                    _divider(palette),
                    ProfileInfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Contact Number',
                      value: user.contactNumber,
                    ),
                    _divider(palette),
                    ProfileInfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: user.address,
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(height: 16.h),
              GlassCard(
                child: CustomText(
                  text:
                      'Firebase account — auth managed by FirebaseAuth with token refresh.',
                  fontSize: 12.sp,
                  color: palette.textSecondary,
                ),
              ),
            ],
            SizedBox(height: 20.h),
            _SectionTitle(title: 'Account Actions', palette: palette),
            SizedBox(height: 10.h),
            GlassCard(
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.edit_outlined,
                    label: 'Update Username',
                    palette: palette,
                    onTap: () => _showUpdateUsernameDialog(user, loginType),
                  ),
                  _divider(palette),
                  _ActionTile(
                    icon: Icons.lock_reset_outlined,
                    label: 'Change Password',
                    palette: palette,
                    onTap: () => _showChangePasswordDialog(user, loginType),
                  ),
                  _divider(palette),
                  _ActionTile(
                    icon: Icons.delete_outline,
                    label: 'Delete Account',
                    palette: palette,
                    color: AppColors.danger,
                    onTap: () => _showDeleteAccountDialog(user, loginType),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SecondaryButton(
              label: 'Logout',
              icon: Icons.logout_rounded,
              onPressed: _handleLogout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(AppPalette palette) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Divider(color: palette.divider, height: 1),
      );
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
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
      ],
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.user,
    required this.initials,
    required this.palette,
    required this.loginType,
  });

  final User user;
  final String initials;
  final AppPalette palette;
  final LoginType loginType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryStart.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        margin: EdgeInsets.all(1.5),
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(22.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryStart.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Container(
                margin: EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.surface,
                ),
                child: Center(
                  child: CustomText(
                    text: initials,
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: user.fullName.isEmpty ? 'Guest User' : user.fullName,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3.h),
                  CustomText(
                    text: user.email,
                    fontSize: 12.sp,
                    color: palette.textSecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: [
                      _Chip(
                        label: loginType.label,
                        icon: Icons.cloud_outlined,
                        highlighted: loginType == LoginType.firebase,
                        palette: palette,
                      ),
                      _Chip(
                        label: '@${user.username}',
                        icon: Icons.alternate_email_rounded,
                        palette: palette,
                      ),
                      _Chip(
                        label: user.type,
                        icon: Icons.shield_outlined,
                        highlighted: true,
                        palette: palette,
                      ),
                      _Chip(
                        label: user.isActive ? 'Active' : 'Inactive',
                        palette: palette,
                        icon: Icons.circle,
                        dotColor: user.isActive
                            ? const Color(0xFF4ADE80)
                            : AppColors.danger,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.palette,
    this.highlighted = false,
    this.dotColor,
  });

  final String label;
  final IconData icon;
  final AppPalette palette;
  final bool highlighted;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        gradient: highlighted ? AppColors.primaryGradient : null,
        color: highlighted ? null : palette.surfaceLight,
        borderRadius: BorderRadius.circular(20.r),
        border: highlighted
            ? null
            : Border.all(color: palette.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null)
            Container(
              width: 6.w,
              height: 6.w,
              margin: EdgeInsets.only(right: 4.w),
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            )
          else
            Icon(
              icon,
              size: 11.sp,
              color: highlighted ? Colors.white : palette.textMuted,
            ),
          if (dotColor == null) SizedBox(width: 4.w),
          CustomText(
            text: label,
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: highlighted ? Colors.white : palette.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final AppPalette palette;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Icon(icon, color: color ?? palette.textPrimary, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: CustomText(
                text: label,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: color ?? palette.textPrimary,
              ),
            ),
            Icon(Icons.chevron_right, color: palette.textMuted, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
