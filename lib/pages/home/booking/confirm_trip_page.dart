import 'dart:async';
import 'dart:math' as math;
import 'package:bottom_sheet/bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pakyaw/models/discount_model.dart';
import 'package:pakyaw/pages/home/booking/discount.dart';
import 'package:pakyaw/pages/home/booking/payment.dart';
import 'package:pakyaw/pages/home/booking/promos.dart';
import 'package:pakyaw/pages/home/booking/trip_details.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/providers/trip_provider.dart';
import 'package:pakyaw/providers/user_provider.dart';
import 'package:pakyaw/services/database.dart';
import 'package:pakyaw/shared/searching.dart';
import 'package:pakyaw/shared/size_config.dart';

import 'note.dart';

// Enhanced PAKYAW Color Palette
const Color primaryNavy = Color(0xFF0B2E6B);
const Color brightBlue = Color(0xFF1C72DD);
const Color lightBlue = Color(0xFF1B99FF);
const Color darkGray = Color(0xFF303841);
const Color lightBackground = Color(0xFFF3F3F3);
const Color successGreen = Color(0xFF10B981);
const Color warningOrange = Color(0xFFF59E0B);
const Color errorRed = Color(0xFFDC2626);

class ExampleModel {
  final String description;
  final double discount;
  final String discountName;

  ExampleModel({
    required this.description,
    required this.discount,
    required this.discountName,
  });

  factory ExampleModel.fromDocument(String name, double discount, String des) {
    return ExampleModel(
      description: des,
      discount: discount,
      discountName: name,
    );
  }
}

class ConfirmTripPage extends ConsumerStatefulWidget {
  const ConfirmTripPage({super.key});

  @override
  ConsumerState<ConfirmTripPage> createState() => _ConfirmTripPageState();
}

class _ConfirmTripPageState extends ConsumerState<ConfirmTripPage>
    with TickerProviderStateMixin {
  DatabaseService database = DatabaseService();

  Completer<GoogleMapController> controller = Completer<GoogleMapController>();

  String paymentMethod = 'Cash';
  String accountNum = '';
  String promosDisplay = 'Promos';
  String promoName = '';
  double discount = 0.0;
  String discountDisplay = 'Discount';
  String discountName = '';
  double discount2 = 0.0;
  double peso = 0.0;
  String vehicleType = '';
  Map<String, dynamic> promos = {};
  Map<String, dynamic> discount3 = {};
  Map<String, dynamic> paymethod = {};

  bool _isInitialized = false;
  bool _isConfirming = false;
  late AnimationController _slideAnimation;
  late AnimationController _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _slideAnimation = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseAnimation = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Start animations
    _slideAnimation.forward();
    _pulseAnimation.repeat(reverse: true);

    // Get basic trip data synchronously
    final trip = ref.read(tripProvider);
    vehicleType = trip.vehicleType ?? '';

    // Schedule heavy operations AFTER the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _isInitialized) return;

      try {
        // Load polyline (non-blocking)
        if (trip.route != null && trip.route!.isNotEmpty) {
          getPolylineFromPoints(trip.route!);
        }

        // Load discount data with proper await and null checking
        try {
          final user = ref.read(authStateProvider).value;
          if (user != null && trip.fare != null) {
            double ccTax = trip.ccTax ?? 0.0;
            double vatTax = trip.vatTax ?? 0.0;
            double fare = trip.fare! + (trip.fare! * ccTax) + (trip.fare! * vatTax);

            await autoSelectSpecialDiscount(user.uid, fare);
          }
        } catch (e) {
          print('Error loading user for discount: $e');
        }

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } catch (e) {
        print('Error during initialization: $e');
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _slideAnimation.dispose();
    _pulseAnimation.dispose();
    super.dispose();
  }

  setPaymentMethod(value, value2) {
    setState(() {
      paymentMethod = value;
      accountNum = value2;
    });
  }

  setPromos(value3, value2) {
    setState(() {
      discount = value3;
      promosDisplay = '${(discount * 100)}%';
      promoName = value2;
    });
  }

  setDiscount(value3, value2) {
    setState(() {
      discount2 = value3;
      discountDisplay = '${(discount2 * 100)}%';
      discountName = value2;
    });
  }

  CameraPosition currentPosition = const CameraPosition(
    target: LatLng(11.00639, 124.6075),
    zoom: 19,
  );

  Map<PolylineId, Polyline> polyLines = {};

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
    fitPolylineToMap(coordinates);
  }

  showPaymentMethods() {
    showFlexibleBottomSheet(
      context: context,
      builder: _buildBottomSheet,
      minHeight: 0,
      initHeight: 0.8,
      maxHeight: 1,
      anchors: [0, 0.5, 0.8],
      isSafeArea: true,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  showPromos() {
    showFlexibleBottomSheet(
      context: context,
      builder: _buildBottomSheet2,
      minHeight: 0,
      initHeight: 0.8,
      maxHeight: 1,
      anchors: [0, 0.5, 0.8],
      isSafeArea: true,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  showDiscount() {
    showFlexibleBottomSheet(
      context: context,
      builder: _buildBottomSheet3,
      minHeight: 0,
      initHeight: 0.8,
      maxHeight: 1,
      anchors: [0, 0.5, 0.8],
      isSafeArea: true,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  void showNotePanel(String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Note(name: name),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheet2(
      BuildContext context, ScrollController scrollController, double bottomSheet) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryNavy, brightBlue],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_offer,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Available Promos',
                  style: TextStyle(
                    fontSize: (SizeConfig.safeBlockHorizontal * 5).clamp(18.0, 24.0),
                    fontWeight: FontWeight.w600,
                    color: darkGray,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Promos(discount: setPromos, vehicleType: vehicleType),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet3(
      BuildContext context, ScrollController scrollController, double bottomSheet) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryNavy, brightBlue],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.percent,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Available Discounts',
                  style: TextStyle(
                    fontSize: (SizeConfig.safeBlockHorizontal * 5).clamp(18.0, 24.0),
                    fontWeight: FontWeight.w600,
                    color: darkGray,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Discount(discount: setDiscount),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(
      BuildContext context, ScrollController scrollController, double bottomSheet) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryNavy, brightBlue],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.payment,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Payment Methods',
                  style: TextStyle(
                    fontSize: (SizeConfig.safeBlockHorizontal * 5).clamp(18.0, 24.0),
                    fontWeight: FontWeight.w600,
                    color: darkGray,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                PaymentWay(paymentMethod: setPaymentMethod)
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> autoSelectSpecialDiscount(String userId, double fare) async {
    try {
      final user = await database.getCurrentUser(userId).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Failed to fetch user data');
        },
      );

      List<Map<double, dynamic>> availableDiscounts = [];

      if (user.student != null) {
        try {
          final studentDiscount = await database.getStudentDiscount().timeout(
            const Duration(seconds: 5),
          );
          Map<double, Map<String, dynamic>> model = {};
          double disc = studentDiscount.discount;
          double peso = studentDiscount.peso;
          double tempDisc = 0.0;
          if (peso != 0) {
            tempDisc = fare - peso;
            model[tempDisc] = {
              'discountName': studentDiscount.discountName,
              'discount': studentDiscount.discount,
              'peso': studentDiscount.peso,
              'description': studentDiscount.description,
            };
          } else if (disc != 0) {
            tempDisc = fare - (fare * disc);
            model[tempDisc] = {
              'discountName': studentDiscount.discountName,
              'discount': studentDiscount.discount,
              'peso': studentDiscount.peso,
              'description': studentDiscount.description,
            };
          }
          availableDiscounts.add(model);
        } catch (e) {
          print('Error loading student discount: $e');
        }
      }

      if (user.pwd != null) {
        try {
          final pwdDiscount = await database.getPWDDiscount().timeout(
            const Duration(seconds: 5),
          );
          Map<double, Map<String, dynamic>> model = {};
          double disc = pwdDiscount.discount;
          double peso = pwdDiscount.peso;
          double tempDisc = 0.0;
          if (peso != 0) {
            tempDisc = fare - peso;
            model[tempDisc] = {
              'discountName': pwdDiscount.discountName,
              'discount': pwdDiscount.discount,
              'peso': pwdDiscount.peso,
              'description': pwdDiscount.description,
            };
          } else if (disc != 0) {
            tempDisc = fare - (fare * disc);
            model[tempDisc] = {
              'discountName': pwdDiscount.discountName,
              'discount': pwdDiscount.discount,
              'peso': pwdDiscount.peso,
              'description': pwdDiscount.description,
            };
          }
          availableDiscounts.add(model);
        } catch (e) {
          print('Error loading PWD discount: $e');
        }
      }

      if (user.senior != null) {
        try {
          final seniorDiscount = await database.getSeniorDiscount().timeout(
            const Duration(seconds: 5),
          );
          Map<double, Map<String, dynamic>> model = {};
          double disc = seniorDiscount.discount;
          double peso = seniorDiscount.peso;
          double tempDisc = 0.0;
          if (peso != 0) {
            tempDisc = fare - peso;
            model[tempDisc] = {
              'discountName': seniorDiscount.discountName,
              'discount': seniorDiscount.discount,
              'peso': seniorDiscount.peso,
              'description': seniorDiscount.description,
            };
          } else if (disc != 0) {
            tempDisc = fare - (fare * disc);
            model[tempDisc] = {
              'discountName': seniorDiscount.discountName,
              'discount': seniorDiscount.discount,
              'peso': seniorDiscount.peso,
              'description': seniorDiscount.description,
            };
          }
          availableDiscounts.add(model);
        } catch (e) {
          print('Error loading senior discount: $e');
        }
      }

      if (availableDiscounts.isNotEmpty) {
        Map<double, dynamic> finalDiscount = availableDiscounts.reduce(
                (current, next) =>
            current.keys.first > next.keys.first ? current : next);
        var temp = finalDiscount[finalDiscount.keys.first];
        if (mounted) {
          setState(() {
            discountName = temp['discountName'];
            discount2 = temp['discount'];
            peso = temp['peso'];
            discountDisplay = temp['discountName'];
          });
        }
      } else {
        if (mounted) {
          setState(() {
            discountName = '';
            discount2 = 0.0;
          });
        }
      }
    } catch (e) {
      print('Error loading discount: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    final trip = ref.read(tripProvider);

    double ccTax = trip.ccTax ?? 0.0;
    double vatTax = trip.vatTax ?? 0.0;
    double baseFare = trip.fare ?? 0.0;
    double fare = baseFare + (baseFare * ccTax) + (baseFare * vatTax);

    // Calculate responsive dimensions
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: lightBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Google Map Background
            GoogleMap(
              initialCameraPosition: currentPosition,
              polylines: Set<Polyline>.of(polyLines.values),
              onMapCreated: (GoogleMapController mapController) {
                controller.complete(mapController);
              },
              markers: trip.route != null && trip.route!.isNotEmpty
                  ? {
                Marker(
                  markerId: const MarkerId('pickUpLocation'),
                  position: trip.route![0],
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen),
                ),
                Marker(
                  markerId: const MarkerId('dropOffLocation'),
                  position: trip.route![trip.route!.length - 1],
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
                ),
              }
                  : {},
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),

            // Back Button
            Positioned(
              top: 16,
              left: 16,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-1, 0),
                  end: Offset.zero,
                ).animate(_slideAnimation),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryNavy, brightBlue],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: primaryNavy.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Notes Button
            Positioned(
              top: 16,
              right: 16,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(_slideAnimation),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: () => showNotePanel(trip.notes ?? ''),
                      child: Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.edit_note,
                          color: darkGray,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Trip Information Card
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(_slideAnimation),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: screenHeight * 0.3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pickup Location
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
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
                                  color: successGreen,
                                  size: isSmallScreen ? 20 : 24,
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
                                        fontSize: (SizeConfig.safeBlockHorizontal * 3).clamp(12.0, 16.0),
                                        color: Colors.grey[600],
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      trip.pickup ?? 'Not set',
                                      style: TextStyle(
                                        fontSize: (SizeConfig.safeBlockHorizontal * 4).clamp(14.0, 18.0),
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
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
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
                                  color: errorRed,
                                  size: isSmallScreen ? 20 : 24,
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
                                        fontSize: (SizeConfig.safeBlockHorizontal * 3).clamp(12.0, 16.0),
                                        color: Colors.grey[600],
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      trip.dropOff ?? 'Not set',
                                      style: TextStyle(
                                        fontSize: (SizeConfig.safeBlockHorizontal * 4).clamp(14.0, 18.0),
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
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Trip Details Card
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(_slideAnimation),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: screenHeight * 0.4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Vehicle Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Vehicle Image
                            Container(
                              width: isSmallScreen ? 60 : 80,
                              height: isSmallScreen ? 40 : 50,
                              decoration: BoxDecoration(
                                color: lightBackground,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: trip.vehicleTypeImage != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  trip.vehicleTypeImage!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.directions_car,
                                      color: brightBlue,
                                      size: isSmallScreen ? 24 : 32,
                                    );
                                  },
                                ),
                              )
                                  : Icon(
                                Icons.directions_car,
                                color: brightBlue,
                                size: isSmallScreen ? 24 : 32,
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Vehicle Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trip.vehicleType ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: (SizeConfig.safeBlockHorizontal * 4.5).clamp(16.0, 20.0),
                                      fontWeight: FontWeight.w600,
                                      color: darkGray,
                                      fontFamily: 'Montserrat',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Estimated Fare',
                                    style: TextStyle(
                                      fontSize: (SizeConfig.safeBlockHorizontal * 3).clamp(12.0, 14.0),
                                      color: Colors.grey[600],
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
                                gradient: LinearGradient(
                                  colors: [primaryNavy, brightBlue],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '₱${fare.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: (SizeConfig.safeBlockHorizontal * 4).clamp(14.0, 18.0),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Divider
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: Colors.grey[200],
                      ),

                      // Options Row
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Payment Method
                            Expanded(
                              child: _buildOptionCard(
                                icon: Icons.payment,
                                title: paymentMethod,
                                onTap: showPaymentMethods,
                                isSmallScreen: isSmallScreen,
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Discount
                            Expanded(
                              child: _buildOptionCard(
                                icon: Icons.percent,
                                title: discountDisplay,
                                onTap: showDiscount,
                                isSmallScreen: isSmallScreen,
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Promos
                            Expanded(
                              child: _buildOptionCard(
                                icon: Icons.local_offer,
                                title: promosDisplay,
                                onTap: showPromos,
                                isSmallScreen: isSmallScreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Confirm Button
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(_slideAnimation),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isConfirming
                          ? [Colors.grey[400]!, Colors.grey[500]!]
                          : [primaryNavy, brightBlue],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (_isConfirming ? Colors.grey : primaryNavy).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isConfirming ? null : _handleConfirmTrip,
                      child: Container(
                        alignment: Alignment.center,
                        child: _isConfirming
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Confirming...',
                              style: TextStyle(
                                fontSize: (SizeConfig.safeBlockHorizontal * 4.5).clamp(16.0, 20.0),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ],
                        )
                            : Text(
                          'Confirm Trip',
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: lightBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: isSmallScreen ? 8 : 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: isSmallScreen ? 16 : 20,
                  color: brightBlue,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: (SizeConfig.safeBlockHorizontal * 3).clamp(11.0, 14.0),
                    fontWeight: FontWeight.w500,
                    color: darkGray,
                    fontFamily: 'Montserrat',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleConfirmTrip() async {
    if (_isConfirming) return;

    setState(() {
      _isConfirming = true;
    });

    try {
      promos = {
        'promo_name': promoName,
        'discount': discount,
      };
      discount3 = {
        'discount_name': discountName,
        'discount': discount2,
        'peso': peso,
      };
      paymethod = {
        'payment_method': paymentMethod,
        'account_num': accountNum
      };

      ref.read(tripProvider.notifier).updateTrip((trip) => trip.copyWith(
          promos: promos, paymentMethod: paymethod, discount: discount3));

      ref.read(tripProvider.notifier).printTripDetails();
      String? results = await ref.read(tripProvider).saveToFireStore();

      if (results != null) {
        print(results);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TripDetails(tripId: results),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("An error occurred please try again later."),
              backgroundColor: errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error confirming trip: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("An error occurred please try again later."),
            backgroundColor: errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }
}