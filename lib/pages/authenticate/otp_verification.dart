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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.fromLTRB(20.0, 30.0, 20.0, 13.0),
              child: Text(
                'Enter the 6-digit code sent to you at ${widget.phoneNum}',
                style: const TextStyle(
                  fontSize: 25.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12.0,),
            Form(
              key: _formKey,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    height: 58.0,
                    width: 54.0,
                    child: TextFormField(
                      onChanged: (val) {
                        if(val.length == 1){
                          FocusScope.of(context).nextFocus();
                          otp.add(val);
                        }else if(val.isEmpty){
                          setState(() => val = '');
                          otp.removeAt(otp.length - 1);
                        }
                      },
                      style: const TextStyle(
                        fontSize: 30.0
                      ),
                      decoration: InputDecoration(
                        fillColor: Colors.grey[350],
                        filled: true,
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(5.0)),
                          borderSide: BorderSide(color: Colors.black, width: 2.0)
                        )
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(1),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 58.0,
                    width: 54.0,
                    child: TextFormField(
                      onChanged: (val) {
                        if(val.length == 1){
                          FocusScope.of(context).nextFocus();
                          otp.add(val);
                        }else if(val.isEmpty){
                          FocusScope.of(context).previousFocus();
                          otp.removeAt(otp.length - 1);
                        }
                      },
                      style: const TextStyle(
                          fontSize: 30.0
                      ),
                      decoration: InputDecoration(
                          fillColor: Colors.grey[350],
                          filled: true,
                          focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(5.0)),
                              borderSide: BorderSide(color: Colors.black, width: 2.0)
                          )
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(1),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 58.0,
                    width: 54.0,
                    child: TextFormField(
                      onChanged: (val) {
                        if(val.length == 1){
                          FocusScope.of(context).nextFocus();
                          otp.add(val);
                        }else if(val.isEmpty){
                          FocusScope.of(context).previousFocus();
                          otp.removeAt(otp.length - 1);
                        }
                      },
                      style: const TextStyle(
                          fontSize: 30.0
                      ),
                      decoration: InputDecoration(
                          fillColor: Colors.grey[350],
                          filled: true,
                          focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(5.0)),
                              borderSide: BorderSide(color: Colors.black, width: 2.0)
                          )
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(1),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 58.0,
                    width: 54.0,
                    child: TextFormField(
                      onChanged: (val) {
                        if(val.length == 1){
                          FocusScope.of(context).nextFocus();
                          otp.add(val);
                        }else if(val.isEmpty){
                          FocusScope.of(context).previousFocus();
                          otp.removeAt(otp.length - 1);
                        }
                      },
                      style: const TextStyle(
                          fontSize: 30.0
                      ),
                      decoration: InputDecoration(
                          fillColor: Colors.grey[350],
                          filled: true,
                          focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(5.0)),
                              borderSide: BorderSide(color: Colors.black, width: 2.0)
                          )
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(1),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 58.0,
                    width: 54.0,
                    child: TextFormField(
                      onChanged: (val) {
                        if(val.length == 1){
                          FocusScope.of(context).nextFocus();
                          otp.add(val);
                        }else if(val.isEmpty){
                          FocusScope.of(context).previousFocus();
                          otp.removeAt(otp.length - 1);
                        }
                      },
                      style: const TextStyle(
                          fontSize: 30.0
                      ),
                      decoration: InputDecoration(
                          fillColor: Colors.grey[350],
                          filled: true,
                          focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(5.0)),
                              borderSide: BorderSide(color: Colors.black, width: 2.0)
                          )
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(1),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 58.0,
                    width: 54.0,
                    child: TextFormField(
                      onChanged: (val) {
                        if(val.length == 1){
                          FocusScope.of(context).nextFocus();
                          otp.add(val);

                        }else if(val.isEmpty){
                          FocusScope.of(context).previousFocus();
                          otp.removeAt(otp.length - 1);
                        }
                      },
                      style: const TextStyle(
                          fontSize: 30.0
                      ),
                      decoration: InputDecoration(
                          fillColor: Colors.grey[350],
                          filled: true,
                          focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(5.0)),
                              borderSide: BorderSide(color: Colors.black, width: 2.0)
                          )
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(1),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                ],
              ),

            ),
            const SizedBox(height: 40.0,),
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0)
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15.0)
                  ),
                  onPressed: () async {
                    fOTP = otp.join('');
                    print(fOTP);
                    _submitOTP(context);
                  },
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
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
