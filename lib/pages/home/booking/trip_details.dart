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

// Enhanced PAKYAW Color Palette
const Color primaryNavy = Color(0xFF0B2E6B);
const Color brightBlue = Color(0xFF1C72DD);
const Color lightBlue = Color(0xFF1B99FF);
const Color darkGray = Color(0xFF303841);
const Color lightBackground = Color(0xFFF3F3F3);
const Color successGreen = Color(0xFF10B981);
const Color warningOrange = Color(0xFFF59E0B);
const Color errorRed = Color(0xFFDC2626);

class TripDetails extends ConsumerStatefulWidget {
  final String tripId;
  const TripDetails({super.key, required this.tripId});

  @override
  ConsumerState<TripDetails> createState() => _TripDetailsState();
}

class _TripDetailsState extends ConsumerState<TripDetails>
    with WidgetsBindingObserver, TickerProviderStateMixin {
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
  double _currentHeight = 0.0;
  double _minHeight = 0.0;
  double _maxHeight = 0.0;
  double rating = 1;
  int changes = 1;
  final smsService = SMSService();

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  List<String> reasons = [
    '',
    'Driver too far.',
    'Driver No Show',
    'I want to change my booking details.',
    "I don't need a ride anymore.",
    "Driver not suitable.",
    "Other"
  ];

  Map<PolylineId, Polyline> polyLines = {};
  Completer<GoogleMapController> controller = Completer<GoogleMapController>();

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Start animations
    _slideController.forward();
    _fadeController.forward();
    _pulseController.repeat(reverse: true);

    customMarker();
    getCancelCharge();
    WidgetsBinding.instance.addObserver(this);

    // Initialize responsive dimensions after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenHeight = MediaQuery.of(context).size.height;
      setState(() {
        _minHeight = screenHeight * 0.25;
        _maxHeight = screenHeight * 0.76;
        _currentHeight = _minHeight;
      });
    });

    final trip = ref.read(tripProvider);
    getPolylineFromPoints(trip.route!);
    print(widget.tripId);
    trip.findAndNotifyDriver(widget.tripId, trip.pickupLoc!, trip.vehicleType!);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    super.dispose();
  }

  void setVatValue(bool value) {
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
      color: primaryNavy,
      points: coordinates,
      width: 4,
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
      color: brightBlue,
      points: coordinates,
      width: 4,
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
    itemSize: 40,
    itemPadding: const EdgeInsets.symmetric(horizontal: 8.0),
    itemBuilder: (context, _) => const Icon(
      Icons.star,
      color: warningOrange,
    ),
    onRatingUpdate: (rating) {
      this.rating = rating;
      print(rating);
    },
  );

  void showRating(context2, String tripId, String driverId, double charge, String passengerId) {
    DatabaseService database = DatabaseService();
    print('Does this print?');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rating illustration
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryNavy, brightBlue],
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 50,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Rate Your Trip',
                style: TextStyle(
                  fontSize: (SizeConfig.safeBlockHorizontal * 6).clamp(20.0, 28.0),
                  fontWeight: FontWeight.w600,
                  color: darkGray,
                  fontFamily: 'Montserrat',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'How was your experience?',
                style: TextStyle(
                  fontSize: (SizeConfig.safeBlockHorizontal * 4).clamp(14.0, 18.0),
                  color: Colors.grey[600],
                  fontFamily: 'Montserrat',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              buildRating(),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    bool result = await database.rateRide(
                        tripId, rating, driverId, charge, passengerId);
                    if (result) {
                      Navigator.pop(context);
                      Navigator.popUntil(context2, ModalRoute.withName('/Home'));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Error occurred, please try again"),
                          backgroundColor: errorRed,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryNavy, brightBlue],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Submit Rating',
                      style: TextStyle(
                        fontSize: (SizeConfig.safeBlockHorizontal * 4.5).clamp(16.0, 20.0),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  CameraPosition currentPosition = const CameraPosition(
    target: LatLng(11.00639, 124.6075),
    zoom: 19,
  );

  Future<void> showBeforeCancel(BuildContext context1) {
    return showDialog(
      context: context1,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: warningOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.warning_outlined,
                  color: warningOrange,
                  size: 40,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Cancellation Fee',
                style: TextStyle(
                  fontSize: (SizeConfig.safeBlockHorizontal * 5.5).clamp(18.0, 24.0),
                  fontWeight: FontWeight.w600,
                  color: darkGray,
                  fontFamily: 'Montserrat',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                "You will be charged ₱$cancelCharge on your future trips if you cancel this trip.",
                style: TextStyle(
                  fontSize: (SizeConfig.safeBlockHorizontal * 4).clamp(14.0, 18.0),
                  color: Colors.grey[600],
                  fontFamily: 'Montserrat',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryNavy, brightBlue],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'I Understand',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showCancelDialog(context2, String id, String driverId, String passengerId) {
    String currentSelected = reasons[0];
    TextEditingController other = TextEditingController();
    bool toggleView = false;
    DatabaseService database = DatabaseService();
    print(currentSelected);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryNavy, brightBlue],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cancel,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Cancel Trip',
                            style: TextStyle(
                              fontSize: (SizeConfig.safeBlockHorizontal * 5).clamp(18.0, 22.0),
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Please select a reason for cancellation:',
                            style: TextStyle(
                              fontSize: (SizeConfig.safeBlockHorizontal * 4).clamp(14.0, 18.0),
                              fontWeight: FontWeight.w500,
                              color: darkGray,
                              fontFamily: 'Montserrat',
                            ),
                          ),

                          const SizedBox(height: 16),

                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: reasons.length - 1,
                            itemBuilder: (context, index) {
                              final reason = reasons[index + 1];
                              final isDisabled = !enabledNoShow && reason == 'Driver No Show';

                              if (!enabledNoShow && reason != 'Driver No Show') {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: currentSelected == reason
                                          ? brightBlue
                                          : Colors.grey[300]!,
                                      width: currentSelected == reason ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: RadioListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    title: Text(
                                      reasons[index + 1],
                                      style: TextStyle(
                                        fontSize: (SizeConfig.safeBlockHorizontal * 3.5).clamp(12.0, 16.0),
                                        color: darkGray,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                    value: reasons[index + 1],
                                    groupValue: currentSelected,
                                    activeColor: brightBlue,
                                    onChanged: (value) {
                                      print(currentSelected);
                                      if (value == 'Other') {
                                        setState(() {
                                          toggleView = true;
                                          currentSelected = value.toString();
                                        });
                                      } else {
                                        setState(() {
                                          toggleView = false;
                                          currentSelected = value.toString();
                                        });
                                      }
                                      print(currentSelected);
                                    },
                                  ),
                                );
                              } else if (enabledNoShow && reason == 'Driver No Show') {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: currentSelected == reason
                                          ? brightBlue
                                          : Colors.grey[300]!,
                                      width: currentSelected == reason ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: RadioListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    title: Text(
                                      reasons[index + 1],
                                      style: TextStyle(
                                        fontSize: (SizeConfig.safeBlockHorizontal * 3.5).clamp(12.0, 16.0),
                                        color: darkGray,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                    value: reasons[index + 1],
                                    groupValue: currentSelected,
                                    activeColor: brightBlue,
                                    onChanged: (value) {
                                      print(currentSelected);
                                      if (value == 'Other') {
                                        setState(() {
                                          toggleView = true;
                                          currentSelected = value.toString();
                                        });
                                      } else {
                                        setState(() {
                                          toggleView = false;
                                          currentSelected = value.toString();
                                        });
                                      }
                                      print(currentSelected);
                                    },
                                  ),
                                );
                              } else {
                                return Container();
                              }
                            },
                          ),

                          if (toggleView) ...[
                            const SizedBox(height: 16),
                            TextField(
                              controller: other,
                              minLines: 1,
                              maxLines: 3,
                              style: TextStyle(
                                fontSize: (SizeConfig.safeBlockHorizontal * 3.5).clamp(12.0, 16.0),
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Montserrat',
                              ),
                              decoration: InputDecoration(
                                hintText: 'Please specify...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: brightBlue, width: 2),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Actions
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentSelected != ''
                                  ? Colors.transparent
                                  : Colors.grey[300],
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: currentSelected != ''
                                ? () async {
                              bool result = false;
                              if (currentSelected == 'Driver No Show') {
                                print('No show');
                                result = await database.driverNoShow(
                                    id, currentSelected, driverId, passengerId);
                              } else if (currentSelected != 'Other' &&
                                  currentSelected != 'Driver No Show') {
                                print('Not No show');
                                result = await database.cancelTrip(id,
                                    currentSelected, driverId, passengerId, cancelCharge!);
                              } else {
                                print('Other');
                                result = await database.cancelTrip(id,
                                    'Other: ${other.text}', driverId, passengerId, cancelCharge!);
                              }
                              if (result) {
                                Navigator.pop(context);
                                Navigator.of(context2).pop();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text("Error occurred, please try again"),
                                    backgroundColor: errorRed,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            }
                                : null,
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: currentSelected != ''
                                    ? LinearGradient(colors: [primaryNavy, brightBlue])
                                    : null,
                                color: currentSelected == '' ? Colors.grey[300] : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Confirm Cancellation',
                                style: TextStyle(
                                  fontSize: (SizeConfig.safeBlockHorizontal * 4).clamp(14.0, 18.0),
                                  fontWeight: FontWeight.w600,
                                  color: currentSelected != '' ? Colors.white : Colors.grey[500],
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    final DateFormat dateFormat = DateFormat('MMM d, yyyy - hh:mm a');
    return dateFormat.format(date);
  }

  String getDistance(double distance) {
    if (distance > 1) {
      return '$distance km';
    } else {
      return '${distance * 1000} m';
    }
  }

  // Keep all the email and SMS functionality unchanged
  Future<void> sendEmailV2(CurrentTrip trip, String userEmail) async {
    final smtpServer = gmail(email, password);
    double CCT = trip.fare * trip.ccTax;
    double vTax = trip.fare * trip.vatTax;
    double taxedFare = trip.fare + CCT + vTax;
    double promo = taxedFare * trip.promo['discount'];
    double discounted = taxedFare - promo;
    double discount = 0.0;
    if (trip.discount['peso'] != 0) {
      discount = trip.discount['peso'];
    } else if (trip.discount['discount'] != 0) {
      discount = discounted * trip.discount['discount'];
    }
    double discounted2 = discounted - discount;

    final message = Message()
      ..from = Address(email, 'Pakyaw')
      ..recipients.add(userEmail)
      ..subject = 'Receipt'
      ..html = '''
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
    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: $sendReport');
    } on MailerException catch (e) {
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
    if (trip.discount['peso'] != 0) {
      discount = trip.discount['peso'];
    } else if (trip.discount['discount'] != 0) {
      discount = discounted * trip.discount['discount'];
    }
    double discounted2 = discounted - discount;
    final message = Message()
      ..from = Address(email, 'Pakyaw')
      ..recipients.add(userEmail)
      ..subject = 'Receipt'
      ..html = '''
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
    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: $sendReport');
    } on MailerException catch (e) {
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
      distance: trip.distance > 1 ? trip.distance : (trip.distance * 1000),
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
      changedDropOffAddress: trip.changedDropOffAddress,
    );
    smsService.sendLongSMS(userNumber, receiptText, context);
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
    if (discountPeso != 0) {
      minusDiscountAmount = discountPeso;
    } else if (discountAmount != 0) {
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

  void customMarker() {
    // Set destination marker to red (matches PAKYAW error/destination red)
    setState(() {
      destination_flag = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    });

    // Set driver marker to blue (matches PAKYAW primary blue)
    setState(() {
      driver_flag = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    });
  }

  double getActualFare(double fare, double discount, double discount2,
      double vatTax, double ccTax, double peso) {
    double taxed_fare = fare + (fare * vatTax) + (fare * ccTax);
    double promo_disscounted_fare = taxed_fare - (taxed_fare * discount);
    double discounted_fare = 0.0;
    if (peso != 0) {
      discounted_fare = promo_disscounted_fare - peso;
    } else if (discount2 != 0) {
      discounted_fare =
          promo_disscounted_fare - (promo_disscounted_fare * discount2);
    }
    return discounted_fare;
  }

  int getDuration(String time) {
    int seconds = int.parse(time.replaceAll('s', ''));
    if (seconds > 60) {
      int minute = (seconds / 60).round();
      return minute;
    } else {
      return seconds;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final currentTrip = ref.read(currentTripProvider(widget.tripId)).value;
    if (state == AppLifecycleState.detached &&
        currentTrip!.status == 'accepted') {
      DatabaseService databaseService = DatabaseService();
      databaseService.cancelTrip(widget.tripId, 'N/A',
          currentTrip.driver['driver_id'], currentTrip.passenger['passenger_id'], cancelCharge!);
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> getCancelCharge() async {
    DatabaseService database = DatabaseService();
    final value = await database.getCancellationTax();
    cancelCharge = value.toDouble();
  }

  void createTime() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingSeconds > 0) {
          print('are you the culprit?');
          remainingSeconds--;
        } else {
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
      data: (data) {
        print('or are you?');
        double actualFare = getActualFare(data.fare, data.promo['discount'],
            data.discount['discount'], data.vatTax, data.ccTax, data.discount['peso']);
        int duration = getDuration(data.duration);

        if (data.driver['driver_id'] != '' && !flag1) {
          flag1 = true;
          remainingSeconds = int.parse(data.driver['duration'].replaceAll('s', ''));
          createTime();
        }
        if (data.status == 'ongoing' && !flag2) {
          flag2 = true;
          timer?.cancel();
        }
        if (data.status == 'cancelled' && !flag4) {
          flag4 = true;
          Navigator.popUntil(context, ModalRoute.withName('/Home'));
        }
        if (data.status == 'completed' && !flag3) {
          flag3 = true;
          if (userAuth!.email != null && userAuth.email!.isNotEmpty) {
            if (data.changedRoute!.isEmpty) {
              sendEmailV1(data, userAuth.email!);
            } else {
              sendEmailV2(data, userAuth.email!);
            }
          }
          if (userAuth.phoneNumber != null && userAuth.phoneNumber!.isNotEmpty) {
            print('text sent to ' + userAuth.phoneNumber!);
            sendText(data, userAuth.phoneNumber!);
          }
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            print('How many times');
            DatabaseService database = DatabaseService();
            double charge =
            await database.getPassengerCharge(data.passenger['passenger_id']);
            showRating(context, data.id, data.driver['driver_id'], charge,
                data.passenger['passenger_id']);
          });
        }
        if (data.changedRoute!.isNotEmpty && !flag5) {
          flag5 = true;
          print('it now has been trued');
          getPolylineFromPoints2(data.changedRoute!);
        }
        if (data.driver['driver_id'] != '') {
          geo = data.driver['driver_location']['geopoint'];
          driverPos = LatLng(geo!.latitude, geo!.longitude);
        }

        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: lightBackground,
          body: SafeArea(
            child: Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: currentPosition,
                  polylines: Set<Polyline>.of(polyLines.values),
                  myLocationEnabled: true,
                  onMapCreated: (GoogleMapController mapController) {
                    controller.complete(mapController);
                  },
                  markers: {
                    if (pickUp != null)
                      Marker(
                        markerId: const MarkerId('pickUpLocation'),
                        position: pickUp!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen),
                      ),
                    if (dest != null)
                      Marker(
                        markerId: const MarkerId('dropOffLocation'),
                        position: dest!,
                        icon: destination_flag,
                      ),
                    if (data.driver['driver_id'] != '' && driverPos != null)
                      Marker(
                        markerId: const MarkerId('Driver'),
                        position: driverPos!,
                        icon: driver_flag,
                      ),
                  },
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                ),

                // Enhanced Bottom Sheet
                Positioned(
                  bottom: 0.0,
                  left: 0.0,
                  right: 0.0,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(_slideController),
                    child: GestureDetector(
                      onVerticalDragUpdate: (details) {
                        setState(() {
                          _currentHeight -= details.delta.dy;
                          _currentHeight = _currentHeight.clamp(_minHeight, _maxHeight);
                        });
                      },
                      child: Container(
                        height: _currentHeight,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24.0),
                            topRight: Radius.circular(24.0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Handle Bar
                            Container(
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

                            // Driver Status
                            Column(
                              children: [
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: data.driver['driver_id'] == ''
                                      ? const Searching()
                                      : DriverFound(
                                      driver: data.driver, vehicle: data.vehicle),
                                ),
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 20),
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.grey[300]!,
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Trip Details Content
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Location Cards
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            lightBackground,
                                            Colors.white,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16.0),
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          // Pickup Location
                                          Container(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: successGreen.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    Icons.trip_origin,
                                                    size: (SizeConfig.safeBlockHorizontal * 5).clamp(20.0, 28.0),
                                                    color: successGreen,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Pickup Location',
                                                        style: TextStyle(
                                                          fontSize: (SizeConfig.safeBlockHorizontal * 3).clamp(12.0, 14.0),
                                                          color: Colors.grey[600],
                                                          fontFamily: 'Montserrat',
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        data.changedPickupAddress == ''
                                                            ? data.pickupAddress
                                                            : data.changedPickupAddress,
                                                        style: TextStyle(
                                                          fontSize: (SizeConfig.safeBlockHorizontal * 3.5).clamp(14.0, 16.0),
                                                          fontWeight: FontWeight.w600,
                                                          color: darkGray,
                                                          fontFamily: 'Montserrat',
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Divider
                                          Container(
                                            height: 1,
                                            margin: const EdgeInsets.symmetric(horizontal: 16),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.grey[300]!,
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),

                                          // Drop-off Location
                                          Container(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: errorRed.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    Icons.pin_drop,
                                                    size: (SizeConfig.safeBlockHorizontal * 5).clamp(20.0, 28.0),
                                                    color: errorRed,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Drop-off Location',
                                                        style: TextStyle(
                                                          fontSize: (SizeConfig.safeBlockHorizontal * 3).clamp(12.0, 14.0),
                                                          color: Colors.grey[600],
                                                          fontFamily: 'Montserrat',
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        data.changedDropOffAddress == ''
                                                            ? data.dropOffAddress
                                                            : data.changedDropOffAddress,
                                                        style: TextStyle(
                                                          fontSize: (SizeConfig.safeBlockHorizontal * 3.5).clamp(14.0, 16.0),
                                                          fontWeight: FontWeight.w600,
                                                          color: darkGray,
                                                          fontFamily: 'Montserrat',
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 16.0),

                                    // Vehicle & Fare Card
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [primaryNavy, brightBlue],
                                        ),
                                        borderRadius: BorderRadius.circular(16.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryNavy.withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          children: [
                                            // Vehicle Image
                                            Container(
                                              width: 60,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: trip.vehicleTypeImage != null
                                                  ? ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  trip.vehicleTypeImage!,
                                                  fit: BoxFit.contain,
                                                  color: Colors.white,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return const Icon(
                                                      Icons.directions_car,
                                                      color: Colors.white,
                                                      size: 24,
                                                    );
                                                  },
                                                ),
                                              )
                                                  : const Icon(
                                                Icons.directions_car,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),

                                            const SizedBox(width: 16),

                                            // Vehicle Details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    data.vehicleType,
                                                    style: TextStyle(
                                                      fontSize: (SizeConfig.safeBlockHorizontal * 4).clamp(16.0, 18.0),
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.white,
                                                      fontFamily: 'Montserrat',
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Total Fare',
                                                    style: TextStyle(
                                                      fontSize: (SizeConfig.safeBlockHorizontal * 3).clamp(12.0, 14.0),
                                                      color: Colors.white.withOpacity(0.8),
                                                      fontFamily: 'Montserrat',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Fare Amount
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '₱${actualFare.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: (SizeConfig.safeBlockHorizontal * 4).clamp(16.0, 18.0),
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  fontFamily: 'Montserrat',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16.0),

                                    // Trip Statistics
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  lightBackground,
                                                  Colors.white,
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.grey[200]!,
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.straighten,
                                                  color: brightBlue,
                                                  size: 24,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '${data.distance} km',
                                                  style: TextStyle(
                                                    fontSize: (SizeConfig.safeBlockHorizontal * 4).clamp(14.0, 16.0),
                                                    fontWeight: FontWeight.w600,
                                                    color: darkGray,
                                                    fontFamily: 'Montserrat',
                                                  ),
                                                ),
                                                Text(
                                                  'Distance',
                                                  style: TextStyle(
                                                    fontSize: (SizeConfig.safeBlockHorizontal * 3).clamp(12.0, 14.0),
                                                    color: Colors.grey[600],
                                                    fontFamily: 'Montserrat',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  lightBackground,
                                                  Colors.white,
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.grey[200]!,
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  color: brightBlue,
                                                  size: 24,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  int.parse(data.duration.replaceAll('s', '')) < 60
                                                      ? '$duration sec'
                                                      : '$duration min',
                                                  style: TextStyle(
                                                    fontSize: (SizeConfig.safeBlockHorizontal * 4).clamp(14.0, 16.0),
                                                    fontWeight: FontWeight.w600,
                                                    color: darkGray,
                                                    fontFamily: 'Montserrat',
                                                  ),
                                                ),
                                                Text(
                                                  'Duration',
                                                  style: TextStyle(
                                                    fontSize: (SizeConfig.safeBlockHorizontal * 3).clamp(12.0, 14.0),
                                                    color: Colors.grey[600],
                                                    fontFamily: 'Montserrat',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16.0),

                                    // Change Location Button
                                    if (data.changedRoute!.isEmpty)
                                      Center(
                                        child: TextButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ChangeDropOffSelect(tripId: data.id),
                                              ),
                                            );
                                          },
                                          icon: Icon(
                                            Icons.edit_location,
                                            color: brightBlue,
                                            size: 20,
                                          ),
                                          label: Text(
                                            'Change Destination',
                                            style: TextStyle(
                                              fontSize: (SizeConfig.safeBlockHorizontal * 4).clamp(14.0, 16.0),
                                              fontWeight: FontWeight.w600,
                                              color: brightBlue,
                                              fontFamily: 'Montserrat',
                                            ),
                                          ),
                                        ),
                                      ),

                                    const SizedBox(height: 16.0),

                                    // Payment & Discount Cards
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  lightBackground,
                                                  Colors.white,
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.grey[200]!,
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.payment,
                                                  color: brightBlue,
                                                  size: 20,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  data.paymentMethod['payment_method'],
                                                  style: TextStyle(
                                                    fontSize: (SizeConfig.safeBlockHorizontal * 3.5).clamp(12.0, 14.0),
                                                    fontWeight: FontWeight.w600,
                                                    color: darkGray,
                                                    fontFamily: 'Montserrat',
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  'Payment',
                                                  style: TextStyle(
                                                    fontSize: (SizeConfig.safeBlockHorizontal * 3).clamp(10.0, 12.0),
                                                    color: Colors.grey[600],
                                                    fontFamily: 'Montserrat',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  lightBackground,
                                                  Colors.white,
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.grey[200]!,
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.local_offer,
                                                  color: brightBlue,
                                                  size: 20,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  data.promo['discount'] != 0.0
                                                      ? '${(data.promo['discount'] * 100)}%'
                                                      : 'N/A',
                                                  style: TextStyle(
                                                    fontSize: (SizeConfig.safeBlockHorizontal * 3.5).clamp(12.0, 14.0),
                                                    fontWeight: FontWeight.w600,
                                                    color: darkGray,
                                                    fontFamily: 'Montserrat',
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  'Discount',
                                                  style: TextStyle(
                                                    fontSize: (SizeConfig.safeBlockHorizontal * 3).clamp(10.0, 12.0),
                                                    color: Colors.grey[600],
                                                    fontFamily: 'Montserrat',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 24.0),

                                    // Action Buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Cancel Button
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: errorRed, width: 2),
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(25),
                                              onTap: () async {
                                                if (data.driver['driver_id'] != '') {
                                                  await showBeforeCancel(context);
                                                }
                                                showCancelDialog(context, data.id,
                                                    data.driver['driver_id'], data.passenger['passenger_id']);
                                              },
                                              child: Container(
                                                width: 50,
                                                height: 50,
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  Icons.close,
                                                  color: errorRed,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 20.0),

                                        // Emergency Button (only show during ongoing trips)
                                        if (data.status == 'ongoing')
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [errorRed, Colors.red[700]!],
                                              ),
                                              borderRadius: BorderRadius.circular(25),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: errorRed.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(25),
                                                onTap: () async {
                                                  DatabaseService database = DatabaseService();
                                                  String phoneNum = await database.getEmergencyPhone();
                                                  await database.cancelTripEmergency(data.id,
                                                      data.driver['driver_id'], data.passenger['passenger_id']);
                                                  await telephony.dialPhoneNumber('+63$phoneNum');
                                                  Navigator.popUntil(context, ModalRoute.withName('/Home'));
                                                },
                                                child: Container(
                                                  width: 50,
                                                  height: 50,
                                                  alignment: Alignment.center,
                                                  child: FadeTransition(
                                                    opacity: _pulseController,
                                                    child: const Icon(
                                                      Icons.call,
                                                      color: Colors.white,
                                                      size: 24,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),

                                    const SizedBox(height: 20.0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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