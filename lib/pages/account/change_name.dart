import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/providers/user_provider.dart';

class NameChange extends ConsumerStatefulWidget {
  final String? name;
  const NameChange({super.key, required this.name});

  @override
  ConsumerState<NameChange> createState() => _NameChangeState();
}

class _NameChangeState extends ConsumerState<NameChange> {
  final _formkey = GlobalKey<FormState>();
  String changeName = ''; 
  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseServiceProvider);
    final user = ref.watch(authStateProvider).value;
    return Form(
      key: _formkey,
        child: Column(
          children: <Widget>[
            const Text('Update your name', style: TextStyle(fontSize: 23.0, fontWeight: FontWeight.bold),),
            const SizedBox(height: 15.0,),
            TextFormField(
              initialValue: widget.name ?? '',
              decoration: const InputDecoration(
                fillColor: Colors.white,
                filled: true,
              ),
              validator: (val) => val!.isEmpty ? 'Please enter name' : null,
              onChanged: (val) => setState(() {
                changeName = val;
              }),
            ),
            const SizedBox(height: 20.0,),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () async {
                if(_formkey.currentState!.validate()) {
                  await database.updatePassengerName(user!.uid, changeName);
                  Navigator.pop(context);
                }
              },
              child: const Text('Update', style: TextStyle(color: Colors.white, fontSize: 18.0),),

            ),
          ],
        ),

    );
  }
}
