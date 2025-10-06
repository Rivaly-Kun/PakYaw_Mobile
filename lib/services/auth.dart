import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pakyaw/pages/authenticate/update_otp_verification.dart';

class AuthService{
  const AuthService(this._auth);
  final FirebaseAuth _auth;

  Stream<User?> get authStateChange => _auth.authStateChanges();


  Future<User?> signInWithGoogle() async {
    try{
      final googleUser = await GoogleSignIn().signIn();

      final googleAuth = await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(idToken: googleAuth?.idToken, accessToken: googleAuth?.accessToken);

      final resut = await _auth.signInWithCredential(credential);

      return resut.user;
    }catch(e){
      print(e.toString());
    }
  }

  updatePhoneNum(String verificationId, String otp) async {

    final User? user = FirebaseAuth.instance.currentUser;

    try{
      PhoneAuthCredential cred = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: otp);

      await user!.updatePhoneNumber(cred);
    }catch(e){
      print('error in: ${e.toString()}');
    }




  }
  

  Future<User?> signInWithCredentials(PhoneAuthCredential credential) async {
    try {
      final result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> signOut() async {
    try{
      await _auth.signOut();
    }catch(e){
      print(e.toString());
    }

  }

}