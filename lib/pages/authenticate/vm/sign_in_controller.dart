import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/pages/authenticate/vm/sign_in_state.dart';
import 'package:pakyaw/providers/auth_provider.dart';

class SignInController extends StateNotifier<SignInState>{
  SignInController(this.ref) : super(const SignInStateInitial());

  final Ref ref;

  void login(PhoneAuthCredential credential) async {
    state = const SignInStateLoading();
    try{
      await ref.read(authServiceProvider).signInWithCredentials(credential);
      state = const SignInStateSuccess();
    }catch(e){
      state = SignInStateError(e.toString());
    }
  }
}

final signInControllerProvider = StateNotifierProvider<SignInController, SignInState>((ref){
  return SignInController(ref);
});