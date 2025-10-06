import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Trips{
  final String uid;
   final List<LatLng>? changedRoute;
   final Timestamp createdTime;
   final double distance;
   final Map<String, dynamic> driver;
   final String dropOffAddress;
   final Map<String, dynamic> dropOffLoc;
  final String changedDropOffAddress;
  final Map<String, dynamic>? changedDropOffLoc;
   final String duration;
   final double fare;
   final Map<String, dynamic> passenger;
   final Map<String, dynamic> paymentMethod;
   final Map<String, dynamic> pickupLoc;
   final String pickupAddress;
  final Map<String, dynamic>? changedPickupLoc;
  final String changedPickupAddress;
   final Map<String, dynamic> promo;
  final Map<String, dynamic> discount;
   final double rating;
   final List<LatLng> route;
   final String status;
   final Map<String, dynamic> vehicle;
   final String vehicleType;
   final double vatTax;
   final double ccTax;

  const Trips({
    required this.uid,
    required this.changedRoute,
    required this.createdTime,
    required this.distance,
    required this.driver,
    required this.dropOffAddress,
    required this.changedDropOffAddress,
    required this.dropOffLoc,
    required this.changedDropOffLoc,
    required this.duration,
    required this.fare,
    required this.passenger,
    required this.paymentMethod,
    required this.pickupLoc,
    required this.changedPickupLoc,
    required this.pickupAddress,
    required this.changedPickupAddress,
    required this.promo,
    required this.discount,
    required this.rating,
    required this.route,
    required this.status,
    required this.vehicle,
    required this.vehicleType,
    required this.vatTax,
    required this.ccTax
  });

  factory Trips.fromDocument(DocumentSnapshot doc){
    final data = doc.data() as Map<String, dynamic>;

    List<dynamic> dynamicList = data['route'];
    List<dynamic> dynamicChangedList = data['changed_route'] ?? [];

    List<LatLng> routeLatLng = dynamicList.map((item){
      if(item is GeoPoint){
        return LatLng(item.latitude, item.longitude);
      }else{
        print("Error: Expected GeoPoint but got ${item.runtimeType}");
        return const LatLng(0, 0);
      }
    }).toList();

    List<LatLng>? changedRouteLatLng = dynamicChangedList.isNotEmpty ? dynamicChangedList.map((item){
      if(item is GeoPoint){
        return LatLng(item.latitude, item.longitude);
      }else{
        print("Error: Expected GeoPoint but got ${item.runtimeType}");
        return const LatLng(0, 0);
      }
    }).toList() : null;

    return Trips(
      uid: doc.id,
      changedRoute: changedRouteLatLng,
      changedDropOffAddress: data['changedDropOffAddress'],
      changedDropOffLoc: data['changedDropOffLoc'],
      changedPickupAddress: data['changedPickupAddress'],
      changedPickupLoc: data['changedPickupLoc'],
      createdTime: data['createdTime'],
      distance: data['distance'],
      driver: data['driver'],
      dropOffAddress: data['dropOffAddress'],
      dropOffLoc: data['dropOffLoc'],
      duration: data['duration'],
      fare: data['fare'],
      passenger: data['passenger'],
      paymentMethod: data['paymentMethod'],
      pickupLoc: data['pickUpLoc'],
      pickupAddress: data['pickupAddress'],
      promo: data['promo'],
      discount: data['discount'],
      rating: data['rating'],
      route: routeLatLng,
      status: data['status'],
      vehicle: data['vehicle'],
      vehicleType: data['vehicleType'],
      vatTax: data['vatTax'],
      ccTax: data['ccTax']
    );
  }

}