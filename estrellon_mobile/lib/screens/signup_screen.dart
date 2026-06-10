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

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isObscure = true;
  bool _isConfirmObscure = true;
  bool _isLoadingMongo = false;
  bool _isLoadingFirebase = false;
  String _selectedType = 'editor';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildUserPayload() => {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'age': _ageController.text.trim(),
        'gender': _genderController.text.trim(),
        'contactNumber': _contactController.text.trim(),
        'address': _addressController.text.trim(),
        'type': _selectedType,
      };

  String _friendlyError(Object error, LoginType loginType) {
    final message = error.toString();
    if (message.contains('Connection refused') ||
        message.contains('Failed host lookup') ||
        message.contains('Network is unreachable')) {
      return 'Cannot reach the server. Make sure the backend is running and your phone is on the same Wi-Fi as your PC.';
    }
    return authErrorMessage(error, loginType);
  }

  Future<void> _completeSignUp(
    Map<String, dynamic> sessionData,
    LoginType loginType,
  ) async {
    await _userService.saveUserData(sessionData);

    if (!mounted) return;

    final user = userFromLoginResponse(sessionData);
    context.read<UserProvider>().setUser(
          user,
          token: sessionData['token']?.toString(),
          loginType: loginType,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Account created with ${loginType.label}')),
    );

    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _handleMongoSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoadingMongo = true);

    try {
      final sessionData = await _userService.registerWithMongo(
        user: _buildUserPayload(),
      );
      await _completeSignUp(sessionData, LoginType.mongo);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(e, LoginType.mongo))),
      );
    } finally {
      if (mounted) setState(() => _isLoadingMongo = false);
    }
  }

  Future<void> _handleFirebaseSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoadingFirebase = true);

    try {
      final sessionData = await _userService.registerWithFirebase(
        user: _buildUserPayload(),
      );
      await _completeSignUp(sessionData, LoginType.firebase);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(e, LoginType.firebase))),
      );
    } finally {
      if (mounted) setState(() => _isLoadingFirebase = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                child: Row(
                  children: [
                    _IconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomText(
                          text: 'Create Account',
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        SizedBox(height: 8.h),
                        CustomText(
                          text: 'Join Raguini and start sharing your stories',
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 28.h),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _firstNameController,
                                label: 'First Name',
                                prefixIcon: Icons.person_outline,
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: AppTextField(
                                controller: _lastNameController,
                                label: 'Last Name',
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        AppTextField(
                          controller: _usernameController,
                          label: 'Username',
                          prefixIcon: Icons.alternate_email,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                        SizedBox(height: 16.h),
                        AppTextField(
                          controller: _emailController,
                          label: 'Email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(v)) {
                              return 'Invalid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        AppTextField(
                          controller: _passwordController,
                          label: 'Password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _isObscure,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () =>
                                setState(() => _isObscure = !_isObscure),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (v.length < 5) return 'Min 5 characters';
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        AppTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _isConfirmObscure,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmObscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => setState(
                              () => _isConfirmObscure = !_isConfirmObscure,
                            ),
                          ),
                          validator: (v) {
                            if (v != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _ageController,
                                label: 'Age',
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: AppTextField(
                                controller: _genderController,
                                label: 'Gender',
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        AppTextField(
                          controller: _contactController,
                          label: 'Contact Number',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                        SizedBox(height: 16.h),
                        AppTextField(
                          controller: _addressController,
                          label: 'Address',
                          prefixIcon: Icons.location_on_outlined,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                        SizedBox(height: 16.h),
                        _TypeSelector(
                          selected: _selectedType,
                          onChanged: (v) => setState(() => _selectedType = v),
                        ),
                        SizedBox(height: 28.h),
                        GradientButton(
                          label: 'Sign Up with MongoDB',
                          isLoading: _isLoadingMongo,
                          onPressed:
                              _isLoadingFirebase ? null : _handleMongoSignUp,
                        ),
                        SizedBox(height: 12.h),
                        GradientButton(
                          label: 'Sign Up with Firebase',
                          isLoading: _isLoadingFirebase,
                          onPressed:
                              _isLoadingMongo ? null : _handleFirebaseSignUp,
                        ),
                        SizedBox(height: 12.h),
                        CustomText(
                          text:
                              'MongoDB stores profile via /api/users. Firebase stores auth via FirebaseAuth.',
                          fontSize: 11.sp,
                          color: AppColors.textMuted,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomText(
                              text: 'Already have an account? ',
                              fontSize: 14.sp,
                              color: AppColors.textSecondary,
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: CustomText(
                                text: 'Log In',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryEnd,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 32.h),
                      ],
                    ),
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

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: AppDecorations.secondaryButton(context, radius: 14),
        child: Icon(icon, color: AppColors.textPrimary, size: 18.sp),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const types = ['editor', 'viewer', 'admin'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Type',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: types.map((type) {
            final isSelected = selected == type;
            return GestureDetector(
              onTap: () => onChanged(type),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : AppColors.surface,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Text(
                  type[0].toUpperCase() + type.substring(1),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
