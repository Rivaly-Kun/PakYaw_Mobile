import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Base class for all trips
abstract class BaseTrip {
  final String uid;
  final Timestamp createdTime;
  final String status;

  BaseTrip({
    required this.uid,
    required this.createdTime,
    required this.status,
  });

  // Method to determine trip type
  String get tripType;
}

// Pakyaw Trip Model
class PakyawTrip extends BaseTrip {
  final String pickupAddress;
  final String dropOffAddress; // Changed to match your code
  final GeoPoint pickUpLoc; // Changed to GeoPoint
  final GeoPoint dropOffLoc; // Changed to GeoPoint
  final List<LatLng> route; // Added route field
  final double fare;
  final double distance;
  final String duration;
  final String vehicleType;
  final double appCharge;
  final double vatTax;
  final Map<String, dynamic> discount;
  final Map<String, dynamic> driver;
  final Map<String, dynamic> vehicle;
  final Map<String, dynamic> paymentMethod;
  final double rating;

  PakyawTrip({
    required super.uid,
    required super.createdTime,
    required super.status,
    required this.pickupAddress,
    required this.dropOffAddress,
    required this.pickUpLoc,
    required this.dropOffLoc,
    required this.route,
    required this.fare,
    required this.distance,
    required this.duration,
    required this.vehicleType,
    required this.appCharge,
    required this.vatTax,
    required this.discount,
    required this.driver,
    required this.vehicle,
    required this.paymentMethod,
    required this.rating,
  });

  @override
  String get tripType => 'Pakyaw';

  factory PakyawTrip.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse route
    List<LatLng> routePoints = [];
    if (data['route'] != null) {
      List<dynamic> routeData = data['route'];
      routePoints = routeData.map((point) {
        if (point is GeoPoint) {
          return LatLng(point.latitude, point.longitude);
        }
        return LatLng(0, 0);
      }).toList();
    }

    // Extract GeoPoint from map structure
    GeoPoint pickUpGeoPoint = const GeoPoint(0, 0);
    if (data['pickUpLoc'] != null && data['pickUpLoc'] is Map) {
      var pickUpMap = data['pickUpLoc'] as Map<String, dynamic>;
      if (pickUpMap['geopoint'] != null) {
        pickUpGeoPoint = pickUpMap['geopoint'] as GeoPoint;
      }
    }

    GeoPoint dropOffGeoPoint = const GeoPoint(0, 0);
    if (data['dropOffLoc'] != null && data['dropOffLoc'] is Map) {
      var dropOffMap = data['dropOffLoc'] as Map<String, dynamic>;
      if (dropOffMap['geopoint'] != null) {
        dropOffGeoPoint = dropOffMap['geopoint'] as GeoPoint;
      }
    }

    return PakyawTrip(
      uid: doc.id,
      createdTime: data['createdTime'] ?? Timestamp.now(),
      status: data['status'] ?? 'unknown',
      pickupAddress: data['pickupAddress'] ?? 'Unknown',
      dropOffAddress: data['dropOffAddress'] ?? 'Unknown',
      pickUpLoc: pickUpGeoPoint,
      dropOffLoc: dropOffGeoPoint,
      route: routePoints,
      fare: (data['fare'] ?? 0).toDouble(),
      distance: (data['distance'] ?? 0).toDouble(),
      duration: data['duration'] ?? '0 min',
      vehicleType: data['vehicleType'] ?? 'Standard',
      appCharge: (data['appCharge'] ?? 0).toDouble(),
      vatTax: (data['vatTax'] ?? 0).toDouble(),
      discount: data['discount'] ?? {'peso': 0, 'discount_name': 'None'},
      driver: data['driver'] ?? {},
      vehicle: data['vehicle'] ?? {},
      paymentMethod: data['paymentMethod'] ?? {'payment_method': 'Cash'},
      rating: (data['rating'] ?? 0).toDouble(),
    );
  }
}

// Carpool Trip Model
class CarpoolTrip extends BaseTrip {
  final String routeName;
  final Map<String, dynamic> pickup; // Changed to Map
  final Map<String, dynamic> dropoff; // Changed to Map
  final String routeTaken; // Encoded polyline
  final double farePerPassenger;
  final double fareTotal;
  final double distanceKm;
  final int durationSeconds;
  final int passengerCount;
  final List<CarpoolPassenger> passengers;
  final String driverName;
  final String vehicleModel;
  final String plateNum;
  final String paymentMethod;
  final Timestamp startedAt;
  final Timestamp completedAt;

  CarpoolTrip({
    required super.uid,
    required super.createdTime,
    required super.status,
    required this.routeName,
    required this.pickup,
    required this.dropoff,
    required this.routeTaken,
    required this.farePerPassenger,
    required this.fareTotal,
    required this.distanceKm,
    required this.durationSeconds,
    required this.passengerCount,
    required this.passengers,
    required this.driverName,
    required this.vehicleModel,
    required this.plateNum,
    required this.paymentMethod,
    required this.startedAt,
    required this.completedAt,
  });

  @override
  String get tripType => 'Carpool';

  factory CarpoolTrip.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse passengers
    List<CarpoolPassenger> passengerList = [];
    if (data['passengers'] != null) {
      List<dynamic> passengersData = data['passengers'];
      passengerList = passengersData.map((p) => CarpoolPassenger.fromMap(p)).toList();
    }

    return CarpoolTrip(
      uid: doc.id,
      createdTime: data['startedAt'] ?? Timestamp.now(), // ✅ Changed to startedAt
      status: data['status'] ?? 'unknown',
      routeName: data['routeName'] ?? 'Carpool Route',
      pickup: data['pickup'] ?? {'name': 'Unknown', 'lat': 0.0, 'lng': 0.0},
      dropoff: data['dropoff'] ?? {'name': 'Unknown', 'lat': 0.0, 'lng': 0.0},
      routeTaken: data['routeTaken'] ?? '',
      farePerPassenger: (data['fare_per_passenger'] ?? 0).toDouble(), // ✅ underscore
      fareTotal: (data['fare_total'] ?? 0).toDouble(), // ✅ underscore
      distanceKm: (data['distance_km'] ?? 0).toDouble(), // ✅ underscore
      durationSeconds: data['duration_seconds'] ?? 0, // ✅ underscore
      passengerCount: data['passengerCount'] ?? 0,
      passengers: passengerList,
      driverName: data['driverName'] ?? 'Unknown Driver',
      vehicleModel: data['vehicleModel'] ?? 'Unknown',
      plateNum: data['plate_num'] ?? 'N/A', // ✅ underscore
      paymentMethod: data['payment_method'] ?? 'Cash', // ✅ underscore
      startedAt: data['startedAt'] ?? Timestamp.now(),
      completedAt: data['completedAt'] ?? Timestamp.now(),
    );
  }
}

// Carpool Passenger Model
class CarpoolPassenger {
  final String userId;
  final String userName;
  final String userEmail;
  final String pickupPoint;
  final String dropoffPoint;
  final double fareOwed;

  CarpoolPassenger({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.pickupPoint,
    required this.dropoffPoint,
    required this.fareOwed,
  });

  factory CarpoolPassenger.fromMap(Map<String, dynamic> map) {
    return CarpoolPassenger(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Unknown',
      userEmail: map['userEmail'] ?? '',
      pickupPoint: map['pickupPoint'] ?? 'Unknown',
      dropoffPoint: map['dropoffPoint'] ?? 'Unknown',
      fareOwed: (map['fareOwed'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'pickupPoint': pickupPoint,
      'dropoffPoint': dropoffPoint,
      'fareOwed': fareOwed,
    };
  }
}