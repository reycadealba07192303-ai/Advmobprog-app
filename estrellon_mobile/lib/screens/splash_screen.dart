import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/login_type.dart';
import '../providers/user_provider.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    getIsLogin();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> getIsLogin() async {
    final service = UserService();
    final userData = await service.getUserData();
    final hasFirebaseUser = service.currentFirebaseUser != null;

    final loginType =
        LoginTypeX.from(userData['loginType']?.toString());

    if (!mounted) return;

    if ((loginType == LoginType.firebase && hasFirebaseUser) ||
        (userData['token'] != null && userData['token'] != '')) {
      if (loginType == LoginType.firebase) {
        await service.refreshFirebaseTokenIfNeeded();
      }

      if (!mounted) return;

      context.read<UserProvider>().setUser(
            userFromStoredData(userData),
            token: userData['token']?.toString(),
            loginType: loginType,
          );

      Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      });
    } else {
      Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80.h,
              right: -60.w,
              child: Container(
                width: 200.w,
                height: 200.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryStart.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100.h,
              left: -80.w,
              child: Container(
                width: 250.w,
                height: 250.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryEnd.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 140.w,
                        height: 140.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(36.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryStart
                                  .withValues(alpha: 0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(36.r),
                          child: Image.asset(
                            'assets/images/splash_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: const BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                ),
                                child: Icon(
                                  Icons.auto_stories_rounded,
                                  size: 64.sp,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 28.h),
                      CustomText(
                        text: 'Raguini',
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      SizedBox(height: 8.h),
                      CustomText(
                        text: 'Share your stories with the world',
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 64.h),
                      SizedBox(
                        width: 32.w,
                        height: 32.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primaryEnd,
                        ),
                      ),
                    ],
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
