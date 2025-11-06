import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/models/trip_models.dart';

class CombinedTripsNotifier extends StateNotifier<AsyncValue<List<BaseTrip>>> {
  final String userID;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<BaseTrip> _allTrips = [];
  DocumentSnapshot? _lastPakyawDoc;
  DocumentSnapshot? _lastCarpoolDoc;
  bool _hasMorePakyaw = true;
  bool _hasMoreCarpool = true;
  final int _limit = 10;
  StreamSubscription? _pakyawSubscription;
  StreamSubscription? _carpoolSubscription;

  CombinedTripsNotifier(this.userID) : super(const AsyncValue.loading()) {
    _listenToTrips();
  }

  void _listenToTrips() {
    state = const AsyncValue.loading();
    _pakyawSubscription?.cancel();
    _pakyawSubscription = _firestore
        .collectionGroup('Trips')
        .where('passenger.passenger_id', isEqualTo: userID)
        .orderBy('createdTime', descending: true)
        .limit(_limit)
        .snapshots()
        .listen((pakyawSnapshot) {
      final pakyawTrips =
          pakyawSnapshot.docs.map((doc) => PakyawTrip.fromFirestore(doc)).toList();
      if (pakyawSnapshot.docs.isNotEmpty) {
        _lastPakyawDoc = pakyawSnapshot.docs.last;
      }
      _hasMorePakyaw = pakyawSnapshot.docs.length == _limit;
      _updateTrips(pakyawTrips: pakyawTrips);
    }, onError: (e, stack) {
      state = AsyncValue.error(e, stack);
    });

    _carpoolSubscription?.cancel();
    _carpoolSubscription = _firestore
        .collection('completed_trips')
        .orderBy('startedAt', descending: true)
        .limit(_limit * 3)
        .snapshots()
        .listen((carpoolSnapshot) {
      final carpoolTrips = carpoolSnapshot.docs
          .map((doc) => CarpoolTrip.fromFirestore(doc))
          .where((trip) => trip.passengers.any((p) => p.userId == userID))
          .take(_limit)
          .toList();
      if (carpoolSnapshot.docs.isNotEmpty) {
        _lastCarpoolDoc = carpoolSnapshot.docs.last;
      }
      _hasMoreCarpool = carpoolSnapshot.docs.length == _limit;
      _updateTrips(carpoolTrips: carpoolTrips);
    }, onError: (e, stack) {
      state = AsyncValue.error(e, stack);
    });
  }

  void _updateTrips(
      {List<PakyawTrip>? pakyawTrips, List<CarpoolTrip>? carpoolTrips}) {
    final currentPakyaw =
        pakyawTrips ?? _allTrips.whereType<PakyawTrip>().toList();
    final currentCarpool =
        carpoolTrips ?? _allTrips.whereType<CarpoolTrip>().toList();

    _allTrips = [...currentPakyaw, ...currentCarpool];
    _allTrips.sort((a, b) => b.createdTime.compareTo(a.createdTime));
    state = AsyncValue.data(_allTrips);
  }

  Future<void> loadMore() async {
    if (!_hasMorePakyaw && !_hasMoreCarpool) return;

    try {
      List<BaseTrip> newTrips = [];

      // Load more Pakyaw trips if available
      if (_hasMorePakyaw && _lastPakyawDoc != null) {
        final pakyawSnapshot = await _firestore
            .collection('Trips')
            .doc(userID)
            .collection('trips')
            .orderBy('createdTime', descending: true)
            .startAfterDocument(_lastPakyawDoc!)
            .limit(_limit)
            .get();

        final pakyawTrips = pakyawSnapshot.docs
            .map((doc) => PakyawTrip.fromFirestore(doc))
            .toList();

        newTrips.addAll(pakyawTrips);

        if (pakyawSnapshot.docs.isNotEmpty) {
          _lastPakyawDoc = pakyawSnapshot.docs.last;
        }
        _hasMorePakyaw = pakyawSnapshot.docs.length == _limit;
      }

      // Load more Carpool trips if available
      if (_hasMoreCarpool && _lastCarpoolDoc != null) {
        final carpoolSnapshot = await _firestore
            .collection('completed_trips')
            .orderBy('startedAt', descending: true)
            .startAfterDocument(_lastCarpoolDoc!)
            .limit(_limit * 3) // Fetch 3x more since we'll filter
            .get();

        final carpoolTrips = carpoolSnapshot.docs
            .map((doc) => CarpoolTrip.fromFirestore(doc))
            .where((trip) => trip.passengers.any((p) => p.userId == userID))
            .take(_limit)
            .toList();

        newTrips.addAll(carpoolTrips);

        if (carpoolSnapshot.docs.isNotEmpty) {
          _lastCarpoolDoc = carpoolSnapshot.docs.last;
        }
        _hasMoreCarpool = carpoolSnapshot.docs.length == _limit;
      }

      // Add and sort new trips by createdTime
      _allTrips.addAll(newTrips);
      _allTrips.sort((a, b) => b.createdTime.compareTo(a.createdTime));

      state = AsyncValue.data(_allTrips);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    _allTrips = [];
    _lastPakyawDoc = null;
    _lastCarpoolDoc = null;
    _hasMorePakyaw = true;
    _hasMoreCarpool = true;
    _listenToTrips();
  }

  @override
  void dispose() {
    _pakyawSubscription?.cancel();
    _carpoolSubscription?.cancel();
    super.dispose();
  }
}

final combinedTripsProvider = StateNotifierProvider.family<
    CombinedTripsNotifier,
    AsyncValue<List<BaseTrip>>,
    String>((ref, userID) {
  final notifier = CombinedTripsNotifier(userID);
  ref.onDispose(() {
    notifier.dispose();
  });
  return notifier;
});