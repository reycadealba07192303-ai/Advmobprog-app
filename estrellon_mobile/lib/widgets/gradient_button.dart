import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import 'custom_text.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 56.h,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: onPressed == null
            ? LinearGradient(
                colors: [
                  AppColors.primaryStart.withValues(alpha: 0.4),
                  AppColors.primaryEnd.withValues(alpha: 0.4),
                ],
              )
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: AppColors.primaryStart.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(24.r),
          child: Center(
            child: isLoading
                ? SizedBox(
                    height: 24.h,
                    width: 24.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : CustomText(
                    text: label,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      height: 56.h,
      width: double.infinity,
      decoration: AppDecorations.secondaryButton(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20.r),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: palette.textPrimary, size: 20.sp),
                SizedBox(width: 8.w),
              ],
              CustomText(
                text: label,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
