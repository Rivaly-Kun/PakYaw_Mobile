// lib/pages/authenticate/sign_in.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart'; // <-- ADD THIS IMPORT
import 'package:pakyaw/pages/authenticate/otp_verification.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/providers/user_provider.dart';

class SignIn extends ConsumerStatefulWidget {
  const SignIn({super.key});

  @override
  ConsumerState<SignIn> createState() => _SignInState();
}

class _SignInState extends ConsumerState<SignIn>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();

  bool isLoading = false;
  bool isGoogleLoading = false;
  String mobileNo = '';
  String error = '';

  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _logoAnimationController;
  late AnimationController _errorAnimationController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _errorAnimation;

  // PAKYAW Brand Colors
  static const Color primaryNavy = Color(0xFF0B2E6B);
  static const Color brightBlue = Color(0xFF1C72DD);
  static const Color lightBlue = Color(0xFF1B99FF);
  static const Color darkGray = Color(0xFF303841);
  static const Color lightBackground = Color(0xFFF3F3F3);
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _errorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _logoScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    _errorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _errorAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _logoAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _slideAnimationController.forward();
    });

    // Add focus listener to reduce lag
    _phoneFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _logoAnimationController.dispose();
    _errorAnimationController.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitPhoneNumber(BuildContext context) async {
    if (isLoading) return; // Prevent multiple submissions

    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      String phoneNumber = '+63${mobileNo.trim()}';
      FirebaseAuth auth = FirebaseAuth.instance;

      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          setState(() => isLoading = false);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            isLoading = false;
            error = 'Verification failed. Please try again.';
          });
          _errorAnimationController.forward().then((_) {
            Future.delayed(const Duration(milliseconds: 200), () {
              _errorAnimationController.reverse();
            });
          });
          HapticFeedback.lightImpact();
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => isLoading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerification(
                verificationID: verificationId,
                phoneNum: phoneNumber,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() => isLoading = false);
        },
      );
    } catch (e) {
      setState(() {
        isLoading = false;
        error = 'An error occurred. Please try again.';
      });
      _errorAnimationController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _errorAnimationController.reverse();
        });
      });
    }
  }

  void _validateAndSubmit() {
    if (mobileNo.isEmpty) {
      setState(() => error = 'Please enter your mobile number');
      _errorAnimationController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _errorAnimationController.reverse();
        });
      });
      HapticFeedback.lightImpact();
    } else if (mobileNo.length != 10) {
      setState(() => error = 'Mobile number must be 10 digits');
      _errorAnimationController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _errorAnimationController.reverse();
        });
      });
      HapticFeedback.lightImpact();
    } else {
      _submitPhoneNumber(context);
    }
  }

  // <-- MODIFIED SECTION
  Widget _buildLogo() {
    return ScaleTransition(
      scale: _logoScaleAnimation,
      // Use SvgPicture.asset to display your logo
      // Make sure you have renamed your asset to remove spaces for best practice
      child: SvgPicture.asset(
        'assets/pakyaw_logo.svg',
        height: 150, // You can adjust this size as needed
      ),
    );
  }
  // END OF MODIFIED SECTION

  Widget _buildPhoneInput() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: _phoneFocusNode.hasFocus ? brightBlue : Colors.grey.withOpacity(0.2),
          width: _phoneFocusNode.hasFocus ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Country code section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryNavy.withOpacity(0.1), brightBlue.withOpacity(0.1)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: brightBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.phone,
                    color: brightBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '+63',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: darkGray,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),

          // Phone number input
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: darkGray,
                fontFamily: 'Montserrat',
              ),
              decoration: const InputDecoration(
                hintText: '9XX XXX XXXX',
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontFamily: 'Montserrat',
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              onChanged: (val) {
                setState(() {
                  mobileNo = val;
                  if (error.isNotEmpty) {
                    error = '';
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryNavy,
            brightBlue,
            lightBlue,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: brightBlue.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : _validateAndSubmit,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
                : const Text(
              'Continue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isGoogleLoading ? null : () async {
            setState(() => isGoogleLoading = true);
            final authService = ref.read(authServiceProvider);
            try {
              await authService.signInWithGoogle();
            } catch (e) {
              setState(() {
                error = 'Google sign-in failed. Please try again.';
                isGoogleLoading = false;
              });
              _errorAnimationController.forward().then((_) {
                Future.delayed(const Duration(milliseconds: 200), () {
                  _errorAnimationController.reverse();
                });
              });
            }
            // A setState call here might not be necessary if navigation happens on success
            if (mounted) {
              setState(() => isGoogleLoading = false);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            alignment: Alignment.center,
            child: isGoogleLoading
                ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: brightBlue,
                strokeWidth: 3,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Image.asset(
                    'assets/Google.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.g_mobiledata,
                        color: brightBlue,
                        size: 24,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: darkGray,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey.withOpacity(0.3),
                  Colors.grey.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Montserrat',
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey.withOpacity(0.3),
                  Colors.grey.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lightBackground,
              Colors.white,
              lightBackground.withOpacity(0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Logo section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        _buildLogo(),
                        const SizedBox(height: 24),
                        const Text(
                          'PAKYAW',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: primaryNavy,
                            fontFamily: 'Montserrat',
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your ride, your way',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Welcome text
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: darkGray,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your mobile number to continue',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Form section
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Phone input
                            _buildPhoneInput(),

                            // Error message
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: error.isNotEmpty ? 40 : 0,
                              child: error.isNotEmpty
                                  ? ScaleTransition(
                                scale: _errorAnimation,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: errorRed.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: errorRed.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: errorRed,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          error,
                                          style: const TextStyle(
                                            color: errorRed,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Montserrat',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                                  : const SizedBox.shrink(),
                            ),

                            const SizedBox(height: 24),

                            // Continue button
                            _buildContinueButton(),

                            const SizedBox(height: 32),

                            // Divider
                            _buildDivider(),

                            const SizedBox(height: 24),

                            // Google sign-in button
                            _buildGoogleSignInButton(),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Footer
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontFamily: 'Montserrat',
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}