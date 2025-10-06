import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pakyaw/models/discount_model.dart';

import '../models/user.dart';

class DatabaseService{

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Future<bool> isNewUser(String uid) async {
    final userDoc = await _firestore.collection('Passengers').doc(uid).get();
    return !userDoc.exists;
  }

  Future<void> createUser(String uid, String name, String fname, String lname, String? phoneNum, String? email, String birthdate, Map<String, dynamic> toUpload) async {
     final docRef = _firestore.collection('Passengers').doc(uid);
     final subDocRef = docRef.collection('PaymentMethods').doc(uid);
     Map<String, dynamic> cancellationsToday = {
       'cancelledDate': Timestamp.now(),
       'cancelCount': 0.0,
     };
     await docRef.set({
      'profile_pic': '',
       'birthday': Timestamp.fromDate(DateFormat('yyyy-MM-dd').parse(birthdate)),
       'blocked': false,
      'name': name,
       'first_name': fname,
       'last_name': lname,
      'phone_number': phoneNum,
      'email': email,
       'saved_places': FieldValue.arrayUnion([
         {'name': 'Home', 'address': '', 'location': const GeoPoint(0,0)},
         {'name': 'Work', 'address': '', 'location': const GeoPoint(0,0)}
       ]),
       'totalRating': 5.0,
       'ratingCount': 1,
       'cancellation_charge': 0.0,
       'cancellations': cancellationsToday,
      'createdAt': FieldValue.serverTimestamp(),
    });

     await subDocRef.set({
       'currently_linked': 0,
     });

     await docRef.update(
         toUpload.map((key, value) => MapEntry(key, {
           'url': value.url,
           'fileName': value.fileName,
           'expiry': value.expiry,
           'verified': false
         }))
     );
  }

  Future<void> updateEWalletPaymentMethod(String uid, String accountNum) async {
    try{
      final docRef = _firestore.collection('Passengers').doc(uid);
      final subDocSnap = await docRef.collection('PaymentMethods').limit(1).get();

      if(subDocSnap.docs.isNotEmpty){
        DocumentSnapshot subDoc = subDocSnap.docs.first;

        await subDoc.reference.update({
          'e-wallet': true,
          'account_number': accountNum,
          'currently_linked': FieldValue.increment(1)
        });
      }else{
        await docRef.collection('PaymentMethods').add({
          'e-wallet': true,
          'account_number': accountNum,
          'currently_linked': 1,
        });
      }

    }catch(e){
      print(e.toString());
    }
  }

  Future<bool> getVatExistsAndVerified(String driverId) async {
    bool value = false;
    try{
      final docRef = _firestore.collection('Driver').doc(driverId);
      final documents = await docRef.collection('FleetOwnerDocuments').limit(1).get();

      if(documents.docs.isNotEmpty){
        final Map<String, dynamic>? doc = documents.docs.first.data();
        if(doc != null && doc.containsKey('varCertificateVerified')){
          value = doc['varCertificateVerified'];
        }else{
          value = false;
        }
      }
      return value;
    }catch (e){
      throw 'An error occurred';
    }
  }

  Future<bool> remove_Ewallet(String userId) async {
    print('ran');
    try{
      final docRef = _firestore.collection('Passengers').doc(userId);
      final doc = docRef.collection('PaymentMethods').doc(userId);
      await doc.update({
        'currently_linked': FieldValue.increment(-1),
        'e-wallet': FieldValue.delete()
      });
      return true;
    }catch(e){
      throw 'Error in adding payment e-wallet';
    }
  }

  Future<bool> cancelTrip(String tripId, String reason, String driverId, String passengerId, double cancelCharge) async {
    try{
      final colRef = _firestore.collection('UserReports');
      final passengerRef2 = await _firestore.collection('Passengers').doc(passengerId).get();
      final passengerMap = passengerRef2.data() as Map<String, dynamic>;
      _firestore.runTransaction((transaction) async {
        DocumentReference rideRef = _firestore.collection('Trips').doc(tripId);
        DocumentReference userRepRef = _firestore.collection('UserReports').doc();

        transaction.update(rideRef, {
          'status': 'cancelled',
          'fare': 0.0,
          'reason': reason
        });
        if(driverId != '') {
          DocumentReference driverRef = _firestore.collection('Driver').doc(driverId);
          DocumentReference passengerRef = _firestore.collection('Passengers').doc(passengerId);

          transaction.update(driverRef, {
            'onlineStatus': 'online'
          });
          transaction.update(passengerRef, {
            'cancellation_charge': FieldValue.increment(cancelCharge),
            'cancellations.cancelCount': FieldValue.increment(1),
          });

          QuerySnapshot notificationsSnapshot = await _firestore
              .collection('driverNotifications')
              .where('tripId', isEqualTo: tripId)
              .get();


          for (var doc in notificationsSnapshot.docs) {
            print('loop1');
            transaction.delete(doc.reference);
          }
          transaction.set(userRepRef, {
            'createdAt': Timestamp.now(),
            'message': 'Passenger-${passengerId.substring(0, 8)} has cancelled Trip-${tripId.substring(0, 8)}',
            'resolve': false,
            'severity': 3,
            'tag': 'Cancellation',
            'user_id': passengerId,
            'user_type': 'passenger'
          });
        }else{
          transaction.set(userRepRef, {
            'createdAt': Timestamp.now(),
            'message': 'Passenger-${passengerId.substring(0, 8)} has cancelled Trip-${tripId.substring(0, 8)}',
            'resolve': false,
            'severity': 1,
            'tag': 'Cancellation',
            'user_id': passengerId,
            'user_type': 'passenger'
          });
        }

      });
      int cancelCount = passengerMap['cancellations']['cancelCount'];
      if(cancelCount > 5){
        await colRef.add({
          'createdAt': Timestamp.now(),
          'message': 'Passenger-${passengerId.substring(0, 8)} has cancelled 5 consecutive trips today.',
          'resolve': false,
          'severity': 5,
          'tag': 'Cancellation',
          'user_id': passengerId,
          'user_type': 'passenger'
        });
      }
      return true;
    }catch (e){
      print('Error: $e');
      return false;
    }
  }

  Future<bool> cancelTripEmergency(String tripId, String driverId, String passengerId )async {
    try{
      final colRef = _firestore.collection('UserReports');
      final passengerRef2 = await _firestore.collection('Passengers').doc(passengerId).get();
      final passengerMap = passengerRef2.data() as Map<String, dynamic>;
      _firestore.runTransaction((transaction) async {
        DocumentReference rideRef = _firestore.collection('Trips').doc(tripId);
        DocumentReference userRepRef = _firestore.collection('UserReports').doc();

        transaction.update(rideRef, {
          'status': 'cancelled',
          'fare': 0.0,
          'reason': 'Emergency Call'
        });
        DocumentReference driverRef = _firestore.collection('Driver').doc(driverId);

        transaction.update(driverRef, {
          'onlineStatus': 'online'
        });

        QuerySnapshot notificationsSnapshot = await _firestore
            .collection('driverNotifications')
            .where('tripId', isEqualTo: tripId)
            .get();


        for (var doc in notificationsSnapshot.docs) {
          print('loop1');
          transaction.delete(doc.reference);
        }
        transaction.set(userRepRef, {
          'createdAt': Timestamp.now(),
          'message': 'Passenger-${passengerId.substring(0, 8)} has called for an emergency on Trip-${tripId.substring(0, 8)}',
          'resolve': false,
          'severity': 5,
          'tag': 'Emergency',
          'user_id': passengerId,
          'user_type': 'passenger'
        });

      });
      return true;
    }catch (e){
      print('Error: $e');
      return false;
    }
  }

  Future<bool> driverNoShow(String tripId, String reason, String driverId, String passengerId) async {
    try{
      await _firestore.runTransaction((transaction) async {
        DocumentReference rideRef = _firestore.collection('Trips').doc(tripId);
        DocumentReference userRepRef = _firestore.collection('UserReports').doc();
        final driver = await _firestore.collection('Driver').doc(driverId).get();
        final data = driver.data() as Map<String, dynamic>;
        double ratingCount = data['ratingCount'].toDouble() + 1;
        double totalRating = data['totalRating'].toDouble();
        double rating = totalRating / ratingCount;

        transaction.update(rideRef, {
          'status': 'cancelled',
          'fare': 0.0,
          'reason': reason
        });
        DocumentReference driverRef = _firestore.collection('Driver').doc(driverId);

        transaction.update(driverRef, {
          'onlineStatus': 'online',
          'ratingCount': FieldValue.increment(1),
          'rating': rating,
        });

        QuerySnapshot notificationsSnapshot = await _firestore
            .collection('driverNotifications')
            .where('tripId', isEqualTo: tripId)
            .get();


        for (var doc in notificationsSnapshot.docs) {
          print('loop1');
          transaction.delete(doc.reference);
        }
        transaction.set(userRepRef, {
          'createdAt': Timestamp.now(),
          'message': 'Driver-${driverId.substring(0, 8)} is a no show in Trip-${tripId.substring(0, 8)}',
          'resolve': false,
          'severity': 5,
          'tag': 'No Show',
          'user_id': passengerId,
          'user_type': 'passenger'
        });
        if(rating < 2){
          transaction.set(userRepRef, {
            'createdAt': Timestamp.now(),
            'message': 'Driver-${driverId.substring(0, 8)} rating is now ${rating.toStringAsFixed(1)}',
            'resolve': false,
            'severity': 5,
            'tag': 'Rating',
            'user_id': driverId,
            'user_type': 'driver'
          });
        }
      });
      return true;
    }catch (e){
      print('Error: $e');
      return false;
    }
  }

  Future<void> updateTripsCollection() async {
    final query = await _firestore.collection('Trips').get();
    for(var doc in query.docs){
      await doc.reference.update({
        'discount.peso': 0.0,
      });
    }
  }

  bool changeDropOff(String tripId, String dropOffAddress, String pickupAddress, GeoFirePoint dropOffLoc, GeoFirePoint pickUpLoc, List<LatLng>? changedRoute, double fare, double distance) {
    List<GeoPoint> routeGeoPoints = changedRoute != null
        ? changedRoute.map((latLng) => GeoPoint(latLng.latitude, latLng.longitude)).toList()
        : [];
    try{
      _firestore.runTransaction((transaction) async {
        DocumentReference rideRef = _firestore.collection('ChangeRouteRequest').doc(tripId);

        transaction.set(rideRef, {
          'changedDropOffAddress': dropOffAddress,
          'changedDropOffLoc': dropOffLoc.data,
          'changedPickupAddress': pickupAddress,
          'changedPickUpLoc': pickUpLoc.data,
          'changed_route': routeGeoPoints,
          'distance': distance,
          'fare': fare
        });


      });
      return true;
    }catch (e){
      print('Error: $e');
      return false;
    }
  }

  Future<double> getVatTax() async {
    final vatTax = await _firestore.collection('PakyawSettings').doc('Tax').get();
    return vatTax['vat_tax'].toDouble();
  }
  Future<double> getCCTax() async {
    final vatTax = await _firestore.collection('PakyawSettings').doc('Tax').get();
    return vatTax['common_carrier_tax'].toDouble();
  }
  Future<double> getCancellationTax() async {
    final vatTax = await _firestore.collection('PakyawSettings').doc('Charge').get();
    return vatTax['cancellation_charge'].toDouble();
  }
  Future<double> getBaseKm() async {
    final vatTax = await _firestore.collection('PakyawSettings').doc('Base_KM').get();
    return vatTax['base_km'].toDouble();
  }
  Future<String> getEmergencyPhone() async {
    final vatTax = await _firestore.collection('PakyawSettings').doc('EmergencyCall').get();
    return vatTax['phone_number'];
  }

  Future<bool> rateRide(String tripId, double rating,  String driverId, double charge, String passengerId) async {
    try{
      _firestore.runTransaction((transaction) async {
        DocumentReference tripRef = _firestore.collection('Trips').doc(tripId);
        DocumentReference driverRef = _firestore.collection('Driver').doc(driverId);
        DocumentReference userReports = _firestore.collection('UserReports').doc();
        DocumentReference passengerRef = _firestore.collection('Passengers').doc(passengerId);
        DocumentSnapshot driverSnapshot = await transaction.get(driverRef);
        double currentTotalRating = driverSnapshot['totalRating'];
        int currentRatingCount = driverSnapshot['ratingCount'];

        transaction.update(tripRef, {
          'rating': rating,
        });

        transaction.update(driverRef, {
          'onlineStatus': 'online',
          'totalRating': FieldValue.increment(rating),
          'ratingCount':FieldValue.increment(1)
        });
        transaction.update(passengerRef, {
          'cancellation_charge': FieldValue.increment(-charge)
        });

        double newTotalRating = currentTotalRating + rating;
        int newRatingCount = currentRatingCount + 1;
        double changedRating = newTotalRating / newRatingCount;

        transaction.update(driverRef, {
          'rating': changedRating
        });
        if(changedRating < 2){
          transaction.set(userReports, {
            'createdAt': Timestamp.now(),
            'message': 'Driver-${driverId.substring(0, 8)} rating is now $changedRating',
            'resolve': false,
            'severity': 5,
            'tag': 'Rating',
            'user_id': driverId,
            'user_type': 'driver'
          });
        }

      });
      return true;
    }catch(e){
      print(e.toString());
      return false;
    }
  }

  Future<void> addPassengerProfilePic(String uid, String profilePicUrl) async {
    try{
      final docRef = await _firestore.collection('Passengers').doc(uid).get();

      await docRef.reference.update({
        'profile_pic': profilePicUrl,
      });

    }catch(e){
      print(e.toString());
    }
  }

  Future<void> updatePassengerName(String uid, String name) async {
    try{
      final docRef = await _firestore.collection('Passengers').doc(uid).get();

      await docRef.reference.update({
        'name': name,
      });

    }catch(e){
      print(e.toString());
    }
  }

  Future<void> updateSavedHomePlace(String uid, String address, GeoPoint location, String placeId) async {
    try{
      final docRef = await _firestore.collection('Passengers').doc(uid).get();

      List<dynamic> savePlaces = docRef.get('saved_places');
      int index = savePlaces.indexWhere((places) => places['name'] == 'Home');
      if(index != -1){

        savePlaces[index] = {
          'name': 'Home',
          'address': address,
          'location': GeoPoint(location.latitude, location.longitude),
          'place_id': placeId
        };

        await docRef.reference.update({
          'saved_places': savePlaces
        });
      }else{
        print('Place not found');
      }

    }catch(e){
      print(e.toString());
    }
  }

  Future<void> removeSavedHomePlace(String uid) async {
    try{
      final docRef = await _firestore.collection('Passengers').doc(uid).get();

      List<dynamic> savePlaces = docRef.get('saved_places');
      int index = savePlaces.indexWhere((places) => places['name'] == 'Home');
      if(index != -1){
        savePlaces[index] = {
          'name': 'Home',
          'address': '',
          'location': const GeoPoint(0, 0),
          'place_id': ''
        };

        await docRef.reference.update({
          'saved_places': savePlaces
        });
      }else{
        print('Place not found');
      }

    }catch(e){
      print(e.toString());
    }
  }

  Future<void> updateSavedWorkPlace(String uid, String address, GeoPoint location, String placeId) async {
    print('Locations::');
    print(location.latitude);
    print(location.longitude);
    try{
      final docRef = await _firestore.collection('Passengers').doc(uid).get();

      List<dynamic> savePlaces = docRef.get('saved_places');
      int index = savePlaces.indexWhere((places) => places['name'] == 'Work');
      if(index != -1){
        savePlaces[index] = {
          'name': 'Work',
          'address': address,
          'location': GeoPoint(location.latitude, location.longitude),
          'place_id': placeId
        };

        await docRef.reference.update({
          'saved_places': savePlaces
        });
      }else{
        print('Place not found');
      }

    }catch(e){
      print(e.toString());
    }
  }

  Future<void> updateSavedPlace(String uid, String name, String newName, String address, GeoPoint location, String placeId) async {
    try{
      final docRef = await _firestore.collection('Passengers').doc(uid).get();

      List<dynamic> savePlaces = docRef.get('saved_places');
      int index = savePlaces.indexWhere((places) => places['name'] == name);
      if(index != -1){
        savePlaces[index] = {
          'name': newName,
          'address': address,
          'location': GeoPoint(location.latitude, location.longitude),
          'place_id': placeId
        };

        await docRef.reference.update({
          'saved_places': savePlaces
        });
      }else{
        print('Place not found');
      }

    }catch(e){
      print(e.toString());
    }
  }


  Future<void> addNewSavedPlace(String uid, String name, String address, GeoPoint location, String placeId) async {

    Map<String, dynamic> newLocation = {
      'name': name,
      'address': address,
      'location': GeoPoint(location.latitude, location.longitude),
      'place_id': placeId
    };

    try{
      final docRef = await _firestore.collection('Passengers').doc(uid).get();

      await docRef.reference.update({
        'saved_places': FieldValue.arrayUnion([newLocation]),
      });

    }catch(e){
      print(e.toString());
    }
  }

  Future<void> removeNewSavedPlace(String uid, String name, String address, GeoPoint location, String placeId) async {
    Map<String, dynamic> newLocation = {
      'name': name,
      'address': address,
      'location': GeoPoint(location.latitude, location.longitude),
      'place_id': placeId
    };

    try{
      final docRef = await _firestore.collection('Passengers').doc(uid).get();

      await docRef.reference.update({
        'saved_places': FieldValue.arrayRemove([newLocation]),
      });

    }catch(e){
      print(e.toString());
    }
  }

  Future<void> removeSavedWorkPlace(String uid) async {
    try{
      final docRef = await _firestore.collection('Passengers').doc(uid).get();

      List<dynamic> savePlaces = docRef.get('saved_places');
      int index = savePlaces.indexWhere((places) => places['name'] == 'Work');
      if(index != -1){
        savePlaces[index] = {
          'name': 'Work',
          'address': '',
          'location': const GeoPoint(0, 0),
          'place_id': ''
        };

        await docRef.reference.update({
          'saved_places': savePlaces
        });
      }else{
        print('Place not found');
      }

    }catch(e){
      print(e.toString());
    }
  }

  Future<void> updatePassengerPhoneNum(String uid, String phoneNum) async {
    try{
      final docRef = await _firestore.collection('Passengers').doc(uid).get();

      await docRef.reference.update({
        'phone_number': phoneNum,
      });

    }catch(e){
      print(e.toString());
    }
  }

  Future<void> updateEmail(String uid, String email) async {
    try{
      final docRef = await _firestore.collection('Passengers').doc(uid).get();

      await docRef.reference.update({
        'email': email,
      });

    }catch(e){
      print(e.toString());
    }
  }

  Stream<PaymentMethod?> getPaymentMethods(String uid) {
    final docRef = _firestore.collection('Passengers').doc(uid).collection('PaymentMethods').limit(1);
    return docRef.snapshots().map((querySnapshot){
      if(querySnapshot.docs.isNotEmpty){
        return PaymentMethod.fromDocument(querySnapshot.docs.first);
      }else{
        print("isEmpty, getPaymentMethods");
        return null;
      }
    });
  }
  Future<void> changeTrips() async {
    final collection = await _firestore.collection('Trips').get();
    for(var x in collection.docs){
      await x.reference.update({
        'appCharge': 0.2,
      });
    }
  }
  Future<Users?> getUser(String uid) async {
    final doc = await _firestore.collection('Passengers').doc(uid).get();
    return doc.exists ? Users.fromDocument(doc) : null;
  }

  Stream<Users?> getUserStream(String uid) {
    return _firestore.collection('Passengers').doc(uid).snapshots().map((doc) {
      print(doc.exists);
      return doc.exists ? Users.fromDocument(doc) : null;
    });
  }
  Future<int> getCurrentlyLinked(String userId) async {
    try{
      final docRef = _firestore.collection('Passengers').doc(userId);
      DocumentSnapshot doc = await docRef.collection('PaymentMethods').doc(userId).get();
      Map<String, dynamic>? document = doc.data() as Map<String, dynamic>;
      return document['currently_linked'];
    }catch(e){
      throw 'Error getting linked payment methods.';
    }
  }

  Future<Map<String, dynamic>> get_Ewallet(String userId) async {
    Map<String, dynamic> eWallet = {};
    try{
      final docRef = _firestore.collection('Passengers').doc(userId);
      DocumentSnapshot doc = await docRef.collection('PaymentMethods').doc(userId).get();
      Map<String, dynamic>? document = doc.data() as Map<String, dynamic>;
      if(document.containsKey('e-wallet')){
        eWallet = document['e-wallet'];
        print('Not empty');
      }else{
        print('Is empty');
        eWallet = {};
      }
      return eWallet;
    }catch(e){
      throw 'Error getting e-wallet';
    }
  }
  Future<bool> add_Ewallet(String userId, String accountNumber) async {
    try{
      final docRef = _firestore.collection('Passengers').doc(userId);
      final doc = docRef.collection('PaymentMethods').doc(userId);
      Map<String, dynamic> eWallet = {
        'method': 'E-Wallet',
        'account_number': accountNumber,
      };
      await doc.update({
        'currently_linked': FieldValue.increment(1),
        'e-wallet': eWallet
      });
      return true;
    }catch(e){
      throw '$e';
    }
  }

  Future<void> resetCancellations(String userId) async {
    final doc = await _firestore.collection('Passengers').doc(userId).get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    DateTime today = DateTime.now();
    Timestamp cancelDate = data['cancellations']['cancelledDate'];
    DateTime fsDate = cancelDate.toDate();
    bool isSameDate = fsDate.year == today.year && fsDate.month == today.month && fsDate.day == today.day;
    Map<String, dynamic> cancel = {
      'cancelledDate': Timestamp.now(),
      'cancelCount': 0,
    };
    if(!isSameDate){
      await doc.reference.update({
        'cancellations': cancel
      });
    }
  }
  Future<double> getPassengerCharge(String userId) async{
    final doc = await _firestore.collection('Passengers').doc(userId).get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    double charge = data['cancellation_charge'].toDouble();
    return charge;
  }
  Future<bool> getPassengerBlockStatus(String userId) async{
    final doc = await _firestore.collection('Passengers').doc(userId).get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool blocked = data['blocked'];
    return blocked;
  }
   void updateSubmittedID(String userId){
    List<String> ids = ['Student', 'PWD', 'Senior Citizen'];
    try{
      _firestore.runTransaction((transaction) async {
        DocumentReference docRef = _firestore.collection('Passengers').doc(userId);
        DocumentSnapshot snapshot = await docRef.get();
        var document = snapshot.data() as Map<String, dynamic>;
        for(int i = 0; i < ids.length; i++){
          if(document[ids[i]] != null){
            DateTime expiry = document[ids[i]]['expiry'].toDate();
            if(expiry.isBefore(DateTime.now()) || expiry.isAtSameMomentAs(DateTime.now())){
              await docRef.update({
                '${ids[i]}.verified': false
              });
            }
          }
        }
      });
    }catch(e){
      throw '$e';
    }

  }
  Future<bool> checkVerified(String userId) async {
    List<String> ids = ['Student', 'PWD', 'Senior Citizen'];
    try{
      DocumentReference docRef = _firestore.collection('Passengers').doc(userId);
      DocumentSnapshot snapshot = await docRef.get();
      var document = snapshot.data() as Map<String, dynamic>;
      for(int i = 0; i < ids.length; i++){
        if(document[ids[i]] != null){
          if(!document[ids[i]]['verified']){
            return false;
          }
        }
      }
      return true;
    }catch(e){
      print('$e');
      return false;
    }

  }
  Future<bool> submitIDs(String uid, Map<String, dynamic> toUpload) async {
    try{
      final docRef = _firestore.collection('Passengers').doc(uid);
      await docRef.update(
          toUpload.map((key, value) => MapEntry(key, {
            'url': value.url,
            'fileName': value.fileName,
            'expiry': value.expiry,
            'verified': false
          }))
      );
      return true;
    }catch(e){
      print('$e');
      return false;
    }
  }
  Future<Users> getCurrentUser(String userId) async {
    try{
      DocumentSnapshot document = await _firestore.collection('Passengers').doc(userId).get();
      return Users.fromDocument(document);
    }catch(e){
      throw '$e';
    }
  }
  Future<DiscountModel> getStudentDiscount() async {
    try{
      final doc = await _firestore.collection('Discounts')
          .where('discount_name', whereIn: ['Student', 'Students', 'student', 'students'])
          .where('status', isNotEqualTo: 'Inactive')
          .get();
      return DiscountModel.fromDocument(doc.docs.first);
    }catch(e){
      throw '$e';
    }
  }
  Future<DiscountModel> getPWDDiscount() async {
    try{
      final doc = await _firestore.collection('Discounts')
          .where('discount_name', whereIn: ['PWD', 'pwd', 'disabled', 'Disabled', 'Person with Disabilities', 'Person with Disability'])
          .where('status', isNotEqualTo: 'Inactive')
          .get();
      return DiscountModel.fromDocument(doc.docs.first);
    }catch(e){
      throw '$e';
    }
  }
  Future<DiscountModel> getSeniorDiscount() async {
    try{
      final doc = await _firestore.collection('Discounts')
          .where('discount_name', whereIn: ['Senior Citizen', 'senior citizen', 'Senior Citizens', 'senior citizen'])
          .where('status', isNotEqualTo: 'Inactive')
          .get();
      return DiscountModel.fromDocument(doc.docs.first);
    }catch(e){
      throw '$e';
    }
  }
  Future<bool> reportIncident(String tripId, Map<String, dynamic> driverId, Map<String, dynamic> passengerId, String message) async {
    try{
      final col = _firestore.collection('UserReports');
      col.add({
        'createdAt': Timestamp.now(),
        'message': 'Trip-${tripId.substring(0, 8)}: $message',
        'driver': driverId,
        'passenger': passengerId,
        'resolve': false,
        'severity': 4,
        'tag': 'Incident Report',
        'user_id': passengerId['passenger_id'],
        'user_type': 'passenger'
      });
      // col.add({
      //   'createdAt': Timestamp.now(),
      //   'message': message,
      //   'resolve': false,
      //   'driver': driverId,
      //   'passenger': passengerId,
      //   'trip_id': tripId
      // });
      return true;
    }catch(e){
      print(e);
      return false;
    }
  }
  Future<double> getAppCharge() async {
    final vatTax = await _firestore.collection('PakyawSettings').doc('Charge').get();
    return vatTax['app_charge'];
  }

}