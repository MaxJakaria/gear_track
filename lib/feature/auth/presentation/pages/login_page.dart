import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:gear_track/core/widgets/app_gradient_button.dart';
import 'package:gear_track/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:gear_track/feature/auth/presentation/pages/forgot_password_page.dart';
import 'package:gear_track/feature/auth/presentation/widgets/auth_header_image.dart';
import 'package:gear_track/feature/auth/presentation/widgets/auth_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _hasSavedEmail = false;
  bool _isLoadingSavedEmail = true;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_user_email') ??
        FirebaseAuth.instance.currentUser?.email;

    if (mounted) {
      setState(() {
        if (savedEmail != null && savedEmail.trim().isNotEmpty) {
          _emailController.text = savedEmail.trim();
          _hasSavedEmail = true;
        } else {
          _hasSavedEmail = false;
        }
        _isLoadingSavedEmail = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      if (email.isEmpty) return;

      FocusScope.of(context).unfocus();
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: email,
              password: _passwordController.text,
            ),
          );
    }
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      ForgotPasswordPage.route(initialEmail: _emailController.text.trim()),
    );
  }

  Future<void> _switchAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_user_email');
    if (mounted) {
      setState(() {
        _hasSavedEmail = false;
        _emailController.clear();
        _passwordController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailureState) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.message,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFDC2626),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          if (_isLoadingSavedEmail) {
            return const SafeArea(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Top Illustration
                      const AuthHeaderImage(
                        imagePath: 'assets/images/sign_in.png',
                        bottomSpacing: 40,
                      ),

                      // 2. Email Address Field (Only shown on first-time login)
                      if (!_hasSavedEmail) ...[
                        AuthTextField(
                          controller: _emailController,
                          labelText: 'Email Address',
                          hintText: 'Enter your email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            final val = value?.trim() ?? '';
                            if (val.isEmpty) {
                              return 'Please enter your email.';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(val)) {
                              return 'Enter a valid email address.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // 3. Password Field (Always shown, auto-focused if email is saved)
                      AuthTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _onLogin(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          final val = value ?? '';
                          if (val.isEmpty) {
                            return 'Please enter your password.';
                          }
                          if (val.length < 6) {
                            return 'Password must be at least 6 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 6),

                      // 4. Forgot Password Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed:
                              isLoading ? null : _navigateToForgotPassword,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryButton(context),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 5. Sign In Button
                      AppGradientButton(
                        label: 'Sign In',
                        icon: Icons.login_rounded,
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _onLogin,
                        height: 48,
                        borderRadius: 10,
                      ),

                      // 6. Optional Switch Account Link (Only when email is saved)
                      if (_hasSavedEmail) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: isLoading ? null : _switchAccount,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(
                              'Use different email / Switch account',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
