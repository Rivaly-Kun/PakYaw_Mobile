import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/pages/account/saved_places.dart';
import 'package:pakyaw/pages/authenticate/display_name.dart';
import 'package:pakyaw/pages/authenticate/sign_in.dart';
import 'package:pakyaw/pages/home/home.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/shared/loading.dart';

class Wrapper extends ConsumerWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final authState = ref.watch(authStateProvider);
    final userDbService = ref.watch(databaseServiceProvider);


    return authState.when(
      data: (user){
        if (user != null) {
          return FutureBuilder<bool>(
            future: userDbService.isNewUser(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Loading();
              }

              if (snapshot.hasError) {
                print('Error');
                return const SignIn();
              }

              final isNewUser = snapshot.data ?? true;
              print(isNewUser);
              return MaterialApp(
                initialRoute: isNewUser ? '/SetName' : '/Home',
                routes: {
                  '/': (_) => const SignIn(),
                  '/SetName': (_) => const SetName(),
                  '/Home': (_) => Home(id: user.uid),
                  '/SavedPlaces': (_) => const SavedPlaces(),// Add TripDetails route
                },
              );
            },
          );
        } else {
          return MaterialApp(
            initialRoute: '/',
            routes: {
              '/': (_) => const SignIn(),
              '/SetName': (_) => const SetName(),
              '/Home': (_) => const Home(id: '',),
              '/SavedPlaces': (_) => const SavedPlaces(), // Add TripDetails route
            },
          );
        }
      },
      error: (e, trace) => const SignIn(),
      loading: () => const Loading()
    );

    //return either sign-in or home page
    // return MaterialApp(
    //   initialRoute: '/',
    //   routes: {
    //     '/': (context) => SignIn(),
    //     '/OTP': (context) => OtpVerification(),
    //     '/SetName': (context) => SetName(),
    //     '/Home': (context) => Home(),
    //   },
    // );
  }
}
