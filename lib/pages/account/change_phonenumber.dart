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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formkey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Update Phone Number',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: const Text(
                      '+63',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Phone Number',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (val) => setState(() => phoneNum = val),
                    ),
                  ),
                ],
              ),
            ),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (_formkey.currentState!.validate()) {
                    if (phoneNum!.length != 10) {
                      setState(() => error = 'Mobile number must be 10 digits.');
                      return;
                    }
                    
                    final mobileNo = '+63$phoneNum';
                    final user = ref.read(authStateProvider).value;
                    
                    if (widget.providerType != null) {
                      await reAuthPhoneNum(mobileNo, widget.context1);
                      await ref.read(databaseServiceProvider).updatePassengerPhoneNum(
                            user!.uid,
                            mobileNo,
                          );
                    } else {
                      await ref.read(databaseServiceProvider).updatePassengerPhoneNum(
                            user!.uid,
                            mobileNo,
                          );
                    }
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
