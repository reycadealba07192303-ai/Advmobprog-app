import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/login_type.dart';
import '../providers/user_provider.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/custom_text.dart';
import '../widgets/gradient_button.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userService = UserService();

  bool _isObscure = true;
  bool _isLoadingMongo = false;
  bool _isLoadingFirebase = false;

  Future<void> _completeLogin(
    Map<String, dynamic> response,
    LoginType loginType,
  ) async {
    await _userService.saveUserData(response);

    if (!mounted) return;

    final user = userFromLoginResponse(response);
    context.read<UserProvider>().setUser(
          user,
          token: response['token']?.toString(),
          loginType: loginType,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logged in with ${loginType.label}')),
    );

    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _handleMongoLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoadingMongo = true);

    try {
      final response = await _userService.loginWithMongo(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await _completeLogin(response, LoginType.mongo);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(e, LoginType.mongo))),
      );
    } finally {
      if (mounted) setState(() => _isLoadingMongo = false);
    }
  }

  Future<void> _handleFirebaseLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoadingFirebase = true);

    try {
      final response = await _userService.loginWithFirebase(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await _completeLogin(response, LoginType.firebase);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(e, LoginType.firebase))),
      );
    } finally {
      if (mounted) setState(() => _isLoadingFirebase = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32.r),
                    bottomRight: Radius.circular(32.r),
                  ),
                  child: Stack(
                    children: [
                      Image.asset(
                        'assets/images/login_hero.png',
                        height: 220.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 220.h,
                            decoration: const BoxDecoration(
                              gradient: AppColors.heroGradient,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.auto_stories_rounded,
                                size: 64.sp,
                                color: AppColors.primaryEnd,
                              ),
                            ),
                          );
                        },
                      ),
                      Container(
                        height: 220.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.background.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 8.h),
                        CustomText(
                          text: 'Welcome Back',
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        SizedBox(height: 8.h),
                        CustomText(
                          text: 'Sign in to continue to Raguini',
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 32.h),
                        AppTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Enter your email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20.h),
                        AppTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Enter your password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _isObscure,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () {
                              setState(() => _isObscure = !_isObscure);
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 32.h),
                        GradientButton(
                          label: 'Log In with MongoDB',
                          isLoading: _isLoadingMongo,
                          onPressed: _isLoadingFirebase ? null : _handleMongoLogin,
                        ),
                        SizedBox(height: 12.h),
                        GradientButton(
                          label: 'Log In with Firebase',
                          isLoading: _isLoadingFirebase,
                          onPressed: _isLoadingMongo ? null : _handleFirebaseLogin,
                        ),
                        SizedBox(height: 12.h),
                        CustomText(
                          text:
                              'MongoDB uses API + JWT. Firebase uses FirebaseAuth SDK + token refresh.',
                          fontSize: 11.sp,
                          color: AppColors.textMuted,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomText(
                              text: "Don't have an account? ",
                              fontSize: 14.sp,
                              color: AppColors.textSecondary,
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignUpScreen(),
                                  ),
                                );
                              },
                              child: CustomText(
                                text: 'Sign Up',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryEnd,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: AppDecorations.glassCard(context, radius: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.textMuted,
                                size: 18.sp,
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: CustomText(
                                  text: 'Demo: fname@example.com / 12345',
                                  fontSize: 12.sp,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 32.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
