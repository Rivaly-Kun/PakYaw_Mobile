import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/services/database.dart';
import '../services/auth.dart';
import '../services/storage.dart';

final authServiceProvider = Provider<AuthService>((ref){
  return AuthService(FirebaseAuth.instance);
});

final authStateProvider = StreamProvider<User?>((ref){
  return ref.read(authServiceProvider).authStateChange;
});

final databaseServiceProvider = Provider<DatabaseService>((ref){
  return DatabaseService();
});

final storageServiceProvider = Provider<StorageService>((ref){
  return StorageService();
});