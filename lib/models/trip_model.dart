import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

import '../assistants/request_assistant.dart';
import '../shared/global_var.dart';

class Trip {
  String? pickup;
  GeoFirePoint? pickupLoc;
  String? dropOff;
  GeoFirePoint? dropOffLoc;
  List<LatLng>? route;
  List<LatLng>? changeRoute;
  String? vehicleType;
  String? vehicleTypeImage;
  int? baseRate;
  double? ratePerKm;
  Map<String, dynamic>? paymentMethod;
  Map<String, dynamic>? promos;
  Map<String, dynamic>? discount;
  double? fare;
  Map<String, dynamic>? driver;
  Map<String, dynamic>? rider;
  Map<String, dynamic>? vehicle;
  double? distance;
  String? duration;
  double? rating;
  String? status;
  String? travelMode;
  double? vatTax;
  double? ccTax;
  String? notes;
  double? appCharge;

  Trip({
    this.pickup,
    this.pickupLoc,
    this.dropOff,
    this.dropOffLoc,
    this.route,
    this.changeRoute,
    this.vehicleType,
    this.vehicleTypeImage,
    this.baseRate,
    this.ratePerKm,
    this.paymentMethod,
    this.promos,
    this.discount,
    this.fare,
    this.driver,
    this.rider,
    this.vehicle,
    this.distance,
    this.duration,
    this.rating,
    this.status,
    this.travelMode,
    this.vatTax,
    this.ccTax,
    this.notes,
    this.appCharge,
  });

  Trip copyWith({
    String? pickup,
    GeoFirePoint? pickupLoc,
    String? dropOff,
    GeoFirePoint? dropOffLoc,
    List<LatLng>? route,
    List<LatLng>? changeRoute,
    String? vehicleType,
    String? vehicleTypeImage,
    int? baseRate,
    double? ratePerKm,
    Map<String, dynamic>? paymentMethod,
    Map<String, dynamic>? promos,
    Map<String, dynamic>? discount,
    double? fare,
    Map<String, dynamic>? driver,
    Map<String, dynamic>? rider,
    Map<String, dynamic>? vehicle,
    double? distance,
    String? duration,
    double? rating,
    String? status,
    String? travelMode,
    double? vatTax,
    double? ccTax,
    String? notes,
    double? appCharge,
  }) {
    return Trip(
      pickup: pickup ?? this.pickup,
      pickupLoc: pickupLoc ?? this.pickupLoc,
      dropOff: dropOff ?? this.dropOff,
      dropOffLoc: dropOffLoc ?? this.dropOffLoc,
      route: route ?? this.route,
      changeRoute: changeRoute ?? this.changeRoute,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleTypeImage: vehicleTypeImage ?? this.vehicleTypeImage,
      baseRate: baseRate ?? this.baseRate,
      ratePerKm: ratePerKm ?? this.ratePerKm,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      promos: promos ?? this.promos,
      discount: discount ?? this.discount,
      fare: fare ?? this.fare,
      driver: driver ?? this.driver,
      rider: rider ?? this.rider,
      vehicle: vehicle ?? this.vehicle,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      rating: rating ?? this.rating,
      status: status ?? this.status,
      travelMode: travelMode ?? this.travelMode,
      vatTax: vatTax ?? this.vatTax,
      ccTax: ccTax ?? this.ccTax,
      notes: notes ?? this.notes,
      appCharge: appCharge ?? this.appCharge,
    );
  }
  @override
  String toString(){
    return '''
      Trip Details:
      - Pickuploc: $pickupLoc
      - Pickup: $pickup
      - Dropoffloc: $dropOffLoc
      - Dropoff: $dropOff
      - Route: $route
      - Vehicle Type: $vehicleType
      - Vehicle Type Image: $vehicleTypeImage
      - Base Rate: $baseRate
      - Rate Per Km: $ratePerKm 
      - Payment Method: $paymentMethod
    ''';
  }

  String toString2(){
    return '''
      - Promos: $promos
      - Discount: $discount
      - Fare: $fare
      - Driver: $driver
      - Rider: $rider
      - Vehicle: $vehicle
      - Distance: $distance
      - Duration: $duration
      - Rating: $rating
      - Status: $status
      - vatTax: $vatTax
      - ccTax: $ccTax
      - notes: $notes
      - appCharge: $appCharge
    ''';
  }

  Future<String?> saveToFireStore() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    try {
      Map<String, dynamic> driver = {
        'driver_id': '',
        'driver_name': '',
        'rating': '',
        'driver_profile': '',
        'driver_location': '',
        'isVat': false,
      };

      Map<String, dynamic> vehicle = {
        'plate_num': '',
        'vehicle_image': '',
        'model': '',
        'make': '',
        'percent_taken': 0.0
      };

      List<GeoPoint> routeGeoPoints = route != null
          ? route!.map((latLng) => GeoPoint(latLng.latitude, latLng.longitude)).toList()
          : [];

      DocumentReference docRef = await _firestore.collection('Trips').add({
        'vehicle': vehicle,
        'driver': driver,
        'passenger': rider,
        'pickupAddress': pickup,
        'pickUpLoc': pickupLoc?.data,
        'dropOffAddress': dropOff,
        'dropOffLoc': dropOffLoc?.data,
        'changedPickupAddress': '',
        'changedPickUpLoc': null,
        'changedDropOffAddress': '',
        'changedDropOffLoc': null,
        'route': routeGeoPoints,
        'changed_route': null,
        'paymentMethod': paymentMethod,
        'fare': fare,
        'vehicleType': vehicleType,
        'duration': duration,
        'distance': distance,
        'promo': promos,
        'discount': discount,
        'rating': 5.0,
        'status': 'pending',
        'vatTax': vatTax,
        'ccTax': ccTax,
        'notes': notes,
        'appCharge': appCharge,
        'createdTime': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    }catch(e){
      print(e.toString());
      return null;
    }
  }

  Future<void> findAndNotifyDriver(String tripId, GeoFirePoint location, String type) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    var driverRequest = await _firestore.collection('Trips').doc(tripId).get();
    LatLng origin = LatLng(location.latitude, location.longitude);
    print(type);
    Stream<List<DocumentSnapshot<Map<String, dynamic>>>> driversWithinRadius = GeoCollectionReference(_firestore.collection('Driver')).subscribeWithin(
      center: location,
      radiusInKm: 10,
      field: 'location',
      geopointFrom: (data) =>
      (data['location'] as Map<String, dynamic>)['geopoint'] as GeoPoint,
      queryBuilder: (query) => query
          .where('onlineStatus', isEqualTo: 'online')
          .where('selectedVehicle.vehicle_type', isEqualTo: type),
    );
    late StreamSubscription<List<DocumentSnapshot<Map<String, dynamic>>>> subscribe;
    subscribe = driversWithinRadius.listen((drivers){
      print('loops');
      print('Id in first func: $tripId');
      if(driverRequest['status'] == 'accepted' || driverRequest['status'] == 'cancelled'
      || driverRequest['status'] == 'completed' || driverRequest['status'] == 'ongoing'){
        print('canceled');
        subscribe.cancel();
      }else{
        print('notify');
        notifyDrivers(drivers, origin, tripId);
      }
    });



  }

  Future<bool> checkIfDriverRejected(String driverId, String tripId) async {
    final firestore = FirebaseFirestore.instance;
    var list = await firestore
        .collection('driverNotifications')
        .where('driver_id', isEqualTo: driverId)
        .where('tripId', isEqualTo: tripId)
        .where('status', isEqualTo: 'rejected')
        .get();
    if(list.docs.isNotEmpty){
      return true;
    }else{
      return false;
    }
  }

  notifyDrivers(List<DocumentSnapshot<Map<String, dynamic>>> driversWithinRadius,
      LatLng origin, String TripId) async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    var driverRequest = await _firestore.collection('Trips').doc(TripId).get();
    print('tripId: $TripId');
    print('docExist: ${driverRequest.exists}');
    print('status: ${driverRequest['status']}');

    List<Map<String, dynamic>> driversWithDistances = [];

    if(driverRequest['status'] == 'accepted' || driverRequest['status'] == 'cancelled'
        || driverRequest['status'] == 'completed' || driverRequest['status'] == 'ongoing'){
      print('stop');
      driversWithDistances.clear();
      print(driverRequest);
    }else{
      print('for loop');
    for (var driverSnapshots in driversWithinRadius) {
      print('length: ${driversWithinRadius.length}');
      print('Yabooooyy');
      var driverGeoPoint = (driverSnapshots['location'] as Map<String,
          dynamic>)['geopoint'] as GeoPoint;
      var driverLocation = LatLng(
          driverGeoPoint.latitude, driverGeoPoint.longitude);
      print(origin);
      print(driverLocation);
      var distance = await getRouteInfo(origin, driverLocation);
      print('BlowwEYYY');
      print(driverSnapshots['selectedVehicle']['vehicle_type']);
      driversWithDistances.add({
        'driver_id': driverSnapshots.id,
        'distance_details': distance,
      });
    }
    driversWithDistances.sort((a, b) =>
        (a['distance_details']['distance'] as double).compareTo(
            b['distance_details']['distance'] as double));

    for (var driverData in driversWithDistances) {
      var driver = driverData['driver_id'] as String;
      var distanceDetails = driverData['distance_details'] as Map<
          String,
          dynamic>?;
      print('looping');

      if (driverRequest['status'] == 'accepted' || driverRequest['status'] == 'cancelled' || driverRequest['status'] == 'completed'
          || driverRequest['status'] == 'ongoing') {
        print('it is accepted');
        driversWithDistances.clear();
        break;
      }

      /*
      TODO: Add an if statement to check driverNotifications col if a driver has rejected by using
      TODO: the driver_id and TripID as conditions and checking the status field if it is 'rejected'.
       */
      bool result = await checkIfDriverRejected(driver, TripId);
      if(result){
        print('accessed a rejected doc');
        continue;
      }

      var doc = await _firestore.collection('driverNotifications').add({
        'driver_id': driver,
        'tripId': TripId,
        'passenger': rider,
        'pickUpAddress': pickup,
        'dropOffAddress': dropOff,
        'distance_details': distanceDetails,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('trip Request Id: ${doc.id}');

      await Future.delayed(Duration(seconds: 5));

      if (driverRequest['status'] == 'accepted' || driverRequest['status'] == 'cancelled'
          || driverRequest['status'] == 'completed' || driverRequest['status'] == 'ongoing') {
        print('it is accepted');
        print(driversWithDistances);
        driversWithDistances.clear();
        break; // Stop notifying more drivers if the ride has been accepted
      }
    }
  }
  }

  Future<Map<String, dynamic>> getRouteInfo(LatLng origin, LatLng destination) async {
    const String url = 'https://routes.googleapis.com/directions/v2:computeRoutes';
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': googleMapKey,
      'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline',
    };
    Map<String, dynamic> body = {
      'origin': {
        'location': {
          'latLng': {
            'latitude': origin.latitude,
            'longitude': origin.longitude
          }
        }
      },
      'destination': {
        'location': {
          'latLng': {
            'latitude': destination.latitude,
            'longitude': destination.longitude
          }
        }
      },
      'travelMode': 'DRIVE',
      'routingPreference': 'TRAFFIC_AWARE',
      'computeAlternativeRoutes': false,
      'routeModifiers': {'avoidTolls': false, 'avoidHighways': false, 'avoidFerries': true},
      'languageCode': 'en-US',
      'units': 'METRIC'
    };

    var response = await RequestAssistant.postRequest(url, headers, body);

    if(response is Map<String, dynamic> && response.containsKey('routes')){
      final route = response['routes'][0];

      double distanceKm = route['distanceMeters'] / 1000.0;
      String duration = route['duration'];
      List<GeoPoint> routePoints = decodePolyline(route['polyline']['encodedPolyline']);
      Map<String, dynamic> routeToPassengerDetails = {
        'distance': distanceKm,
        'duration': duration,
        'route': routePoints
      };
      return routeToPassengerDetails;
    }else{
      throw Exception('Failed to get route information: $response');
    }

  }
  List<GeoPoint> decodePolyline(String encoded) {
    List<PointLatLng> points = PolylinePoints().decodePolyline(encoded);
    return points.map((point) => GeoPoint(point.latitude, point.longitude)).toList();
  }

  factory Trip.empty() => Trip();

}