import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/services/auth.dart';

class OtpVerification extends StatefulWidget {
  final String verificationID;
  final String phoneNum;
  const OtpVerification({super.key, required this.verificationID, required this.phoneNum});

  @override
  State<OtpVerification> createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> {

  final AuthService _authService = AuthService(FirebaseAuth.instance);

  final _formKey = GlobalKey<FormState>();
  List<String> otp = [];
  String fOTP = '';

  // PAKYAW Brand Colors
  static const Color primaryNavy = Color(0xFF0B2E6B);
  static const Color brightBlue = Color(0xFF1C72DD);
  static const Color lightBlue = Color(0xFF1B99FF);
  static const Color darkGray = Color(0xFF303841);
  static const Color lightBackground = Color(0xFFF3F3F3);

  Future<void> _submitOTP(BuildContext context) async {
    String otp = fOTP.trim();

    try{
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationID,
        smsCode: otp,
      );

      await _authService.signInWithCredentials(credential);
    }catch(e){
      print(e.toString());
    }

  }

  String _formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.startsWith('+63')) {
      String number = phoneNumber.substring(3);
      if (number.length >= 3) {
        return '+63 ${number.substring(0, 3)} ${number.substring(3)}';
      }
    }
    return phoneNumber;
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryNavy, brightBlue, lightBlue],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: brightBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 3,
          ),
        ],
      ),
      child: const Icon(
        Icons.directions_car,
        size: 40,
        color: Colors.white,
      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: <Widget>[
                  // Header with back button
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: darkGray,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Logo section
                  Column(
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 16),
                      const Text(
                        'PAKYAW',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: primaryNavy,
                          fontFamily: 'Montserrat',
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Title section
                  Column(
                    children: [
                      const Text(
                        'Verification Code',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: darkGray,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontFamily: 'Montserrat',
                            height: 1.4,
                          ),
                          children: [
                            const TextSpan(text: 'We sent a 6-digit code to\n'),
                            TextSpan(
                              text: _formatPhoneNumber(widget.phoneNum),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: primaryNavy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // OTP Form section
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // OTP Input Fields
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            6,
                                (index) => Container(
                              width: 50,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                onChanged: (val) {
                                  if (val.length == 1) {
                                    if (index < 5) FocusScope.of(context).nextFocus();
                                    if (otp.length <= index) {
                                      otp.add(val);
                                    } else {
                                      otp[index] = val;
                                    }
                                  } else if (val.isEmpty) {
                                    if (index > 0) FocusScope.of(context).previousFocus();
                                    if (otp.isNotEmpty && otp.length > index) {
                                      otp.removeAt(index);
                                    }
                                  }
                                },
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: darkGray,
                                  fontFamily: 'Montserrat',
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: brightBlue, width: 2),
                                  ),
                                  enabledBorder: InputBorder.none,
                                  counterText: '',
                                ),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(1),
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                maxLength: 1,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Verify Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [primaryNavy, brightBlue, lightBlue],
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
                              onTap: () async {
                                fOTP = otp.join('');
                                print(fOTP);
                                _submitOTP(context);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                alignment: Alignment.center,
                                child: const Text(
                                  'Verify Code',
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
                        ),

                        const SizedBox(height: 32),

                        // Resend Section
                        Column(
                          children: [
                            Text(
                              'Didn\'t receive the code?',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // Add resend code functionality here
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                  child: Text(
                                    'Resend Code',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: brightBlue,
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Security Note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: brightBlue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: brightBlue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: brightBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your information is secure and encrypted',
                            style: TextStyle(
                              fontSize: 12,
                              color: brightBlue,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}