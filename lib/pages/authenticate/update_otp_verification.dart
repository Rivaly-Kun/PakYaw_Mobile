import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/providers/auth_provider.dart';

class UpdateOtpVerification extends ConsumerStatefulWidget {
  final String verificationID;
  final String phoneNum;
  const UpdateOtpVerification({super.key, required this.verificationID, required this.phoneNum});

  @override
  ConsumerState<UpdateOtpVerification> createState() => _UpdateOtpVerificationState();
}

class _UpdateOtpVerificationState extends ConsumerState<UpdateOtpVerification> {

  final _formKey = GlobalKey<FormState>();
  List<String> otp = [];
  String fOTP = '';

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authServiceProvider);
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
            Container(
              margin: const EdgeInsets.fromLTRB(9.0, 0.0, 20.0, 9.0),
              child: TextButton(
                  onPressed: () => {

                  },
                  child: const Text(
                    'Changed your mobile number?',
                    style: TextStyle(
                      fontSize: 20.0,
                      decoration: TextDecoration.underline,
                    ),
                  )
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
                    await auth.updatePhoneNum(widget.verificationID, fOTP);
                    Navigator.pop(context);
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
