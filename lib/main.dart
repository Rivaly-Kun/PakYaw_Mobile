import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/pages/authenticate/sign_in.dart';
import 'package:pakyaw/pages/wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pakyaw/shared/global_var.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Permission.locationWhenInUse.isDenied.then((value){
    if(value){
      Permission.locationWhenInUse.request();
    }
  });
  await FirebaseAppCheck.instance.activate(// Only needed for web
    androidProvider: AndroidProvider.debug,  // Use .playIntegrity for production
    appleProvider: AppleProvider.appAttest,  // Use .deviceCheck for iOS < 14
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const Wrapper(),
      navigatorObservers: [routeObserver],
    );
  }
}

