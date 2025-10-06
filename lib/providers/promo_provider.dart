import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/promo_model.dart';

part 'promo_provider.g.dart';

@riverpod
Stream<List<PromoModel>> promo(PromoRef ref){
  final firestore = FirebaseFirestore.instance;
  Timestamp today = Timestamp.now();
  DateTime date = today.toDate().add(const Duration(hours: 8));
  return firestore.
      collection('Promo')
      .where('start_date', isLessThanOrEqualTo: date)
      .where('end_date', isGreaterThanOrEqualTo: date)
      .where('is_general_promo', isEqualTo: true)
      .snapshots()
      .map((snapshots){
    return snapshots.docs.map((doc) => PromoModel.fromDocument(doc)).toList();
  });
}
@riverpod
Stream<List<PromoModel>> allPromo(AllPromoRef ref){
  final firestore = FirebaseFirestore.instance;
  Timestamp today = Timestamp.now();
  DateTime date = today.toDate().add(const Duration(hours: 8));
  return firestore.
  collection('Promo')
      .where('start_date', isLessThanOrEqualTo: date)
      .where('end_date', isGreaterThanOrEqualTo: date)
      .snapshots()
      .map((snapshots){
    return snapshots.docs.map((doc) => PromoModel.fromDocument(doc)).toList();
  });
}
@riverpod
Stream<List<PromoModel>> promoVehicleType(PromoVehicleTypeRef ref, String vehicleType){
  final firestore = FirebaseFirestore.instance;
  Timestamp today = Timestamp.now();
  DateTime date = today.toDate().add(const Duration(hours: 8));
  return firestore.
  collection('Promo')
      .where('location', arrayContains: vehicleType)
      .where('start_date', isLessThanOrEqualTo: date)
      .where('end_date', isGreaterThanOrEqualTo: date)
      .snapshots()
      .map((snapshots){
    return snapshots.docs.map((doc) => PromoModel.fromDocument(doc)).toList();
  });
}