import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pakyaw/models/vehicle_options_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'vehicle_types_provider.g.dart';

@riverpod
Stream<List<VehicleTypes>> vehicleTypes(VehicleTypesRef ref) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('VehicleType')
      .where('status', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => VehicleTypes.fromDocument(doc)).toList();
  });
}

@riverpod
Future<Capacity> maxCapacity(MaxCapacityRef ref) async {
  final vehicleTypes = await ref.watch(vehicleTypesProvider.future);
  final maxCapacity = vehicleTypes.fold(0, (max, vehicle) => vehicle.capacity > max ? vehicle.capacity : max);
  return Capacity(capacity: maxCapacity);
}