import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pakyaw/pages/home/booking/confirm_vehicletype.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/providers/trip_provider.dart';
import 'package:pakyaw/providers/user_provider.dart';
import 'package:pakyaw/services/database.dart';
import 'package:pakyaw/shared/error.dart';
import 'package:pakyaw/shared/loading.dart';
import 'package:pakyaw/shared/size_config.dart';
import 'package:uuid/uuid.dart';

import '../../../assistants/request_assistant.dart';
import '../../../models/place_predictions.dart';
import '../../../shared/global_var.dart';

class DropOffSelect extends ConsumerStatefulWidget {
  final String? prefilledDestination;
  final LatLng? prefilledLatLng;

  const DropOffSelect({
    super.key,
    this.prefilledDestination,
    this.prefilledLatLng,
  });

  @override
  ConsumerState<DropOffSelect> createState() => _DropOffSelectState();
}

class _DropOffSelectState extends ConsumerState<DropOffSelect> {
  // PAKYAW Brand Colors (copied for local use)
  static const Color primaryNavy = Color(0xFF0B2E6B);
  static const Color brightBlue = Color(0xFF1C72DD);
  static const Color darkGray = Color(0xFF303841);
  static const Color lightBackground = Color(0xFFF3F3F3);

  TextEditingController pickUpController = TextEditingController();
  TextEditingController destController = TextEditingController();
  FocusNode pickUpFocus = FocusNode();
  FocusNode destFocus = FocusNode();

  final Completer<GoogleMapController> googleMapController = Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfUser;

  LatLng? draggedLocation;
  LatLng? pickup;
  LatLng? dropOff;
  String? tokenForSession;
  Timer? _debounce;

  bool isLoading = false;
  bool isPickUp = true; // True if we are setting the pickup location
  List<PlacePredictions> listForPlaces = [];

  // Initial map position
  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(11.00639, 124.6075), // Ormoc City
    zoom: 15,
  );

  @override
  void initState() {
    super.initState();
    tokenForSession = const Uuid().v4();
    pickUpController.addListener(_onPickUpSearchChanged);
    destController.addListener(_onDestSearchChanged);

    // Handle prefilled destination
    if (widget.prefilledDestination != null && widget.prefilledLatLng != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          destController.text = widget.prefilledDestination!;
          dropOff = widget.prefilledLatLng;
          isPickUp = true; // Switch to pickup mode after setting destination
        });
        // Animate camera to the prefilled destination
        controllerGoogleMap?.animateCamera(
          CameraUpdate.newLatLngZoom(widget.prefilledLatLng!, 17),
        );
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    pickUpController.dispose();
    destController.dispose();
    pickUpFocus.dispose();
    destFocus.dispose();
    super.dispose();
  }

  void findPlaces(String placeName) async {
    if (placeName.length < 2) return;

    String autoCompleteUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&location=11.0384%2C124.6105&radius=14000&strictbounds=true&key=$googleMapKey&sessiontoken=$tokenForSession";

    var res = await RequestAssistant.getRequest(autoCompleteUrl);

    if (!mounted) return;

    if (res != "Failed" && res['status'] == 'OK') {
      var predictions = res['predictions'];
      var placeList = (predictions as List).map((e) => PlacePredictions.fromJson(e)).toList();
      setState(() {
        listForPlaces = placeList;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  void _onPickUpSearchChanged() {
    if (!pickUpFocus.hasFocus) return;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (pickUpController.text.length >= 2) {
        setState(() {
          isLoading = true;
          listForPlaces.clear();
        });
        findPlaces(pickUpController.text);
      } else {
        setState(() {
          listForPlaces.clear();
          isLoading = false;
        });
      }
    });
  }

  void _onDestSearchChanged() {
    if (!destFocus.hasFocus) return;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (destController.text.length >= 2) {
        setState(() {
          isLoading = true;
          listForPlaces.clear();
        });
        findPlaces(destController.text);
      } else {
        setState(() {
          listForPlaces.clear();
          isLoading = false;
        });
      }
    });
  }

  Future<void> getCurrentLocation() async {
    try {
      Position positionOfUser = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      currentPositionOfUser = positionOfUser;

      LatLng userLatLng = LatLng(currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
      draggedLocation = userLatLng;

      CameraPosition cameraPosition = CameraPosition(target: userLatLng, zoom: 17);
      controllerGoogleMap?.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
      getAddress(userLatLng);
    } catch (e) {
      print("Error getting current location: $e");
    }
  }

  getAddress(LatLng position) async {
    final String url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleMapKey';
    var res = await RequestAssistant.getRequest(url);

    if (!mounted) return;

    if (res != "Failed" && res['status'] == 'OK') {
      final result = res['results'][0];
      final address = result['formatted_address'];
      setState(() {
        if (isPickUp) {
          pickUpController.text = address;
          pickup = position;
        } else {
          destController.text = address;
          dropOff = position;
        }
      });
    }
  }

  Future<LatLng?> getLatLngFromPlaceId(String placeId) async {
    String url = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,geometry&key=$googleMapKey&sessiontoken=$tokenForSession";
    var res = await RequestAssistant.getRequest(url);

    if (res != "Failed" && res['status'] == 'OK') {
      tokenForSession = const Uuid().v4(); // Reset session token after use
      Map<String, dynamic> geometry = res['result']['geometry']['location'];
      return LatLng(geometry['lat'], geometry['lng']);
    }
    return null;
  }

  void _onConfirmPressed() async {
    if (pickup == null || dropOff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please set both pickup and drop-off locations."))
      );
      return;
    }

    if (pickUpController.text == destController.text) {
      showDialog(context: context, builder: (context) => AlertDialog(
        title: const Text('Identical Locations'),
        content: const Text('The trip might not be necessary since the locations are the same. Do you want to proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            Navigator.pop(context);
            _proceedToNextScreen();
          }, child: const Text('Proceed')),
        ],
      ));
      return;
    }

    _proceedToNextScreen();
  }

  void _proceedToNextScreen() async {
    final userAuth = ref.read(authStateProvider).value;
    final user = ref.read(usersProvider).value;

    if (userAuth == null || user == null) return;

    DatabaseService database = DatabaseService();
    double appChargeValue = await database.getAppCharge();

    Map<String, dynamic> passenger = {
      'passenger_id': userAuth.uid,
      'passenger_name': user.name,
      'passenger_profile': user.profilePicPath,
      'rating': (user.ratingCount == 0) ? 0 : (user.totalRating / user.ratingCount)
    };

    final pickupLoc = GeoFirePoint(GeoPoint(pickup!.latitude, pickup!.longitude));
    final dropOffLoc = GeoFirePoint(GeoPoint(dropOff!.latitude, dropOff!.longitude));

    ref.read(tripProvider.notifier).updateTrip((trip) => trip.copyWith(
        pickup: pickUpController.text,
        pickupLoc: pickupLoc,
        dropOff: destController.text,
        dropOffLoc: dropOffLoc,
        rider: passenger,
        appCharge: appChargeValue
    ));

    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ConfirmVehicletype())
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final user = ref.watch(usersProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: user.when(
        data: (data) {
          if (data == null) return const Loading();
          return Stack(
            children: [
              GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _kInitialPosition,
                myLocationEnabled: true,
                myLocationButtonEnabled: false, // We have a custom one
                zoomControlsEnabled: false,
                onMapCreated: (GoogleMapController mapController) {
                  controllerGoogleMap = mapController;
                  googleMapController.complete(controllerGoogleMap);
                  getCurrentLocation();
                },
                onCameraMove: (position) {
                  draggedLocation = position.target;
                },
                onCameraIdle: () {
                  if (draggedLocation != null) {
                    getAddress(draggedLocation!);
                  }
                },
              ),

              // Back Button
              Positioned(
                top: 50,
                left: 20,
                child: FloatingActionButton(
                  mini: true,
                  onPressed: () => Navigator.pop(context),
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.arrow_back, color: darkGray),
                ),
              ),

              // Center Pin and Label
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Label to guide the user
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                      child: Container(
                        key: ValueKey<bool>(isPickUp),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: darkGray,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Text(
                          isPickUp ? "Set Pickup Location" : "Set Drop-off Location",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
                        ),
                      ),
                    ),
                    Icon(Icons.location_pin, color: isPickUp ? brightBlue : Colors.red, size: 48),
                    const SizedBox(height: 56), // Offset so pin is on the location
                  ],
                ),
              ),

              // My Location Button
              Positioned(
                top: 50,
                right: 20,
                child: FloatingActionButton(
                  mini: true,
                  onPressed: getCurrentLocation,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: darkGray),
                ),
              ),

              // NEW: Draggable Scrollable Sheet for a smoother UX
              DraggableScrollableSheet(
                initialChildSize: 0.35,
                minChildSize: 0.35,
                maxChildSize: 0.85,
                builder: (BuildContext context, ScrollController scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, spreadRadius: 5),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: Column(
                        children: [
                          // Handlebar
                          Container(
                            width: 40,
                            height: 5,
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),

                          // Redesigned Search Input Section
                          _buildSearchInputSection(),

                          const Divider(height: 1),

                          // Results/Saved Places List
                          Expanded(
                            child: isLoading
                                ? const Center(child: CircularProgressIndicator(color: brightBlue))
                                : ListView.builder(
                              controller: scrollController,
                              padding: EdgeInsets.zero,
                              itemCount: listForPlaces.isNotEmpty ? listForPlaces.length : data.savedPlaces.length,
                              itemBuilder: (context, index) {
                                if (listForPlaces.isNotEmpty) {
                                  // Display search results
                                  return _buildPredictionTile(listForPlaces[index]);
                                } else {
                                  // Display saved places
                                  if (data.savedPlaces[index]['address'] == '') return const SizedBox.shrink();
                                  return _buildSavedPlaceTile(data.savedPlaces[index]);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Confirm Button
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (pickup != null && dropOff != null) ? primaryNavy : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: (pickup != null && dropOff != null) ? _onConfirmPressed : null,
                    child: const Text('Confirm Locations', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                  ),
                ),
              )
            ],
          );
        },
        error: (e, stack) => ErrorCatch(error: e.toString()),
        loading: () => const Loading(),
      ),
    );
  }

  // NEW: Widget for the redesigned search input section
  Widget _buildSearchInputSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          // Route line indicator
          Column(
            children: [
              Icon(Icons.circle, color: brightBlue, size: 12),
              Container(
                height: 40,
                width: 2,
                color: Colors.grey[300],
              ),
              const Icon(Icons.location_on, color: Colors.red, size: 16),
            ],
          ),
          const SizedBox(width: 15),
          // TextFields
          Expanded(
            child: Column(
              children: [
                _buildSearchTextField(
                  controller: pickUpController,
                  focusNode: pickUpFocus,
                  hintText: 'Pickup location',
                  isActive: isPickUp,
                  onTap: () {
                    setState(() {
                      isPickUp = true;
                      listForPlaces.clear();
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildSearchTextField(
                  controller: destController,
                  focusNode: destFocus,
                  hintText: 'Drop-off destination',
                  isActive: !isPickUp,
                  onTap: () {
                    setState(() {
                      isPickUp = false;
                      listForPlaces.clear();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Helper for creating a styled search TextField
  Widget _buildSearchTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        FocusScope.of(context).requestFocus(focusNode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? brightBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hintText,
            border: InputBorder.none,
            isDense: true,
          ),
          style: const TextStyle(
              overflow: TextOverflow.ellipsis,
              color: darkGray,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500
          ),
        ),
      ),
    );
  }

  // NEW: Refactored tile for displaying predictions
  Widget _buildPredictionTile(PlacePredictions prediction) {
    return ListTile(
      leading: const Icon(Icons.pin_drop, color: darkGray),
      title: Text(prediction.mainText, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
      subtitle: Text(prediction.secondaryText, style: const TextStyle(fontFamily: 'Montserrat')),
      onTap: () async {
        LatLng? result = await getLatLngFromPlaceId(prediction.placeId);
        if (result != null) {
          controllerGoogleMap?.animateCamera(CameraUpdate.newLatLng(result));
          setState(() {
            if (isPickUp) {
              pickUpController.text = prediction.mainText;
              pickup = result;
            } else {
              destController.text = prediction.mainText;
              dropOff = result;
            }
            listForPlaces.clear();
            FocusScope.of(context).unfocus(); // Hide keyboard
          });
        }
      },
    );
  }

  // NEW: Refactored tile for displaying saved places
  Widget _buildSavedPlaceTile(Map<String, dynamic> place) {
    IconData getIcon(String name) {
      if (name.toLowerCase() == 'home') return Icons.home;
      if (name.toLowerCase() == 'work') return Icons.work;
      return Icons.star;
    }
    return ListTile(
      leading: Icon(getIcon(place['name']), color: darkGray),
      title: Text(place['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
      subtitle: Text(place['address'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Montserrat')),
      onTap: () {
        GeoPoint location = place['location'];
        LatLng latLng = LatLng(location.latitude, location.longitude);
        controllerGoogleMap?.animateCamera(CameraUpdate.newLatLng(latLng));
        setState(() {
          if(isPickUp) {
            pickUpController.text = place['address'];
            pickup = latLng;
          } else {
            destController.text = place['address'];
            dropOff = latLng;
          }
          FocusScope.of(context).unfocus(); // Hide keyboard
        });
      },
    );
  }
}