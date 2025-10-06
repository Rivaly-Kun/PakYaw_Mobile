import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pakyaw/models/history_ride_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_trip_provider.g.dart';

@riverpod
class TripsNotifier extends _$TripsNotifier {
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  final int _limit = 10;
  final List<Trips> _trips = [];

  @override
  Future<List<Trips>> build(String passengerId) {
    return _fetchTrips(passengerId);
  }

  Future<List<Trips>> _fetchTrips(String passengerId) async {
    if (!_hasMoreData) return _trips;
    final firestore = FirebaseFirestore.instance;
    Query query = firestore
        .collection('Trips')
        .where('passenger.passenger_id', isEqualTo: passengerId)
        .orderBy('createdTime', descending: true)
        .limit(_limit);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    try {
      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        _hasMoreData = false;
        return _trips;
      }

      final newTrips = snapshot.docs
          .map((doc) => Trips.fromDocument(doc))
          .toList();

      if (newTrips.isEmpty) {
        _hasMoreData = false;
      } else {
        _lastDocument = snapshot.docs.last;
        _trips.addAll(newTrips);
      }

      return _trips;
    } catch (e) {
      _hasMoreData = false;
      rethrow;
    }
  }

  Future<void> loadMore(String passengerId) async {
    if (!_hasMoreData) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTrips(passengerId));
  }

  bool get hasMoreData => _hasMoreData;
}