
import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
final firebaseStorage  = FirebaseStorage.instance;

Future uploadPassengerProfilePic(String typeOfDoc, String uid, File? image) async {
  if(image == null) return;

  File file = File(image.path);
  final filename = path.basename(file.path);
  try{
    String filepath = 'PassengerProfilePics/${uid}_${typeOfDoc}_$filename';

    await firebaseStorage.ref(filepath).putFile(file);

    String url = await firebaseStorage.ref(filepath).getDownloadURL();
    return url;

  }catch(e){
    print(e.toString());
  }

}
Future uploadPassengerIDPic(String typeOfDoc, String uid, File? image, String filename) async {
  if(image == null) return;
  try{
    String filepath = 'PassengerIDPics/${uid}_${typeOfDoc}_$filename';

    await firebaseStorage.ref(filepath).putFile(image);

    String url = await firebaseStorage.ref(filepath).getDownloadURL();
    return url;

  }catch(e){
    print(e.toString());
  }

}

}