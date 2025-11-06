import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pakyaw/assistants/request_assistant.dart';
import 'package:pakyaw/pages/home/booking/confirm_trip_page.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/providers/trip_provider.dart';
import 'package:pakyaw/providers/vehicle_types_provider.dart';
import 'package:pakyaw/services/database.dart';
import 'package:pakyaw/shared/error.dart';
import 'package:pakyaw/shared/loading.dart';
import 'package:pakyaw/shared/size_config.dart';

import '../../../shared/global_var.dart';

class ConfirmVehicletype extends ConsumerStatefulWidget {
  const ConfirmVehicletype({super.key});

  @override
  ConsumerState<ConfirmVehicletype> createState() => _ConfirmVehicletypeState();
}

class _ConfirmVehicletypeState extends ConsumerState<ConfirmVehicletype> with TickerProviderStateMixin {

  DatabaseService database = DatabaseService();
  int? selectedCapacity = 1;
  int? selectedIndex;
  String? selectedVehicle;
  int? baseRate;
  double? ratePerKm;
  String? typeImage;
  List<LatLng>? routePoints;
  String? duration;
  double? distance;
  int? wheels;
  String error1 = '';
  String id = '';
  bool isLoading = false;
  late AnimationController _animationController;
  late AnimationController _pulseController;

  // PAKYAW Brand Colors
  static const Color primaryNavy = Color(0xFF0B2E6B);
  static const Color brightBlue = Color(0xFF1C72DD);
  static const Color lightBlue = Color(0xFF1B99FF);
  static const Color darkGray = Color(0xFF303841);
  static const Color lightBackground = Color(0xFFF3F3F3);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animationController.forward();
    _pulseController.repeat(reverse: true);

    ref.read(tripProvider.notifier).printTripDetails();
    final user = ref.read(authStateProvider).value;
    id = user!.uid;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isSuccess = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? successGreen : Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  showWarning(BuildContext context1){
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [warningOrange, warningOrange.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Selection Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
          content: const Text(
            'Please select a vehicle type to continue',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Montserrat',
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryNavy, brightBlue],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        )
    );
  }

  getRouteInfo(LatLng origin, LatLng destination, String travelMode) async {
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
      'travelMode': travelMode,
      'routingPreference': 'TRAFFIC_AWARE',
      'computeAlternativeRoutes': false,
      'routeModifiers': {'avoidTolls': false, 'avoidHighways': false, 'avoidFerries': true},
      'languageCode': 'en-US',
      'units': 'METRIC'
    };

    var response = await RequestAssistant.postRequest(url, headers, body);

    if(response is Map<String, dynamic> && response.containsKey('routes')){
      final route = response['routes'][0];

      distance = route['distanceMeters'] / 1000.0;
      duration = route['duration'];
      routePoints = decodePolyline(route['polyline']['encodedPolyline']);

    }else{
      throw Exception('Failed to get route information: $response');
    }
  }

  Duration parseDuration(String s) {
    int hours = 0;
    int minutes = 0;
    int seconds = 0;
    List<String> parts = s.replaceAll(' ', '').toLowerCase().split(RegExp(r'[hms]'));
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        switch (s[s.indexOf(parts[i]) + parts[i].length]) {
          case 'h':
            hours = int.parse(parts[i]);
            break;
          case 'm':
            minutes = int.parse(parts[i]);
            break;
          case 's':
            seconds = int.parse(parts[i]);
            break;
        }
      }
    }
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  List<LatLng> decodePolyline(String encoded) {
    List<PointLatLng> points = PolylinePoints().decodePolyline(encoded);
    return points.map((point) => LatLng(point.latitude, point.longitude)).toList();
  }

  Widget _buildCapacitySelector(data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            lightBackground.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryNavy, brightBlue],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.people,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'How many passengers?',
                style: TextStyle(
                  fontSize: SizeConfig.safeBlockHorizontal * 5,
                  fontWeight: FontWeight.w600,
                  color: darkGray,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: SizeConfig.blockSizeHorizontal * 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [lightBackground, Colors.white],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: brightBlue.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: brightBlue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: DropdownButton<int>(
                menuMaxHeight: 200.0,
                underline: Container(),
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                onChanged: (int? value){
                  setState(() {
                    selectedCapacity = value;
                    selectedIndex = null;
                    selectedVehicle = null;
                  });
                },
                isExpanded: true,
                value: selectedCapacity,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: brightBlue,
                  size: 24,
                ),
                style: TextStyle(
                  fontSize: SizeConfig.safeBlockHorizontal * 4,
                  fontWeight: FontWeight.w600,
                  color: darkGray,
                  fontFamily: 'Montserrat',
                ),
                items: List<int>.generate(data.capacity, (int index) => index + 1).map(
                      (val) {
                    return DropdownMenuItem<int>(
                      value: val,
                      child: Text(
                        '$val ${val == 1 ? 'passenger' : 'passengers'}',
                        style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 4,
                          fontWeight: FontWeight.w600,
                          color: darkGray,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(vehicleData, int index, bool isAvailable) {
    final isSelected = selectedIndex == index;

    return FadeTransition(
      opacity: _animationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.1,
            1.0,
            curve: Curves.easeOutCubic,
          ),
        )),
        child: GestureDetector(
          onTap: isAvailable
              ? () {
            setState(() {
              selectedIndex = index;
              selectedVehicle = vehicleData.type;
              baseRate = vehicleData.baseRate;
              ratePerKm = vehicleData.ratePerKm;
              typeImage = vehicleData.image;
              wheels = vehicleData.wheels;
            });
          }
              : null,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate dynamic sizing based on available space
              final availableWidth = constraints.maxWidth;
              final availableHeight = constraints.maxHeight;
              final imageSize = math.min(availableWidth * 0.3, availableHeight * 0.35).clamp(30.0, 60.0);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(6),
                padding: const EdgeInsets.all(8),
                constraints: BoxConstraints(
                  minHeight: 120,
                  maxHeight: availableHeight,
                  minWidth: availableWidth,
                  maxWidth: availableWidth,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryNavy, brightBlue],
                  )
                      : isAvailable
                      ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      lightBackground.withOpacity(0.5),
                    ],
                  )
                      : LinearGradient(
                    colors: [Colors.grey[200]!, Colors.grey[100]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? brightBlue.withOpacity(0.25)
                          : Colors.black.withOpacity(0.06),
                      blurRadius: isSelected ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Selection indicator
                    if (isSelected)
                      Flexible(
                        child: FadeTransition(
                          opacity: _pulseController,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),

                    if (isSelected) const SizedBox(height: 2),

                    // Vehicle icon with flexible container
                    Flexible(
                      flex: 3,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: imageSize + 16,
                          maxHeight: imageSize + 16,
                        ),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : isAvailable
                              ? lightBackground.withOpacity(0.5)
                              : Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Image.network(
                            vehicleData.image,
                            width: imageSize,
                            height: imageSize,
                            fit: BoxFit.contain,
                            color: isSelected
                                ? Colors.white
                                : isAvailable
                                ? null
                                : Colors.grey,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.directions_car,
                                size: imageSize,
                                color: isSelected
                                    ? Colors.white
                                    : isAvailable
                                    ? brightBlue
                                    : Colors.grey,
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Vehicle type text with proper constraints
                    Flexible(
                      child: Container(
                        constraints: BoxConstraints(maxWidth: availableWidth - 16),
                        child: Text(
                          vehicleData.type,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : isAvailable
                                ? darkGray
                                : Colors.grey[600],
                            fontSize: (SizeConfig.safeBlockHorizontal * 2.8).clamp(10.0, 14.0),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Montserrat',
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    const SizedBox(height: 1),

                    // Capacity text
                    Flexible(
                      child: Text(
                        'Max: ${vehicleData.capacity}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white.withOpacity(0.8)
                              : isAvailable
                              ? Colors.grey[600]
                              : Colors.grey[500],
                          fontSize: (SizeConfig.safeBlockHorizontal * 2.4).clamp(9.0, 12.0),
                          fontFamily: 'Montserrat',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Unavailable badge with proper constraints
                    if (!isAvailable)
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          constraints: BoxConstraints(maxWidth: availableWidth - 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Unavailable',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: (SizeConfig.safeBlockHorizontal * 2.0).clamp(8.0, 10.0),
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Montserrat',
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicleTypes = ref.watch(vehicleTypesProvider);
    final maxCapacity = ref.watch(maxCapacityProvider);
    final trip = ref.watch(tripProvider);

    return vehicleTypes.when(
      data: (data) {
        return Scaffold(
          backgroundColor: lightBackground,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryNavy, brightBlue],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            title: Text(
              'Choose Vehicle Type',
              style: TextStyle(
                fontSize: SizeConfig.safeBlockHorizontal * 5,
                fontWeight: FontWeight.w700,
                color: darkGray,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
          body: Column(
            children: [
              const SizedBox(height: 20),

              // Capacity Selector
              maxCapacity.when(
                data: (capacityData) => _buildCapacitySelector(capacityData),
                error: (e, error) => Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Error loading capacity: $e',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, lightBackground.withOpacity(0.5)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircularProgressIndicator(
                        color: brightBlue,
                        strokeWidth: 3,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Loading capacity options...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Vehicle Types Section
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        lightBackground.withOpacity(0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryNavy, brightBlue],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.directions_car,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Available Vehicles',
                            style: TextStyle(
                              fontSize: SizeConfig.safeBlockHorizontal * 5,
                              fontWeight: FontWeight.w600,
                              color: darkGray,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ],
                      ),

                      if (error1.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[300]!),
                          ),
                          child: Text(
                            error1,
                            style: TextStyle(
                              fontSize: SizeConfig.safeBlockHorizontal * 3.5,
                              color: Colors.red[600],
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Filter available vehicles based on selected capacity
                            final availableVehicles = data.where((vehicle) =>
                            selectedCapacity! <= vehicle.capacity).toList();

                            // Show message if no vehicles are available
                            if (availableVehicles.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No vehicles available for ${selectedCapacity!} ${selectedCapacity! == 1 ? 'passenger' : 'passengers'}',
                                      style: TextStyle(
                                        fontSize: SizeConfig.safeBlockHorizontal * 4,
                                        color: Colors.grey[600],
                                        fontFamily: 'Montserrat',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Please select a lower passenger count',
                                      style: TextStyle(
                                        fontSize: SizeConfig.safeBlockHorizontal * 3.5,
                                        color: Colors.grey[500],
                                        fontFamily: 'Montserrat',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }

                            return GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8.0,
                                mainAxisSpacing: 8.0,
                                childAspectRatio: constraints.maxWidth > 600 ? 0.85 : 0.75,
                              ),
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                final isAvailable = selectedCapacity! <= data[index].capacity;

                                return _buildVehicleCard(data[index], index, isAvailable);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Confirm Button
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: SizeConfig.blockSizeVertical * 7,
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryNavy, brightBlue, lightBlue],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: brightBlue.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: isLoading ? null : () async {
                        // Validate vehicle selection first
                        if (selectedVehicle == null) {
                          showWarning(context);
                          return;
                        }

                        // Validate that trip locations exist
                        if (trip.pickupLoc == null || trip.dropOffLoc == null) {
                          _showSnackBar("Location data is missing. Please go back and select locations again.", isSuccess: false);
                          return;
                        }

                        setState(() {
                          isLoading = true;
                        });

                        try {
                          // Fetch required data
                          double ccTax = 0.0;
                          try {
                            ccTax = await database.getCCTax();
                          } catch (e) {
                            print('Warning: Could not fetch CC Tax, using default value 0.0: $e');
                          }

                          double basekm = await database.getBaseKm();
                          double charge = await database.getPassengerCharge(id);

                          double fare = 0;
                          String travelMode = wheels! <= 3 ? 'TWO_WHEELER' : 'DRIVE';

                          print('Travel Mode: $travelMode');

                          // Get route information
                          await getRouteInfo(
                              LatLng(trip.pickupLoc!.latitude, trip.pickupLoc!.longitude),
                              LatLng(trip.dropOffLoc!.latitude, trip.dropOffLoc!.longitude),
                              travelMode
                          );

                          // Validate that route info was successfully retrieved
                          if (duration == null || routePoints == null || distance == null) {
                            if (mounted) {
                              _showSnackBar("Failed to calculate route. Please try again.", isSuccess: false);
                            }
                            return;
                          }

                          // Calculate fare
                          print('Distance: $distance km, Base km: $basekm');
                          if (distance! < basekm) {
                            fare = baseRate!.toDouble();
                          } else {
                            fare = baseRate! + ((distance! - basekm) * ratePerKm!);
                          }

                          print('Calculated fare: $fare');

                          // Update trip provider (VAT removed, set to 0)
                          ref.read(tripProvider.notifier).updateTrip((trip) => trip.copyWith(
                            vehicleType: selectedVehicle,
                            baseRate: baseRate,
                            ratePerKm: ratePerKm,
                            vehicleTypeImage: typeImage,
                            duration: duration,
                            route: routePoints,
                            distance: distance,
                            vatTax: 0.0,  // VAT REMOVED
                            ccTax: ccTax,
                            travelMode: travelMode,
                            fare: double.parse((fare + charge).toStringAsFixed(2)),
                          ));

                          // Navigate to next screen
                          if (mounted) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ConfirmTripPage())
                            );
                          }

                        } catch (e) {
                          print('Error in confirm vehicle: $e');

                          // Show error message to user
                          if (mounted) {
                            _showSnackBar("Error: ${e.toString()}", isSuccess: false);
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        }
                      },
                      child: isLoading
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Calculating Route...',
                            style: TextStyle(
                              fontSize: SizeConfig.safeBlockHorizontal * 4.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ],
                      )
                          : Text(
                        'Confirm Selection',
                        style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      error: (e, stack) {
        print(e.toString());
        print(stack.toString());
        return ErrorCatch(error: e.toString());
      },
      loading: () => Scaffold(
        backgroundColor: lightBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: brightBlue,
                strokeWidth: 4,
              ),
              const SizedBox(height: 24),
              Text(
                'Loading vehicle types...',
                style: TextStyle(
                  fontSize: SizeConfig.safeBlockHorizontal * 4,
                  color: Colors.grey[600],
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}