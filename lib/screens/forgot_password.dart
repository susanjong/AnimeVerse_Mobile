import 'package:anime_verse/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../providers/auth_provider.dart';
import '../utils/snackbar_helper.dart';
import '../utils/validators.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetEmail() async {
    final email = _emailController.text.trim();

    // Validasi email
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      SnackbarHelper.showError(context, emailError);
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendPasswordResetEmail(email);

    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (success) {
      if (mounted) {
        setState(() => _emailSent = true);
        SnackbarHelper.showSuccess(
          context,
          'Password reset email sent! Check your inbox.',
        );
      }
    } else {
      if (mounted) {
        final errorMessage = authProvider.errorMessage ??
            'Failed to send reset email';
        SnackbarHelper.showError(context, errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AppScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 600;
          final maxWidth = isLargeScreen ? 400.0 : constraints.maxWidth;

          return SingleChildScrollView(
            child: Center(
              child: Container(
                width: maxWidth,
                padding: EdgeInsets.all(screenWidth * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.1),

                    // Back Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: screenWidth * 0.07,
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // Icon
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.05),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _emailSent ? Icons.mark_email_read : Icons.lock_reset,
                        size: screenWidth * 0.15,
                        color: Colors.blue.shade300,
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.04),

                    // Title
                    Text(
                      _emailSent ? 'Check Your Email' : 'Forgot Password?',
                      style: TextStyle(
                        fontSize: screenWidth * (isLargeScreen ? 0.06 : 0.08),
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // Description
                    Text(
                      _emailSent
                          ? 'We\'ve sent a password reset link to your email. Please check your inbox and spam folder.'
                          : 'Enter your email address and we\'ll send you a link to reset your password.',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: screenHeight * 0.05),

                    if (!_emailSent) ...[
                      // Email TextField
                      TextField(
                        controller: _emailController,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.white70,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(screenWidth * 0.03),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(
                            Icons.email,
                            color: Colors.white70,
                            size: screenWidth * 0.06,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.025,
                            horizontal: screenWidth * 0.055,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.white,
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      // Send Reset Email Button
                      SizedBox(
                        width: double.infinity,
                        height: screenHeight * 0.075,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSendResetEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            Colors.blue.withValues(alpha: 0.8),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(screenWidth * 0.03),
                            ),
                            elevation: 5,
                          ),
                          child: _isLoading
                              ? SizedBox(
                            width: screenWidth * 0.06,
                            height: screenWidth * 0.06,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                              : Text(
                            'Send Reset Link',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Email Sent Success State
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius:
                          BorderRadius.circular(screenWidth * 0.03),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade300,
                              size: screenWidth * 0.06,
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Text(
                                'Email sent to:\n${_emailController.text}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // Resend Email Button
                      TextButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () {
                          setState(() => _emailSent = false);
                        },
                        icon: Icon(
                          Icons.refresh,
                          color: Colors.blue.shade300,
                          size: screenWidth * 0.05,
                        ),
                        label: Text(
                          'Resend Email',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.blue.shade300,
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Back to Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: screenHeight * 0.07,
                        child: OutlinedButton(
                          onPressed: () => context.go(AppRoutes.signIn),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(screenWidth * 0.03),
                            ),
                          ),
                          child: Text(
                            'Back to Sign In',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: screenHeight * 0.03),

                    // Help Text
                    if (!_emailSent)
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius:
                          BorderRadius.circular(screenWidth * 0.03),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.white70,
                              size: screenWidth * 0.05,
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Text(
                                'Make sure to check your spam folder if you don\'t see the email.',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.032,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: screenHeight * 0.05),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}