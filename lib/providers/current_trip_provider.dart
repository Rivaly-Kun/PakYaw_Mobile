import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pakyaw/models/current_trip.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_trip_provider.g.dart';

@riverpod
Stream<CurrentTrip> currentTrip(CurrentTripRef ref, String Tripid) {
  final firestore = FirebaseFirestore.instance;
  print('maybe even here?');
  return firestore
      .collection('Trips')
      .doc(Tripid)
      .snapshots()
      .map((doc) {
    return CurrentTrip.fromDocument(doc);
  });
}