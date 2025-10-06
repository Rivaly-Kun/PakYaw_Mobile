import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/providers/user_provider.dart';
import 'package:pakyaw/shared/size_config.dart';

import '../../../providers/trip_provider.dart';

class Note extends ConsumerStatefulWidget {
  final String? name;
  const Note({super.key, required this.name});

  @override
  ConsumerState<Note> createState() => _NoteState();
}

class _NoteState extends ConsumerState<Note> {
  final _formkey = GlobalKey<FormState>();
  String changeName = '';
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Form(
      key: _formkey,
      child: Column(
        children: <Widget>[
          const Text('Notes', style: TextStyle(fontSize: 23.0, fontWeight: FontWeight.bold),),
          Text(
            'Do you want to give instructions or extra information to the driver?',
            style: TextStyle(
              color: Colors.black,
              fontSize: SizeConfig.safeBlockHorizontal * 4,
              fontWeight: FontWeight.w500
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15.0,),
          TextFormField(
            maxLines: null,
            keyboardType: TextInputType.multiline,
            initialValue: widget.name ?? '',
            decoration: const InputDecoration(
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
              fillColor: Colors.white70,
              filled: true,
              labelText: 'Enter notes here',
            ),
            onChanged: (val) => setState(() {
              changeName = val;
            }),
          ),
          const SizedBox(height: 20.0,),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () async {
              if(_formkey.currentState!.validate()) {
                ref.read(tripProvider.notifier).updateTrip((trip) => trip.copyWith(
                    notes: changeName
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 18.0),),

          ),
        ],
      ),

    );
  }
}
