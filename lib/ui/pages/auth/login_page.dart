import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme.dart';
import '../../../data/providers/auth_providers.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/analytics_service.dart';
import '../../../widgets/app_header.dart';

class LoginPage extends ConsumerStatefulWidget {
  final bool initialSignUp;

  const LoginPage({super.key, this.initialSignUp = false});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSignUp = false;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;

  bool get _canSubmit => _agreeTerms && _agreePrivacy && !_isLoading;
  bool get _showApple => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('login_page');
    _isSignUp = widget.initialSignUp;
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $url')),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (!_canSubmit) return;
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      if (mounted) {
        AnalyticsService.logLogin('google');
        context.go('/mentors');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithApple() async {
    if (!_canSubmit || !_showApple) return;
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithApple();
      if (mounted) {
        AnalyticsService.logLogin('apple');
        context.go('/mentors');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Apple sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitEmail() async {
    if (!_canSubmit) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      if (_isSignUp) {
        await authService.createUserWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (mounted) {
          AnalyticsService.logSignUp('email');
        }
      } else {
        await authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (mounted) {
          AnalyticsService.logLogin('email');
        }
      }
      if (mounted) {
        context.go('/mentors');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WFColors.base,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(WFDims.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // Logo and Title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: WFGradients.purpleGradient,
                          borderRadius: BorderRadius.circular(WFDims.radiusXLarge),
                          boxShadow: WFShadows.purpleGlow,
                        ),
                        child: const Icon(
                          Icons.school,
                          size: 40,
                          color: WFColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: WFDims.spacingL),
                      Text(
                        _isSignUp ? 'Join the Circle' : 'Welcome Back',
                        style: WFTextStyles.h1.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: WFDims.spacingS),
                      Text(
                        _isSignUp 
                          ? 'Your transformation begins now'
                          : 'Continue your journey',
                        style: WFTextStyles.bodyMedium.copyWith(
                          color: WFColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: WFDims.spacingXL),

                // Terms & Privacy
                Row(
                  children: [
                    Checkbox(
                      value: _agreeTerms,
                      onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                      activeColor: WFColors.purple400,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.start,
                        children: [
                          Text(
                            'I agree to the ',
                            style: WFTextStyles.bodySmall.copyWith(color: WFColors.gray400),
                          ),
                          InkWell(
                            onTap: () => _openUrl('https://stossthegreat.github.io/Whisper/terms.html'),
                            child: Text(
                              'Terms & Conditions',
                              style: WFTextStyles.bodySmall.copyWith(color: WFColors.purple400, decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _agreePrivacy,
                      onChanged: (v) => setState(() => _agreePrivacy = v ?? false),
                      activeColor: WFColors.purple400,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.start,
                        children: [
                          Text(
                            'I agree to the ',
                            style: WFTextStyles.bodySmall.copyWith(color: WFColors.gray400),
                          ),
                          InkWell(
                            onTap: () => _openUrl('https://stossthegreat.github.io/Whisper/privacy.html'),
                            child: Text(
                              'Privacy Policy',
                              style: WFTextStyles.bodySmall.copyWith(color: WFColors.purple400, decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: WFDims.spacingM),

                // Social Sign-in Buttons
                _SocialSignInButton(
                  text: 'Continue with Google',
                  icon: Icons.g_mobiledata,
                  backgroundColor: Colors.white,
                  textColor: Colors.black87,
                  onPressed: _canSubmit ? _signInWithGoogle : null,
                ),
                
                const SizedBox(height: WFDims.spacingM),
                if (_showApple)
                _SocialSignInButton(
                  text: 'Continue with Apple',
                  icon: Icons.apple,
                  backgroundColor: Colors.black,
                  textColor: Colors.white,
                    onPressed: _canSubmit ? _signInWithApple : null,
                ),
                
                const SizedBox(height: WFDims.spacingL),
                
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: WFColors.gray600)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: WFDims.spacingM),
                      child: Text(
                        'or',
                        style: WFTextStyles.bodySmall.copyWith(color: WFColors.gray500),
                      ),
                    ),
                    Expanded(child: Divider(color: WFColors.gray600)),
                  ],
                ),
                
                const SizedBox(height: WFDims.spacingL),

                // Email/Password Form
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: WFTextStyles.bodyMedium.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: WFColors.gray400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(WFDims.radiusMedium),
                      borderSide: BorderSide(color: WFColors.gray600),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(WFDims.radiusMedium),
                      borderSide: BorderSide(color: WFColors.gray600),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(WFDims.radiusMedium),
                      borderSide: BorderSide(color: WFColors.purple400),
                    ),
                    filled: true,
                    fillColor: WFColors.gray800,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: WFDims.spacingM),
                
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: WFTextStyles.bodyMedium.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: WFColors.gray400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(WFDims.radiusMedium),
                      borderSide: BorderSide(color: WFColors.gray600),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(WFDims.radiusMedium),
                      borderSide: BorderSide(color: WFColors.gray600),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(WFDims.radiusMedium),
                      borderSide: BorderSide(color: WFColors.purple400),
                    ),
                    filled: true,
                    fillColor: WFColors.gray800,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (_isSignUp && value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: WFDims.spacingL),

                // Sign In/Up Button
                ElevatedButton(
                  onPressed: _canSubmit ? _submitEmail : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WFColors.purple400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: WFDims.spacingM),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(WFDims.radiusMedium),
                    ),
                  ),
                  child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isSignUp ? 'Create Account' : 'Sign In',
                        style: WFTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ),
                
                const SizedBox(height: WFDims.spacingM),

                // Toggle Sign In/Up
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp 
                      ? 'Already have an account? Sign In'
                      : 'Don\'t have an account? Sign Up',
                    style: WFTextStyles.bodySmall.copyWith(
                      color: WFColors.purple400,
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

class _SocialSignInButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onPressed;

  const _SocialSignInButton({
    required this.text,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: WFDims.spacingM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WFDims.radiusMedium),
          side: BorderSide(color: WFColors.gray600),
        ),
      ),
      icon: Icon(icon, size: 24),
      label: Text(
        text,
        style: WFTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
} 