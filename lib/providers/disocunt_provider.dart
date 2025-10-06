import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pakyaw/models/discount_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/promo_model.dart';

part 'disocunt_provider.g.dart';

@riverpod
Stream<List<DiscountModel>> discount(DiscountRef ref){
  final firestore = FirebaseFirestore.instance;
  final today = Timestamp.now();
  return firestore.
  collection('Discounts')
      .where('status', isEqualTo: 'Active')
      .snapshots()
      .map((snapshots){
    return snapshots.docs.map((doc) => DiscountModel.fromDocument(doc)).toList();
  });
}