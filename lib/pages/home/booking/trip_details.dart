import 'dart:async';
import 'dart:math';

import 'package:another_telephony/telephony.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:pakyaw/models/current_trip.dart';
import 'package:pakyaw/pages/home/booking/change_destination_page.dart';
import 'package:pakyaw/pages/home/booking/driver_found.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/providers/current_trip_provider.dart';
import 'package:pakyaw/services/database.dart';
import 'package:pakyaw/services/sms_service.dart';
import 'package:pakyaw/shared/error.dart';
import 'package:pakyaw/shared/loading.dart';
import 'package:pakyaw/shared/searching.dart';
import 'package:pakyaw/shared/size_config.dart';

import '../../../providers/trip_provider.dart';
import '../../../shared/global_var.dart';

class TripDetails extends ConsumerStatefulWidget{
  final String tripId;
  const TripDetails({super.key, required this.tripId});

  @override
  ConsumerState<TripDetails> createState() => _TripDetailsState();
}

class _TripDetailsState extends ConsumerState<TripDetails> with WidgetsBindingObserver{
  final Telephony telephony = Telephony.instance;
  bool flag1 = false;
  bool flag2 = false;
  bool flag3 = false;
  bool flag4 = false;
  bool flag5 = false;
  LatLng? pickUp;
  LatLng? dest;
  Timer? timer;
  int remainingSeconds = 0;
  bool enabledNoShow = false;
  double? cancelCharge;
  bool isVatVerified = false;
  GeoPoint? geo;
  LatLng? driverPos;
  double _currentHeight = SizeConfig.blockSizeVertical * 25; // Initial height
  final double _minHeight = SizeConfig.blockSizeVertical * 25;
  final double _maxHeight = SizeConfig.blockSizeVertical * 76;
  double rating = 1;
  int changes = 1;
  final smsService = SMSService();
  List<String> reasons = ['', 'Driver too far.', 'Driver No Show', 'I want to change my booking details.',
  "I don't need a ride anymore.", "Driver not suitable.", "Other"];

  Map<PolylineId, Polyline> polyLines = {};

  Completer<GoogleMapController> controller = Completer<GoogleMapController>();

  void setVatValue(bool value){
    setState(() {
      isVatVerified = value;
    });
  }

  void fitPolylineToMap(List<LatLng> points) async {
    if (points.isEmpty) return;

    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (LatLng point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    int half = points.length ~/ 2;
    int max = points.length - 1;
    setState(() {
      pickUp = LatLng(points[0].latitude, points[0].longitude);
      dest = LatLng(points[max].latitude, points[max].longitude);
    });
    GoogleMapController mapController = await controller.future;
    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  void getPolylineFromPoints(List<LatLng> coordinates) async {
    PolylineId polylineId = const PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: polylineId,
        color: Colors.black,
        points: coordinates,
        width: 4
    );
    setState(() {
      polyLines[polylineId] = polyline;
    });
    print('This is first polylines ${polyLines[polylineId]!.points}');
    print('This is first coordinated $coordinates');
    fitPolylineToMap(coordinates);
  }
  void getPolylineFromPoints2(List<LatLng> coordinates) async {
    PolylineId polylineId = const PolylineId("ChangedRoute");
    Polyline polyline = Polyline(
        polylineId: polylineId,
        color: Colors.black,
        points: coordinates,
        width: 4
    );
    setState(() {
      polyLines.clear();
      polyLines[polylineId] = polyline;
    });
    print('This is second polylines ${polyLines[polylineId]!.points}');
    print('This is second coordinated $coordinates');
    fitPolylineToMap(coordinates);
  }

  Widget buildRating() => RatingBar.builder(
    minRating: 1,
    itemSize: 35,
    itemPadding: const EdgeInsets.symmetric(horizontal: 5.0),
    itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber,),
    onRatingUpdate: (rating) {
      this.rating = rating;
      print(rating);
    },

  );
  
  void showRating(context2, String tripId, String driverId, double charge, String passengerId) {
    DatabaseService database = DatabaseService();
    print('Does this print?');
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Column(
        children: [
          Image(
            image: const AssetImage('assets/rate.png'),
            height: SizeConfig.blockSizeVertical * 10,
            width: SizeConfig.blockSizeHorizontal * 30,
          ),
          const Text('Rate the Trip'),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Please leave a star rating.', style: TextStyle(fontSize: 20.0),),
          const SizedBox(height: 32,),
          buildRating()
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            bool result = await database.rateRide(tripId, rating, driverId, charge, passengerId);
            if(result){
              Navigator.pop(context);
              Navigator.popUntil(context2, ModalRoute.withName('/Home'));
            }else{
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Error occurred, please try again"))
              );
              Navigator.pop(context);
            }
          },
          child: const Text('OK', style: TextStyle(fontSize: 20.0),),

        )
      ],
    ));
  }

  CameraPosition currentPosition = const CameraPosition(
    target: LatLng(11.00639, 124.6075),
    zoom: 19,
  );

  Future<void> showBeforeCancel(BuildContext context1) {
    SizeConfig().init(context1);
    return showDialog(
      context: context1,
      builder: (context) => AlertDialog(
        content: SizedBox(
          height: SizeConfig.blockSizeVertical * 25,
          child: Column(
            children: [
              Image(
                image: const AssetImage('assets/fee.png'),
                height: SizeConfig.blockSizeVertical * 10,
                width: SizeConfig.blockSizeHorizontal * 30,
              ),
              Center(
                child: Icon(
                  Icons.warning_outlined,
                  color: Colors.yellow,
                  size: SizeConfig.safeBlockHorizontal * 8,
                ),
              ),
              Text(
                "You will be charged $cancelCharge pesos on your future trips if you cancel this trip.",
                style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 5,
                    color: Colors.black,
                    fontWeight: FontWeight.w500
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showCancelDialog(context2, String id, String driverId, String passengerId){
    String currentSelected = reasons[0];
    TextEditingController other = TextEditingController();
    bool toggleView = false;
    DatabaseService database = DatabaseService();
    print(currentSelected);
    showDialog(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState){
          return Stack(
            children: [
              Positioned(
                bottom: SizeConfig.blockSizeVertical * 34,
                left: SizeConfig.blockSizeHorizontal * 1.5,
                right: SizeConfig.blockSizeHorizontal * 1.5,
                child: SizedBox(
                  height: SizeConfig.blockSizeVertical * 55,
                  child: SingleChildScrollView(
                    child: AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: reasons.length - 1,
                            itemBuilder: (context, index){
                              final reason = reasons[index + 1];
                              final isDisabled = !enabledNoShow && reason == 'Driver No Show';
                              if(!enabledNoShow && reason != 'Driver No Show'){
                                return RadioListTile(
                                  contentPadding: const EdgeInsets.only(left: 0.0),
                                  title: Text(
                                      reasons[index + 1],
                                      style: TextStyle(
                                          fontSize: SizeConfig.safeBlockHorizontal * 4,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500
                                      )
                                  ),
                                  value: reasons[index + 1],
                                  groupValue: currentSelected,
                                  onChanged: (value){
                                    print(currentSelected);
                                    if(value == 'Other'){
                                      setState((){
                                        toggleView = true;
                                        currentSelected = value.toString();
                                      });
                                    }else{
                                      setState(() {
                                        toggleView = false;
                                        currentSelected = value.toString();
                                      });
                                    }
                                    print(currentSelected);
                                  },
                                );
                              }else if(enabledNoShow && reason == 'Driver No Show'){
                                return RadioListTile(
                                  contentPadding: const EdgeInsets.only(left: 0.0),
                                  title: Text(
                                      reasons[index + 1],
                                      style: TextStyle(
                                          fontSize: SizeConfig.safeBlockHorizontal * 4,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500
                                      )
                                  ),
                                  value: reasons[index + 1],
                                  groupValue: currentSelected,
                                  onChanged: (value){
                                    print(currentSelected);
                                    if(value == 'Other'){
                                      setState((){
                                        toggleView = true;
                                        currentSelected = value.toString();
                                      });
                                    }else{
                                      setState(() {
                                        toggleView = false;
                                        currentSelected = value.toString();
                                      });
                                    }
                                    print(currentSelected);
                                  },
                                );
                              }else{
                                return Container();
                              }

                            },
                          ),
                          toggleView ? TextField(
                            controller: other,
                            minLines: 1,
                            maxLines: 2,
                            style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4, fontWeight: FontWeight.w500),
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                          ) : Container(),
                        ]
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20.0,
                left: 22.0,
                right: 22.0,
                height: 60.0,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      disabledBackgroundColor: Colors.grey.shade700
                  ),
                  onPressed: currentSelected != '' ? () async {
                    bool result = false;
                    if(currentSelected == 'Driver No Show'){
                      print('No show');
                      result = await database.driverNoShow(id, currentSelected, driverId, passengerId);
                    }else if(currentSelected != 'Other' && currentSelected != 'Driver No Show'){
                      print('Not No show');
                      result = await database.cancelTrip(id, currentSelected, driverId, passengerId, cancelCharge!);
                    }else{
                      print('Other');
                      result = await database.cancelTrip(id, 'Other: ${other.text}', driverId, passengerId, cancelCharge!);
                    }
                    if(result){
                      Navigator.pop(context);
                      Navigator.of(context2).pop();
                    }else{
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Error occurred, please try again"))
                      );
                      Navigator.pop(context);
                    }
                  } : null,
                  child: Text('Confirm', style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 7, fontWeight: FontWeight.bold, color: Colors.white),),

                ),
              ),
            ],
          );
        },
      ),
      barrierDismissible: false
    );
  }

  String formatTimestamp(Timestamp timestamp){
    DateTime date = timestamp.toDate();
    final DateFormat dateFormat = DateFormat('MMM d, yyyy - hh:mm a');
    return dateFormat.format(date);
  }

  String getDistance(double distance){
    if(distance > 1){
      return '$distance km';
    }else{
      return '${distance * 1000} m';
    }
  }

  Future<void> sendEmailV2(CurrentTrip trip, String userEmail) async {
    final smtpServer = gmail(email, password);
    double CCT = trip.fare * trip.ccTax;
    double vTax = trip.fare * trip.vatTax;
    double taxedFare = trip.fare + CCT + vTax;
    double promo = taxedFare * trip.promo['discount'];
    double discounted = taxedFare - promo;
    double discount = 0.0;
    if(trip.discount['peso'] != 0){
      discount = trip.discount['peso'];
    }else if (trip.discount['discount'] != 0){
      discount = discounted * trip.discount['discount'];
    }
    double discounted2 = discounted - discount;

    final message = Message()
      ..from = Address(email, 'Pakyaw')
      ..recipients.add(userEmail)
      ..subject = 'Receipt'
      ..html =
      '''
      <!DOCTYPE html>
<html>
<head>
<style>
  body {
    font-family: Arial, sans-serif;
    line-height: 1.6;
    color: #333;
    max-width: 600px;
    margin: 0 auto;
  }
  .receipt {
    border: 1px solid #ddd;
    padding: 20px;
    border-radius: 8px;
  }
  .header {
    text-align: center;
    margin-bottom: 20px;
  }
  .logo {
    width: 100px;
    height: 100px;
    background: #f0f0f0;
    margin: 0 auto;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
  }
  .trip-id {
    color: #666;
    font-size: 14px;
  }
  .detail-row {
    display: flex;
    justify-content: space-between;
    margin-bottom: 10px;
    padding: 5px 0;
    border-bottom: 1px solid #eee;
  }
  .label {
    font-weight: bold;
    color: #555;
  }
  .value {
    text-align: right;
  }
  .address {
    margin-bottom: 15px;
  }
  .total {
    font-size: 18px;
    font-weight: bold;
    margin-top: 20px;
    padding-top: 10px;
    border-top: 2px solid #333;
  }
  .changed {
    color: #e74c3c;
    font-size: 14px;
  }
</style>
</head>
<body>
  <div class="receipt">
    <div class="header">
      <h1>Trip Receipt</h1>
      <p class="trip-id">Trip ID: ${trip.id}</p>
    </div>

    <div class="detail-row">
      <span class="label">Time:</span>
      <span class="value">${formatTimestamp(trip.createdTime)}</span>
    </div>

    <div class="detail-row">
      <span class="label">Distance:</span>
      <span class="value">${getDistance(trip.distance)}</span>
    </div>

    <div class="detail-row">
      <span class="label">Fare:</span>
      <span class="value">₱${trip.fare.toStringAsFixed(2)}</span>
    </div>

    <div class="detail-row">
      <span class="label">Payment Method:</span>
      <span class="value">${trip.paymentMethod['payment_method']}(${trip.paymentMethod['account_num']})</span>
    </div>

    <div class="detail-row">
      <span class="label">Promos Applied:</span>
      <span class="value">${trip.promo['promo_name']} (-₱${promo.toStringAsFixed(2)})</span>
    </div>
    <div class="detail-row">
      <span class="label">Promos Applied:</span>
      <span class="value">${trip.discount['discount_name']} (-₱${discount.toStringAsFixed(2)})</span>
    </div>
    
    <div class="detail-row">
      <span class="label">Common Carrier's Tax (${trip.ccTax * 100}%):</span>
      <span class="value">₱${CCT.toStringAsFixed(2)}</span>
    </div>
    <div class="detail-row">
      <span class="label">Vat Tax (${trip.vatTax * 100}%):</span>
      <span class="value">₱${vTax.toStringAsFixed(2)}</span>
    </div>

    <div class="address">
      <h3>Pickup Location</h3>
      <p>${trip.changedPickupAddress}</p>
      <p class="changed">Changed from: ${trip.pickupAddress}</p>
    </div>

    <div class="address">
      <h3>Drop-off Location</h3>
      <p>${trip.changedDropOffAddress}</p>
      <p class="changed">Changed from: ${trip.dropOffAddress}</p>
    </div>

    <div class="detail-row total">
      <span class="label">Total Amount:</span>
      <span class="value">\$${discounted2.toStringAsFixed(2)}</span>
    </div>
  </div>
</body>
</html>
      ''';
    try{
      final sendReport = await send(message, smtpServer);
      print('Message sent: $sendReport');
    } on MailerException catch (e){
      print('Message not sent. Error: $e');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
  }
  Future<void> sendEmailV1(CurrentTrip trip, String userEmail) async {
    final smtpServer = gmail(email, password);
    double CCT = trip.fare * trip.ccTax;
    double vTax = trip.fare * trip.vatTax;
    double taxedFare = trip.fare + CCT + vTax;
    double promo = taxedFare * trip.promo['discount'];
    double discounted = taxedFare - promo;
    double discount = 0.0;
    if(trip.discount['peso'] != 0){
      discount = trip.discount['peso'];
    }else if (trip.discount['discount'] != 0){
      discount = discounted * trip.discount['discount'];
    }
    double discounted2 = discounted - discount;
    final message = Message()
      ..from = Address(email, 'Pakyaw')
      ..recipients.add(userEmail)
      ..subject = 'Receipt'
      ..html =
      '''
      <!DOCTYPE html>
<html>
<head>
<style>
  body {
    font-family: Arial, sans-serif;
    line-height: 1.6;
    color: #333;
    max-width: 600px;
    margin: 0 auto;
  }
  .receipt {
    border: 1px solid #ddd;
    padding: 20px;
    border-radius: 8px;
  }
  .header {
    text-align: center;
    margin-bottom: 20px;
  }
  .logo {
    width: 100px;
    height: 100px;
    background: #f0f0f0;
    margin: 0 auto;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
  }
  .trip-id {
    color: #666;
    font-size: 14px;
  }
  .detail-row {
    display: flex;
    justify-content: space-between;
    margin-bottom: 10px;
    padding: 5px 0;
    border-bottom: 1px solid #eee;
  }
  .label {
    font-weight: bold;
    color: #555;
  }
  .value {
    text-align: right;
  }
  .address {
    margin-bottom: 15px;
  }
  .total {
    font-size: 18px;
    font-weight: bold;
    margin-top: 20px;
    padding-top: 10px;
    border-top: 2px solid #333;
  }
  .changed {
    color: #e74c3c;
    font-size: 14px;
  }
</style>
</head>
<body>
  <div class="receipt">
    <div class="header">
      <h1>Trip Receipt</h1>
      <p class="trip-id">Trip ID: ${trip.id}</p>
    </div>

    <div class="detail-row">
      <span class="label">Time:</span>
      <span class="value">${formatTimestamp(trip.createdTime)}</span>
    </div>

    <div class="detail-row">
      <span class="label">Distance:</span>
      <span class="value">${getDistance(trip.distance)}</span>
    </div>

    <div class="detail-row">
      <span class="label">Fare:</span>
      <span class="value">₱${trip.fare.toStringAsFixed(2)}</span>
    </div>

    <div class="detail-row">
      <span class="label">Payment Method:</span>
      <span class="value">${trip.paymentMethod['payment_method']}(${trip.paymentMethod['account_num']})</span>
    </div>

    <div class="detail-row">
      <span class="label">Promos Applied:</span>
      <span class="value">${trip.promo['promo_name']} (-₱${promo.toStringAsFixed(2)})</span>
    </div>
    <div class="detail-row">
      <span class="label">Discount Applied:</span>
      <span class="value">${trip.discount['discount_name']} (-₱${discount.toStringAsFixed(2)})</span>
    </div>
    
    <div class="detail-row">
      <span class="label">Common Carrier's Tax (${trip.ccTax * 100}%):</span>
      <span class="value">${CCT.toStringAsFixed(2)}</span>
    </div>
    <div class="detail-row">
      <span class="label">Vat Tax (${trip.vatTax * 100}%):</span>
      <span class="value">${vTax.toStringAsFixed(2)}</span>
    </div>

    <div class="address">
      <h3>Pickup Location</h3>
      <p>${trip.pickupAddress}</p>
    </div>

    <div class="address">
      <h3>Drop-off Location</h3>
      <p>${trip.dropOffAddress}</p>
    </div>

    <div class="detail-row total">
      <span class="label">Total Amount:</span>
      <span class="value">\$${discounted2.toStringAsFixed(2)}</span>
    </div>
  </div>
</body>
</html>
      ''';
    try{
      final sendReport = await send(message, smtpServer);
      print('Message sent: $sendReport');
    } on MailerException catch (e){
      print('Message not sent. Error: $e');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
  }
  Future<void> sendText(CurrentTrip trip, String userNumber) async {
    final receiptText = generateReceiptSMS(
      tripId: trip.id,
      time: trip.createdTime,
      distance: trip.distance > 1 ? trip.distance : (trip.distance * 1000) ,
      ccTax: trip.ccTax,
      vatTax: trip.vatTax,
      fare: trip.fare,
      paymentMethod: trip.paymentMethod,
      promoCode: trip.promo['promo_name'],
      promoAmount: trip.promo['discount'],
      discountCode: trip.discount['discount_name'],
      discountAmount: trip.discount['discount'],
      discountPeso: trip.discount['peso'],
      pickupAddress: trip.pickupAddress,
      dropOffAddress: trip.dropOffAddress,
      changedPickupAddress: trip.changedPickupAddress,
      changedDropOffAddress: trip.changedDropOffAddress
    );
    smsService.sendLongSMS(
        userNumber,
        receiptText,
        context
    );
  }

  String generateReceiptSMS({
    required String tripId,
    required Timestamp time,
    required double distance,
    required ccTax,
    required vatTax,
    required double fare,
    required Map<String, dynamic> paymentMethod,
    required String promoCode,
    required double promoAmount,
    required String discountCode,
    required double discountAmount,
    required double discountPeso,
    required String pickupAddress,
    required String dropOffAddress,
    required String changedPickupAddress,
    required String changedDropOffAddress,
  }) {
    final formatter = DateFormat('MMM d, h:mm a');
    final formattedTime = formatter.format(time.toDate());
    double CCT = fare * ccTax;
    double vTax = fare * vatTax;
    double taxedFare = fare + CCT + vTax;
    double discounted = taxedFare - (taxedFare * promoAmount);
    double minusDiscountAmount = 0;
    if(discountPeso != 0){
      minusDiscountAmount = discountPeso;
    }else if(discountAmount != 0){
      minusDiscountAmount = discounted * discountAmount;
    }
    double discounted2 = discounted - minusDiscountAmount;
    final promoText = promoCode != '' && promoAmount != 0.0
        ? '\n🏷️ Promo: $promoCode (-₱${(promoAmount * 100).toStringAsFixed(2)})'
        : '';
    final discountText = discountCode != '' && discountAmount != 0.0
        ? '\n🏷️ Discount: $discountCode (-₱${(discountAmount * 100).toStringAsFixed(2)})'
        : '';

    final pickupChangeText = changedPickupAddress != ''
        ? '\n(Changed from: $changedPickupAddress)'
        : '';

    final dropoffChangeText = changedDropOffAddress != ''
        ? '\n(Changed from: $changedDropOffAddress)'
        : '';

    return '''
🚗 Ride Receipt
ID: $tripId

⏱️ Time: $formattedTime
📏 Distance: ${distance.toStringAsFixed(1)} km
💰 Fare: ₱${fare.toStringAsFixed(2)}
💰 Common Carrier's Tax (${ccTax * 100}%): ₱${CCT.toStringAsFixed(2)}
💰 Vat Tax (${vatTax * 100}%): ₱${vTax.toStringAsFixed(2)}
💳 Paid via: ${paymentMethod['payment_method']}(${paymentMethod['account_num']})$promoText$discountText

📍 Pickup:
$pickupAddress$pickupChangeText

🏁 Drop-off:
$dropOffAddress$dropoffChangeText

Total: ₱${discounted2.toStringAsFixed(2)}

Thanks for riding with us!
''';
  }

  BitmapDescriptor destination_flag = BitmapDescriptor.defaultMarker;
  BitmapDescriptor driver_flag = BitmapDescriptor.defaultMarker;

  void customMarker(){
    BitmapDescriptor.asset(ImageConfiguration(), "assets/destination_flag.png").then((val){
      setState(() {
        destination_flag = val;
      });
    });
    BitmapDescriptor.asset(ImageConfiguration(), "assets/driver_flag.png").then((val){
      setState(() {
        driver_flag = val;
      });
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    customMarker();
    getCancelCharge();
    WidgetsBinding.instance.addObserver(this);
    final trip = ref.read(tripProvider);
    getPolylineFromPoints(trip.route!);
    print(widget.tripId);
    trip.findAndNotifyDriver(widget.tripId, trip.pickupLoc!, trip.vehicleType!);
  }

  double getActualFare(double fare, double discount, double discount2, double vatTax, double ccTax, double peso){
    double taxed_fare = fare + (fare * vatTax) + (fare * ccTax);
    double promo_disscounted_fare = taxed_fare - (taxed_fare * discount);
    double discounted_fare = 0.0;
    if(peso != 0){
      discounted_fare = promo_disscounted_fare - peso;
    }else if(discount2 != 0){
      discounted_fare = promo_disscounted_fare - (promo_disscounted_fare * discount2);
    }
    return discounted_fare;
  }
  int getDuration(String time){
    int seconds = int.parse(time.replaceAll('s', ''));
    if(seconds > 60){
      int minute = (seconds/60).round();
      return minute;
    }else{
      return seconds;
    }

  }



  @override
  void dispose() {
    // TODO: implement dispose
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState
    final currentTrip = ref.read(currentTripProvider(widget.tripId)).value;
    if(state == AppLifecycleState.detached && currentTrip!.status == 'accepted'){
      DatabaseService databaseService = DatabaseService();
      databaseService.cancelTrip(widget.tripId, 'N/A', currentTrip.driver['driver_id'], currentTrip.passenger['passenger_id'], cancelCharge!);
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> getCancelCharge() async {
    DatabaseService database = DatabaseService();
    final value = await database.getCancellationTax();
    cancelCharge = value.toDouble();
  }

  void createTime(){
    timer = Timer.periodic(const Duration(seconds: 1), (timer){
      setState(() {
        if(remainingSeconds > 0){
          print('are you the culprit?');
          remainingSeconds--;
        }else{
          enabledNoShow = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final currentTrip = ref.watch(currentTripProvider(widget.tripId));
    print('How about here?');
    final trip = ref.watch(tripProvider);
    final userAuth = ref.read(authStateProvider).value;
    return currentTrip.when(
      data: (data){
        print('or are you?');
        double actualFare = getActualFare(data.fare, data.promo['discount'], data.discount['discount'], data.vatTax, data.ccTax, data.discount['peso']);
        int duration = getDuration(data.duration);
        if(data.driver['driver_id'] != ''  && !flag1){
          flag1 = true;
          remainingSeconds = int.parse(data.driver['duration'].replaceAll('s', ''));
          createTime();
        }
        if(data.status == 'ongoing'  && !flag2){
          flag2 = true;
          timer?.cancel();
        }
        if(data.status == 'cancelled'  && !flag4){
          flag4 = true;
          Navigator.popUntil(context, ModalRoute.withName('/Home'));
        }
        if (data.status == 'completed' && !flag3) {
          flag3 = true;
          if(userAuth!.email != null && userAuth.email!.isNotEmpty){
            if(data.changedRoute!.isEmpty){
              sendEmailV1(data, userAuth.email!);
            }else{
              sendEmailV2(data, userAuth.email!);
            }
          }
          if(userAuth.phoneNumber != null && userAuth.phoneNumber!.isNotEmpty){
            print('text sent to ' + userAuth.phoneNumber!);
            sendText(data, userAuth.phoneNumber!);
          }
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            print('How many times');
            DatabaseService database = DatabaseService();
            double charge = await database.getPassengerCharge(data.passenger['passenger_id']);
            showRating(context, data.id, data.driver['driver_id'], charge, data.passenger['passenger_id']);
          });
        }
        if(data.changedRoute!.isNotEmpty && !flag5){
          flag5 = true;
          print('it now has been trued');
          getPolylineFromPoints2(data.changedRoute!);
        }
        if(data.driver['driver_id'] != ''){
          geo = data.driver['driver_location']['geopoint'];
          driverPos = LatLng(geo!.latitude, geo!.longitude);
        }
        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.grey[350],
          body: SafeArea(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: currentPosition,
                  polylines: Set<Polyline>.of(polyLines.values),
                  myLocationEnabled: true,
                  onMapCreated: (GoogleMapController mapController){
                    controller.complete(mapController);
                  },
                  markers: {
                    Marker(
                        markerId: const MarkerId('pickUpLocation'),
                        position: pickUp!,
                        icon: BitmapDescriptor.defaultMarker
                    ),
                    Marker(
                        markerId: const MarkerId('dropOffLocation'),
                        position: dest!,
                        icon: destination_flag
                    ),
                    data.driver['driver_id'] != '' ? Marker(
                      markerId:  const MarkerId('Driver'),
                      position: driverPos!,
                      icon: driver_flag
                    ) : const Marker(markerId: MarkerId('Driver')),
                  },
                ),
                Positioned(
                  bottom: 0.0,
                  left: 0.0,
                  right: 0.0,
                  child: GestureDetector(
                    onVerticalDragUpdate: (details){
                      setState(() {
                        _currentHeight -= details.delta.dy;
                        _currentHeight = _currentHeight.clamp(_minHeight, _maxHeight);
                      });
                    },
                    child: Container(
                      height: _currentHeight,
                      decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(22.0), topRight: Radius.circular(22.0))
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Container(
                                width: 50,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 10.0),
                                  child: data.driver['driver_id'] == '' ? const Searching() : DriverFound(driver: data.driver, vehicle: data.vehicle)
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5.0),
                                child: Divider(height: 20.0, thickness: 5.0,),
                              ),
                            ],
                          ),
                          //Trip details
                          Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(5.0),
                                          margin: const EdgeInsets.all(5.0),
                                          decoration: BoxDecoration(
                                              borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                                              color: Colors.grey[350]
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  SizedBox(width: SizeConfig.blockSizeHorizontal,),
                                                  Icon(Icons.trip_origin, size: SizeConfig.safeBlockHorizontal * 7,),
                                                  SizedBox(width: SizeConfig.blockSizeHorizontal,),
                                                  Expanded(
                                                    child: ListTile(
                                                      title: Text(
                                                        data.changedPickupAddress == '' ? data.pickupAddress : data.changedPickupAddress,
                                                        style: TextStyle(
                                                            fontSize: SizeConfig.safeBlockHorizontal * 4,
                                                            fontWeight: FontWeight.bold,
                                                            overflow: TextOverflow.ellipsis
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                              Divider(height: SizeConfig.blockSizeVertical,),
                                              Row(
                                                children: [
                                                  SizedBox(width: SizeConfig.blockSizeHorizontal,),
                                                  Icon(Icons.pin_drop, size: SizeConfig.safeBlockHorizontal * 7,),
                                                  SizedBox(width: SizeConfig.blockSizeHorizontal,),
                                                  Expanded(
                                                    child: ListTile(
                                                      title: Text(
                                                        data.changedDropOffAddress == '' ? data.dropOffAddress : data.changedDropOffAddress,
                                                        style: TextStyle(
                                                            fontSize: SizeConfig.safeBlockHorizontal * 4,
                                                            fontWeight: FontWeight.bold,
                                                            overflow: TextOverflow.ellipsis
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6.0,),
                                    Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                                        decoration: BoxDecoration(
                                            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                                            color: Colors.grey[350]
                                        ),
                                        child: ListTile(
                                          leading: Image.network(trip.vehicleTypeImage!, width: SizeConfig.blockSizeHorizontal * 7, height: SizeConfig.blockSizeVertical * 4,),
                                          title: Text(data.vehicleType, style: TextStyle(fontWeight: FontWeight.bold, fontSize: SizeConfig.safeBlockHorizontal * 4),),
                                          trailing: Text('₱${actualFare.toStringAsFixed(2)}', style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4, fontWeight: FontWeight.bold),),
                                        )
                                    ),
                                    const SizedBox(height: 10.0,),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        Text('Distance: ${data.distance} km', style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4, fontWeight: FontWeight.bold),),
                                        Text(int.parse(data.duration.replaceAll('s', '')) < 60 ? 'Duration: $duration sec' : 'Duration: $duration min', style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 10.0,),
                                    Center(
                                      child: TextButton(
                                        onPressed: data.changedRoute!.isEmpty ? (){
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => ChangeDropOffSelect(tripId: data.id,)));
                                        } : null,
                                        child: Text(
                                          'Change Location',
                                          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4, fontWeight: FontWeight.bold),

                                        ),

                                      ),
                                    ),
                                    SizedBox(height: SizeConfig.blockSizeVertical * 1.5,),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            margin: EdgeInsets.symmetric(horizontal: SizeConfig.blockSizeHorizontal * 3),
                                            decoration: BoxDecoration(
                                                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                                                border: Border.all(color: Colors.black)
                                            ),
                                            child: ListTile(
                                              leading: const Icon(Icons.money_outlined),
                                              title: Text(data.paymentMethod['payment_method'], style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4, fontWeight: FontWeight.bold),),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            margin: EdgeInsets.symmetric(horizontal: SizeConfig.blockSizeHorizontal * 3),
                                            decoration: BoxDecoration(
                                                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                                                border: Border.all(color: Colors.black)
                                            ),
                                            child: ListTile(
                                              leading: const Icon(Icons.discount),
                                              title: Text(data.promo['discount'] != 0.0 ? '${(data.promo['discount'] * 100)}%' : 'N/A', style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4, fontWeight: FontWeight.bold),),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10.0,),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            // showRating(context);
                                            if(data.driver['driver_id'] != ''){
                                              await showBeforeCancel(context);
                                            }
                                            showCancelDialog(context, data.id, data.driver['driver_id'], data.passenger['passenger_id']);
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(22.0),
                                                border: Border.all(color: Colors.black),
                                                boxShadow: const [
                                                  BoxShadow(
                                                      color: Colors.black,
                                                      blurRadius: 6.0,
                                                      spreadRadius: 0.5,
                                                      offset: Offset(
                                                          0.7,
                                                          0.7
                                                      )
                                                  )
                                                ]
                                            ),
                                            child: const CircleAvatar(
                                              backgroundColor: Colors.white,
                                              child: Icon(Icons.close, color: Colors.black,),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 15.0,),
                                        data.status == 'ongoing' ? GestureDetector(
                                          onTap: () async {
                                            DatabaseService database = DatabaseService();
                                            // showRating(context)
                                            String phoneNum = await database.getEmergencyPhone();
                                            await database.cancelTripEmergency(data.id, data.driver['driver_id'], data.passenger['passenger_id']);
                                            await telephony.dialPhoneNumber('+63$phoneNum');
                                            Navigator.popUntil(context, ModalRoute.withName('/Home'));
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(22.0),
                                                border: Border.all(color: Colors.black),
                                                boxShadow: const [
                                                  BoxShadow(
                                                      color: Colors.black,
                                                      blurRadius: 6.0,
                                                      spreadRadius: 0.5,
                                                      offset: Offset(
                                                          0.7,
                                                          0.7
                                                      )
                                                  )
                                                ]
                                            ),
                                            child: const CircleAvatar(
                                              backgroundColor: Colors.white,
                                              child: Icon(Icons.call, color: Colors.black,),
                                            ),
                                          ),
                                        ) : Container(),
                                      ],
                                    ),
                                    const SizedBox(height: 10.0,),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                ),
              ],
            ),
          ),
        );
      },
      error: (e, stack) {
        print('$e');
        print('$stack');
        return ErrorCatch(error: e.toString());
      },
      loading: () => const Loading(),
    );
  }
}
