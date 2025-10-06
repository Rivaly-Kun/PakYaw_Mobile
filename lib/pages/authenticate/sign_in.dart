import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/pages/authenticate/otp_verification.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/providers/user_provider.dart';

class SignIn extends ConsumerStatefulWidget {
  const SignIn({super.key});

  @override
  ConsumerState<SignIn> createState() => _SignInState();
}

class _SignInState extends ConsumerState<SignIn> {

  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;

  String mobileNo = '';
  String error = '';

  Future<void> _submitPhoneNumber(BuildContext context) async {
    String phoneNumber = '+63${mobileNo.trim()}';
    FirebaseAuth auth = FirebaseAuth.instance;

    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {

      },
      verificationFailed: (FirebaseAuthException e){
        print(e.toString());
      },
      codeSent: (String verificationId, int? resendToken){
        Navigator.push(context, MaterialPageRoute(builder: (context) => OtpVerification(verificationID: verificationId, phoneNum: phoneNumber,)));
      },
      codeAutoRetrievalTimeout: (String verificationId){

      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final _authService = ref.watch(authServiceProvider);
    return Scaffold(
      body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 120.0,),
                Container(
                  margin: const EdgeInsets.fromLTRB(20.0, 50.0, 0.0, 0.0),
                  child: const Text(
                    'Enter your mobile number',
                    style: TextStyle(
                      fontSize: 30.0,
                    ),
                  ),
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 3.0),
                          borderRadius: BorderRadius.circular(10.0),
                          color: Colors.grey[350],
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 12.0),
                        margin: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 0.0),
                        child: Row(
                          children: <Widget>[
                            const SizedBox(width: 3.0,),
                            const Text(
                              '+63',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 3.0,),
                            Expanded(
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 18.0,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Mobile Number',
                                  hintStyle: const TextStyle(
                                    fontSize: 16.0,
                                  ),
                                  fillColor: Colors.grey[350],
                                  filled: true,
                                  enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide.none
                                  )
                                ),
                                onChanged: (val) => {
                                  setState(() => mobileNo = val)
                                },
                              ),
                            ),
                            const SizedBox(width: 20.0,),
                            const Icon(Icons.phone)
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(20.0, 0.0, 0.0, 0.0),
                        child: Text(error,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14.0,
                          ),),
                      ),
                      const SizedBox(height: 10.0,),
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
                                if(mobileNo.isEmpty){
                                  setState(() => error = 'Type in a mobile number');
                                }else if(mobileNo.length != 10){
                                  setState(() => error = 'Mobile number must be 11 digits.');
                                }else{
                                  print(mobileNo);
                                  _submitPhoneNumber(context);
                                  setState(() => error = '');
                                }
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
                      const SizedBox(height: 9.0,),
                      const Row(
                        children: <Widget>[
                          SizedBox(width: 20.0,),
                          Expanded(child: Divider()),
                          SizedBox(width: 5.0,),
                          Text('or'),
                          SizedBox(width: 5.0,),
                          Expanded(child: Divider()),
                          SizedBox(width: 20.0,),
                        ],
                      ),
                      const SizedBox(height: 10.0,),
                      SizedBox(
                        width: 100.0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: isLoading ? const CircularProgressIndicator() : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[350],
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0)
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 15.0)
                            ),
                            onPressed: () async{
                              await _authService.signInWithGoogle();
                            },
                            child: const Image(
                              image: AssetImage('assets/Google.png'),
                              width: 30.0,
                              height: 30.0,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10.0,),
                      // SizedBox(
                      //   width: double.infinity,
                      //   child: Padding(
                      //     padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      //     child: ElevatedButton(
                      //       style: ElevatedButton.styleFrom(
                      //           backgroundColor: Colors.grey,
                      //           shape: RoundedRectangleBorder(
                      //               borderRadius: BorderRadius.circular(10.0)
                      //           ),
                      //           padding: const EdgeInsets.symmetric(vertical: 15.0)
                      //       ),
                      //       onPressed: () async{
                      //         if(_formKey.currentState!.validate()){
                      //         }
                      //       },
                      //       child: const Row(
                      //         mainAxisAlignment: MainAxisAlignment.center,
                      //         children: [
                      //           Icon(
                      //             Icons.mail,
                      //             size: 30.0,
                      //             color: Colors.black,
                      //           ),
                      //           SizedBox(width: 5.0,),
                      //           Text(
                      //               'Email',
                      //               style: TextStyle(
                      //                 color: Colors.white,
                      //                 fontSize: 20.0,)
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ),
                      // ),
            
                    ],
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}


