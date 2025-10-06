import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleOptionsModel{
  List<String> vehicleOptions = ['Bike', 'Sedan', 'SUV', 'Tricycle'];
  String selectedVehicle = '';

  VehicleOptionsModel({required this.selectedVehicle});


}

class Capacity{
  int capacity;
  Capacity({required this.capacity});
}

class VehicleTypes{
  final String id;
  final String type;
  final String image;
  final int wheels;
  final int capacity;
  final int baseRate;
  final double ratePerKm;
  const VehicleTypes({
    required this.type,
    required this.image,
    required this.wheels,
    required this.capacity,
    required this.id,
    required this.baseRate,
    required this.ratePerKm
  });

  factory VehicleTypes.fromDocument(DocumentSnapshot doc){
    final data = doc.data() as Map<String, dynamic>;
    return VehicleTypes(
      id: doc.id,
      type: data['type'],
      image: data['icon'],
      wheels: data['wheels'],
      capacity: (data['capacity']).toInt(),
      baseRate: (data['base_rate']).toInt(),
      ratePerKm: (data['rate_per_km']).toDouble(),
    );
  }

}