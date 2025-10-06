import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trip_model.dart';

final tripProvider = StateNotifierProvider<TripNotifier, Trip>((ref) => TripNotifier());

class TripNotifier extends StateNotifier<Trip> {
  TripNotifier() : super(Trip.empty());

  void updateTrip(Trip Function(Trip) update) {
    state = update(state);
  }

  void saveToFirestore() {
  }
  void printTripDetails() {
    print('Current Trip Details:');
    print(state.toString());
    print(state.toString2());
  }
  void resetTrip(){
    state = Trip.empty();
  }
}