import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/shared/size_config.dart';

import '../authenticate/update_otp_verification.dart';

class PhoneChange extends ConsumerStatefulWidget {
  final String? number;
  final String? providerType;
  final BuildContext context1;
  const PhoneChange({super.key, required this.number, required this.providerType, required this.context1});

  @override
  ConsumerState<PhoneChange> createState() => _PhoneChangeState();
}

class _PhoneChangeState extends ConsumerState<PhoneChange> {

  final _formkey = GlobalKey<FormState>();
  String? phoneNum;
  String error = '';

  reAuthPhoneNum(String phoneNumber, BuildContext context) async {
    FirebaseAuth auth = FirebaseAuth.instance;

    final User? user = auth.currentUser;

    if(user != null){
      try{

        await auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Automatically sign in the user if verification is automatic
            await user.updatePhoneNumber(credential);
            print('Phone number updated successfully');
          },
          verificationFailed: (FirebaseAuthException e) {
            print('Phone number verification failed: ${e.message}');
          },
          codeSent: (String verificationId, int? resendToken) async {
            Navigator.push(context, MaterialPageRoute(builder: (context) => UpdateOtpVerification(verificationID: verificationId, phoneNum: phoneNumber)));
          },
          codeAutoRetrievalTimeout: (String verificationId){

          },

        );


      }catch (e){
        print('error yessirs: $e.toString()');
      }
    } else {
      print('No user is currently signed in');
    }

  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final database = ref.watch(databaseServiceProvider);
    final user = ref.watch(authStateProvider).value;
    final auth = ref.watch(authServiceProvider);
    return Form(
      key: _formkey,
      child: Column(
        children: <Widget>[
          const Text('Update your phone number', style: TextStyle(fontSize: 23.0, fontWeight: FontWeight.bold),),
          const SizedBox(height: 15.0,),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              color: Colors.grey[350],
            ),
            padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 12.0),
            child: Row(
              children: [
                const SizedBox(width: 3.0,),
                Text(
                  '+63',
                  style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 3.0,),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.phone,
                    style: TextStyle(
                      fontSize: SizeConfig.safeBlockHorizontal * 4,
                    ),
                    decoration: InputDecoration(
                        hintText: 'Mobile Number',
                        hintStyle: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 4,
                        ),
                        fillColor: Colors.grey[350],
                        filled: true,
                        enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide.none
                        )
                    ),
                    onChanged: (val) => {
                        setState(() => phoneNum = val)
                    },
                  ),
                ),
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
          const SizedBox(height: 20.0,),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () async {
              if(_formkey.currentState!.validate()){
                if(phoneNum!.length != 10){
                  setState(() => error = 'Mobile number must be 10 digits.');
                }else{
                  String mobileNo = '+63$phoneNum';
                  if(widget.providerType != null){
                    await reAuthPhoneNum(mobileNo, widget.context1);
                    await database.updatePassengerPhoneNum(user!.uid, mobileNo);
                    Navigator.pop(context);
                  }else{
                    await database.updatePassengerPhoneNum(user!.uid, mobileNo);
                    Navigator.pop(context);
                  }
                }
              }
            },
            child: const Text('Update', style: TextStyle(color: Colors.white, fontSize: 18.0),),

          ),
        ],
      ),

    );
  }
}
