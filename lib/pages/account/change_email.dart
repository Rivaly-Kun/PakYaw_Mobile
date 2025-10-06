  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:pakyaw/providers/auth_provider.dart';

  class EmailChange extends ConsumerStatefulWidget {
    final String? email;
    const EmailChange({super.key, required this.email});

    @override
    ConsumerState<EmailChange> createState() => _EmailChangeState();
  }

  class _EmailChangeState extends ConsumerState<EmailChange> {
    final _formKey = GlobalKey<FormState>();
    String? email;



    @override
    Widget build(BuildContext context) {
      final userAuth = ref.watch(authServiceProvider);
      final databaseService = ref.watch(databaseServiceProvider);
      final user = ref.watch(authStateProvider).value;
      return Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            const Text('Update your email', style: TextStyle(fontSize: 23.0, fontWeight: FontWeight.bold),),
            const SizedBox(height: 15.0,),
            TextFormField(
              decoration: const InputDecoration(
                fillColor: Colors.white,
                filled: true,
              ),
              validator: (val) => val!.isEmpty ? 'Please enter email' : null,
              onChanged: (val) => email = val,
            ),
            const SizedBox(height: 20.0,),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () async {
                //TODO: ADD FUNCTION TO UPDATE EMAIL OF USER
                if(_formKey.currentState!.validate()){
                  await databaseService.updateEmail(user!.uid, email!);
                  Navigator.pop(context);
                }
              },
              child: const Text('Update', style: TextStyle(color: Colors.white, fontSize: 18.0),),

            ),
          ],
        ),

      );;
    }
  }
