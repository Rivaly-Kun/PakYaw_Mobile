import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/auth_provider.dart';

class ChangeProfile extends ConsumerStatefulWidget {
  const ChangeProfile({super.key});

  @override
  ConsumerState<ChangeProfile> createState() => _ChangeProfileState();
}

class _ChangeProfileState extends ConsumerState<ChangeProfile> {

  File? image;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final storageService = ref.watch(storageServiceProvider);
    final databaseService = ref.watch(databaseServiceProvider);
    final user = ref.watch(authStateProvider).value;
    return Column(
      children: [
        const SizedBox(height: 20.0,),
        GestureDetector(
          onTap: () async {
            final picture = await ImagePicker().pickImage(source: ImageSource.gallery);

            if(picture != null){
              image = File(picture.path);
              setState(() {
              });
            }
          },
          child: Center(
            child: Container(
              width: 120.0,
              height: 120.0,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
              ),
              padding: const EdgeInsets.all(5.0),
              child: image != null ? Image.file(image!) : const Image(
                image: AssetImage("assets/profile_pic.png"),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20.0,),
        SizedBox(
          width: 200.0,
          height: 50.0,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                elevation: 2,
                backgroundColor: Colors.grey[350],
                shadowColor: Colors.black
            ),
            onPressed:  image!=null ? () async {
              if(image != null){
                setState(() {
                  isLoading = true;
                });
                String url = await storageService.uploadPassengerProfilePic('profilePic', user!.uid, image);
                await databaseService.addPassengerProfilePic(user.uid, url);

                setState(() {
                  isLoading = false;
                });
                if (context.mounted) Navigator.pop(context);
              }
            } : null,
            child: !isLoading ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Upload',
                  style: TextStyle(
                      fontSize: 17.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black
                  ),
                ),
                Icon(Icons.upload, size: 30.0, color: Colors.black,),
              ],
            ) : const CircularProgressIndicator(),

          ),
        )
      ],
    );
  }
}
