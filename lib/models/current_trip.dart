import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CurrentTrip {
  String id;
  Map<String, dynamic> driver;
  Map<String, dynamic> vehicle;
  Map<String, dynamic> passenger;
  Map<String, dynamic> promo;
  Map<String, dynamic> discount;
  Map<String, dynamic> pickupLoc;
  Map<String, dynamic> dropOffLoc;
  String pickupAddress;
  String dropOffAddress;
  List<LatLng>? changedRoute;
  String changedDropOffAddress;
  Map<String, dynamic>? changedDropOffLoc;
  Map<String, dynamic>? changedPickupLoc;
  String changedPickupAddress;
  List<LatLng> route;
  String duration;
  double fare;
  double rating;
  String status;
  String vehicleType;
  Map<String, dynamic> paymentMethod;
  double distance;
  double vatTax;
  double ccTax;
  Timestamp createdTime;

  CurrentTrip({
    required this.id,
    required this.driver,
    required this.vehicle,
    required this.passenger,
    required this.promo,
    required this.discount,
    required this.pickupLoc,
    required this.dropOffLoc,
    required this.pickupAddress,
    required this.dropOffAddress,
    required this.route,
    required this.changedRoute,
    required this.changedPickupAddress,
    required this.changedPickupLoc,
    required this.changedDropOffAddress,
    required this.changedDropOffLoc,
    required this.duration,
    required this.fare,
    required this.rating,
    required this.vehicleType,
    required this.paymentMethod,
    required this.status,
    required this.distance,
    required this.vatTax,
    required this.ccTax,
    required this.createdTime
});

  factory CurrentTrip.fromDocument(DocumentSnapshot doc){
    final data = doc.data() as Map<String, dynamic>;

    List<LatLng> routeLatLng = data['route'] != null
        ? (data['route'] as List<dynamic>).map((latLng) {
      GeoPoint geoPoint = latLng as GeoPoint;
      return LatLng(geoPoint.latitude, geoPoint.longitude);}).toList()
        : [];

    List<LatLng> changedRouteGeoPoints = data['changed_route'] != null
        ? (data['changed_route'] as List<dynamic>).map((latLng) {
      GeoPoint geoPoint = latLng as GeoPoint;
      return LatLng(geoPoint.latitude, geoPoint.longitude);}).toList()
        : [];

    return CurrentTrip(
      id: doc.id,
      driver: data['driver'],
      vehicle: data['vehicle'],
      passenger: data['passenger'],
      promo: data['promo'],
      discount: data['discount'],
      pickupLoc: data['pickUpLoc'],
      dropOffLoc: data['dropOffLoc'],
      pickupAddress: data['pickupAddress'],
      dropOffAddress: data['dropOffAddress'],
      route: routeLatLng,
      changedRoute:  changedRouteGeoPoints,
      changedDropOffAddress: data['changedDropOffAddress'],
      changedDropOffLoc: data['changedDropOffLoc'],
      changedPickupAddress: data['changedPickupAddress'],
      changedPickupLoc: data['changedPickupLoc'],
      duration: data['duration'],
      fare: data['fare'],
      rating: data['rating'],
      vehicleType: data['vehicleType'],
      paymentMethod: data['paymentMethod'],
      status: data['status'],
      distance: data['distance'],
      vatTax: data['vatTax'],
      ccTax: data['ccTax'],
      createdTime: data['createdTime']
    );
  }

}