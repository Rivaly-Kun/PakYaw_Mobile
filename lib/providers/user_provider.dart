
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pakyaw/models/user.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_provider.g.dart';

@riverpod
Stream<Users> getUser(GetUserRef ref, String id){
  final firestore = FirebaseFirestore.instance;
  return firestore.collection('Passengers').doc(id)
      .snapshots()
      .map((doc) => Users.fromDocument(doc));
}

class UserNotifier extends AsyncNotifier<Users?> {

  @override
  FutureOr<Users?> build() async {
    final user = ref.watch(authStateProvider).value;
    if (user?.uid != null) {
      return ref.watch(userStreamProvider(user!.uid)).when(
        data: (user) {
          print('Returned something');
          return user;
        },
        loading: () => null,
        error: (_, __) => null,
      );
    } else {
      return null;
    }
  }
}

class PaymentMethodNotifier extends AsyncNotifier<PaymentMethod?> {

  @override
  FutureOr<PaymentMethod?> build() async {
    final user = ref.watch(authStateProvider).value;
    if (user?.uid != null) {
      return ref.watch(paymentStreamProvider(user!.uid)).when(
        data: (user) => user,
        loading: () => null,
        error: (_, __) => null,
      );
    } else {
      return null;
    }
  }
}

final paymentStreamProvider = StreamProvider.family<PaymentMethod?, String>((ref, uid) {
  final database = ref.watch(databaseServiceProvider);
  return database.getPaymentMethods(uid);
});

final paymentMethodProvider = AsyncNotifierProvider<PaymentMethodNotifier, PaymentMethod?>(() {
  return PaymentMethodNotifier();
});


final userStreamProvider = StreamProvider.family<Users?, String>((ref, uid) {
  final database = ref.watch(databaseServiceProvider);
  return database.getUserStream(uid);
});

final usersProvider = AsyncNotifierProvider<UserNotifier, Users?>(() {
  return UserNotifier();
});