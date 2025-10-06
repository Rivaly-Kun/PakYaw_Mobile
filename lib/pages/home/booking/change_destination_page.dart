import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pakyaw/pages/home/booking/confirm_trip_page.dart';
import 'package:pakyaw/pages/home/booking/confirm_vehicletype.dart';
import 'package:pakyaw/pages/home/booking/trip_details.dart';
import 'package:pakyaw/providers/trip_provider.dart';
import 'package:pakyaw/services/database.dart';
import 'package:uuid/uuid.dart';

import '../../../assistants/request_assistant.dart';
import '../../../models/place_predictions.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/error.dart';
import '../../../shared/global_var.dart';
import '../../../shared/loading.dart';
import '../../../shared/size_config.dart';

class ChangeDropOffSelect extends ConsumerStatefulWidget {
  final String tripId;
  const ChangeDropOffSelect({super.key, required this.tripId});

  @override
  ConsumerState<ChangeDropOffSelect> createState() => _ChangeDropOffSelectState();
}

class _ChangeDropOffSelectState extends ConsumerState<ChangeDropOffSelect> {
  DatabaseService databaseService = DatabaseService();

  double _currentHeight = SizeConfig.blockSizeVertical * 76; // Initial height
  double? distance;
  final double _minHeight = SizeConfig.blockSizeVertical * 23;
  final double _maxHeight = SizeConfig.blockSizeVertical * 76;

  int count = 0;


  bool stopCameraLoop = false;
  bool isLoading = false;

  Timer? _debounce;
  List<dynamic> listForPlaces = [];
  List<LatLng>? routePoints;
  String? tokenForSession;


  String? pickUp;
  TextEditingController dest = TextEditingController();

  final Completer<GoogleMapController> googleMapController = Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  CameraPosition currentPosition = const CameraPosition(
    target: LatLng(11.00639, 124.6075),
    zoom: 19,
  );
  late LatLng draggedLocation;
  LatLng? pickup;
  LatLng? dropOff;
  Position? currentPositionOfUser;

  getCurrentLocation() async {
    print('you is working');
    Position positionOfUser = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentPositionOfUser = positionOfUser;

    LatLng positionOfUserInLatLng = LatLng(
        currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
    draggedLocation = positionOfUserInLatLng;

    CameraPosition cameraPosition = CameraPosition(
      target: positionOfUserInLatLng,
      zoom: 19,
    );
    controllerGoogleMap!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    getPickup(positionOfUserInLatLng);
  }

  getAddress(LatLng position) async {
    if(stopCameraLoop) return;
    stopCameraLoop = true;

    final String places = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleMapKey';

    var res = await RequestAssistant.getRequest(places);
    if(res['status'] == 'OK') {
      final result = res['results'][0];
      print(result);
      final newPosition = LatLng(result['geometry']['location']['lat'], result['geometry']['location']['lng']);
      if(mounted) {
        if((_currentHeight == _minHeight)){
          setState(() {
            dest.text = result['formatted_address'];
          });
        }

      }

      CameraPosition cameraPosition = CameraPosition(
        target: newPosition,
        zoom: 19,
      );
      await controllerGoogleMap!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    }else if(res['status'] == 'ZERO_RESULTS'){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No results found. Try again with a different location."))
      );
    }else if(res['status'] == 'INVALID_REQUEST'){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No results found. Invalid Request."))
      );
    }else if(res['status'] == 'OVER_QUERY_LIMIT'){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No results found. Over Query Limit."))
      );
    }else if(res['status'] == 'REQUEST_DENIED'){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request Denied"))
      );
    }else if(res['status'] == 'UNKNOWN_ERROR'){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unknown Error."))
      );
    }

  }

  getPickup(LatLng position) async {
    print('we doing sheyt');
    if(stopCameraLoop) return;
    stopCameraLoop = true;

    final String places = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleMapKey';

    var res = await RequestAssistant.getRequest(places);
    if(res['status'] == 'OK') {
      final result = res['results'][0];
      print(result);
      final newPosition = LatLng(result['geometry']['location']['lat'], result['geometry']['location']['lng']);
      if(mounted) {
        pickUp = result['formatted_address'];
        print(pickUp);
        setState(() {
          pickup = position;
        });
      }

      CameraPosition cameraPosition = CameraPosition(
        target: newPosition,
        zoom: 19,
      );
      await controllerGoogleMap!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    }else if(res['status'] == 'ZERO_RESULTS'){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No results found. Try again with a different location."))
      );
    }else if(res['status'] == 'INVALID_REQUEST'){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No results found. Invalid Request."))
      );
    }else if(res['status'] == 'OVER_QUERY_LIMIT'){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No results found. Over Query Limit."))
      );
    }else if(res['status'] == 'REQUEST_DENIED'){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request Denied"))
      );
    }else if(res['status'] == 'UNKNOWN_ERROR'){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unknown Error."))
      );
    }

  }

  void _onCameraMove(CameraPosition position) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      stopCameraLoop = false;
      draggedLocation = position.target;
      setState(() {
        dropOff = draggedLocation;
      });
    });
  }

  Future<LatLng?> findLatLong(String placeId) async {

    LatLng location = const LatLng(0.0, 0.0);

    String detailsUrl = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,geometry&key=$googleMapKey";

    var details = await RequestAssistant.getRequest(detailsUrl);

    if(details['status'] == 'OK'){
      Map<String, dynamic> json = details['result'];
      location = LatLng(json['geometry']['location']['lat'], json['geometry']['location']['lng']);
      return location;
    }else if(details['status'] == 'ZERO_RESULTS'){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No results found. Try again with a different location."))
      );
      return null;
    }else if(details['status'] == 'INVALID_REQUEST'){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No results found. Invalid Request."))
      );
      return null;
    }else if(details['status'] == 'OVER_QUERY_LIMIT'){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No results found. Over Query Limit."))
      );
      return null;
    }else if(details['status'] == 'REQUEST_DENIED'){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request Denied"))
      );
      return null;
    }else if(details['status'] == 'UNKNOWN_ERROR'){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unknown Error."))
      );
      return null;
    }
    return null;
  }

  showWarning(BuildContext context1){
    SizeConfig().init(context1);
    showDialog(context: context, builder: (context) => AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(Icons.warning_outlined,color: Colors.yellow, size: SizeConfig.safeBlockHorizontal * 8,),
            ),
            Center(
              child: Text(
                'Warning',
                style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 5,
                    color: Colors.black,
                    fontWeight: FontWeight.bold
                ),
              ),
            ),
            Center(
              child: Text(
                'The trip might not be necessary, since the locations are identical',
                style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 3.7,
                    color: Colors.black,
                    fontWeight: FontWeight.w400
                ),
              ),
            )
          ],
        ),
      ),
    ));
  }
  showWarning2(BuildContext context1){
    SizeConfig().init(context1);
    showDialog(context: context, builder: (context) => AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(Icons.warning_outlined,color: Colors.yellow, size: SizeConfig.safeBlockHorizontal * 8,),
            ),
            Center(
              child: Text(
                'Warning',
                style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 5,
                    color: Colors.black,
                    fontWeight: FontWeight.bold
                ),
              ),
            ),
            Center(
              child: Text(
                'Fields are empty, please select a location.',
                style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 3.7,
                    color: Colors.black,
                    fontWeight: FontWeight.w400
                ),
              ),
            )
          ],
        ),
      ),
    ));
  }

  void findPlaces(String placeName) async {
    if(placeName.length > 2){
      String autoCompleteUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&location=11.0384%2C124.6105&radius=14000&strictbounds=true&key=$googleMapKey&sessiontoken=$tokenForSession";

      var res = await RequestAssistant.getRequest(autoCompleteUrl);

      if(res == "Failed"){
        setState(() {
          isLoading = false;
        });
        return;
      }

      if(res['status'] == 'OK'){
        var predictions = res['predictions'];

        var placeList = (predictions as List).map((e) => PlacePredictions.fromJson(e)).toList();
        setState(() {
          listForPlaces = placeList;
          isLoading = false;
        });
      }else if(res['status'] == 'ZERO_RESULTS'){
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No results found. Try again with a different location."))
        );
      }else if(res['status'] == 'INVALID_REQUEST'){
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No results found. Invalid Request."))
        );
      }else if(res['status'] == 'OVER_QUERY_LIMIT'){
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No results found. Over Query Limit."))
        );
      }else if(res['status'] == 'REQUEST_DENIED'){
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Request Denied"))
        );
      }else if(res['status'] == 'UNKNOWN_ERROR'){
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Unknown Error."))
        );
      }
    }
  }

  void _onDestSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (dest.text.length >= 2) {
        setState(() {
          isLoading = true;
          listForPlaces.clear();
        });
        findPlaces(dest.text);
      } else {
        setState(() {
          listForPlaces.clear();
          isLoading = false;
        });

      }
    });
  }

  getRouteInfo(LatLng origin, LatLng destination, String travelMode) async {
    const String url = 'https://routes.googleapis.com/directions/v2:computeRoutes';
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': googleMapKey,
      'X-Goog-FieldMask': 'routes.distanceMeters,routes.polyline.encodedPolyline',
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
      routePoints = decodePolyline(route['polyline']['encodedPolyline']);

    }else{
      throw Exception('Failed to get route information: $response');
    }

  }

  List<LatLng> decodePolyline(String encoded) {
    List<PointLatLng> points = PolylinePoints().decodePolyline(encoded);
    return points.map((point) => LatLng(point.latitude, point.longitude)).toList();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    tokenForSession ??= const Uuid().v4();
    dest.addListener(_onDestSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getCurrentLocation();
    });

  }
  @override
  void dispose() {
    // TODO: implement dispose
    _debounce?.cancel();
    dest.removeListener(_onDestSearchChanged);
    dest.dispose();
    tokenForSession = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final userAuth = ref.watch(authStateProvider).value;
    final user = ref.watch(usersProvider);
    final trip = ref.read(tripProvider);
    return user.when(
      data: (data){
        if(data != null){
          final savedPlaces = data.savedPlaces;
          return Scaffold(
              resizeToAvoidBottomInset: false,
              body: SafeArea(
                child: Stack(
                  children: [
                    GoogleMap(
                      mapType: MapType.normal,
                      initialCameraPosition: currentPosition,
                      myLocationEnabled: true,
                      onCameraIdle: (){
                        if(!stopCameraLoop){
                          getAddress(draggedLocation);
                        }
                      },
                      onCameraMove: _onCameraMove,
                      onMapCreated: (GoogleMapController mapController){
                        controllerGoogleMap = mapController;
                        googleMapController.complete(controllerGoogleMap);

                        getCurrentLocation();
                      },
                    ),
                    const Center(
                      child: Icon(Icons.location_pin, color: Colors.red, size: 36),
                    ),
                    Positioned(
                      top: 10.0,
                      left: 10.0,
                      child: GestureDetector(
                        onTap: (){
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(22.0),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.white,
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
                            backgroundColor: Colors.black,
                            child: Icon(Icons.arrow_back, color: Colors.white,),
                          ),
                        ),
                      ),

                    ),
                    Positioned(
                      bottom: SizeConfig.blockSizeVertical * 13,
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
                                height: SizeConfig.blockSizeVertical * 5,
                                child: Center(
                                  child: Container(
                                    width: SizeConfig.blockSizeHorizontal * 15,
                                    height: SizeConfig.blockSizeVertical,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  const SizedBox(width: 20.0,),
                                  const Icon(Icons.pin_drop, size: 25.0,),
                                  const SizedBox(width: 18.0,),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Colors.grey[350],
                                          borderRadius: BorderRadius.circular(5)
                                      ),
                                      child: TextField(
                                        controller: dest,
                                        decoration: const InputDecoration(
                                          hintText: 'dropoff address',
                                          fillColor: Colors.white12,
                                          filled: true,
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.only(left: 11, top: 9, bottom: 9),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 40.0,)

                                ],
                              ),
                              const SizedBox(height: 20.0,),
                              const Padding(padding: EdgeInsets.symmetric(horizontal: 10.0), child: Divider(height: 10.0,),),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      savedPlaces[0]['address'] != '' ? Container(
                                        margin: EdgeInsets.symmetric(horizontal: SizeConfig.blockSizeHorizontal * 2.7),
                                        decoration: BoxDecoration(
                                            border: Border(
                                                bottom: BorderSide(
                                                    color: Colors.grey.shade400,
                                                    width: 1.0
                                                )
                                            )
                                        ),
                                        child: ListTile(
                                          onTap: (){
                                            setState(() {
                                              dest.text = savedPlaces[0]['address'];
                                              GeoPoint temp = savedPlaces[0]['location'];
                                              print(temp);
                                              dropOff = LatLng(temp.latitude, temp.longitude);
                                            });
                                          },
                                          leading: const Icon(Icons.home),
                                          title: Text(
                                            'Home',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: SizeConfig.safeBlockHorizontal * 4
                                            ),
                                          ),
                                          shape: const Border(
                                              bottom: BorderSide(
                                                  color: Colors.black,
                                                  width: 2.0
                                              )
                                          ),
                                          subtitle: Text(
                                            savedPlaces[0]['address'],
                                            style: TextStyle(
                                                fontSize: SizeConfig.safeBlockHorizontal * 3.7,
                                                color: Colors.black,
                                                overflow: TextOverflow.ellipsis
                                            ),
                                          ),
                                        ),
                                      ) : Container(),
                                      savedPlaces[1]['address'] != '' ? Container(
                                        margin: EdgeInsets.symmetric(horizontal: SizeConfig.blockSizeHorizontal * 2.7),
                                        decoration: BoxDecoration(
                                          border: Border(
                                              bottom: BorderSide(
                                                  color: Colors.grey.shade400,
                                                  width: 1.0
                                              )
                                          ),
                                        ),
                                        child: ListTile(
                                          onTap: (){
                                            setState(() {
                                              dest.text = savedPlaces[1]['address'];
                                              GeoPoint temp = savedPlaces[1]['location'];
                                              print(temp.latitude);
                                              print(temp.longitude);
                                              dropOff = LatLng(temp.latitude, temp.longitude);
                                            });
                                          },
                                          leading: const Icon(Icons.luggage),
                                          title: Text(
                                            'Work',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: SizeConfig.safeBlockHorizontal * 4
                                            ),
                                          ),
                                          subtitle: Text(
                                            savedPlaces[1]['address'],
                                            style: TextStyle(
                                                fontSize: SizeConfig.safeBlockHorizontal * 3.7,
                                                color: Colors.black,
                                                overflow: TextOverflow.ellipsis
                                            ),
                                          ),
                                        ),
                                      ) : Container(),
                                      (savedPlaces.length > 2) ? ListView.separated(
                                        padding: const EdgeInsets.all(0.0),
                                        itemBuilder: (context, index){
                                          return Container(
                                            margin: EdgeInsets.symmetric(horizontal: SizeConfig.blockSizeHorizontal * 2.7),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                  bottom: BorderSide(
                                                      color: Colors.grey.shade400,
                                                      width: 1.0
                                                  )
                                              ),
                                            ),
                                            child: ListTile(
                                              onTap: (){
                                                setState(() {
                                                  dest.text = savedPlaces[index + 2]['address'];
                                                  GeoPoint temp = savedPlaces[index + 2]['location'];
                                                  print(temp.latitude);
                                                  print(temp.longitude);
                                                  dropOff = LatLng(temp.latitude, temp.longitude);
                                                });
                                              },
                                              leading: const Icon(Icons.place),
                                              title: Text(
                                                savedPlaces[index + 2]['name'],
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: SizeConfig.safeBlockHorizontal * 3.7
                                                ),
                                              ),
                                              subtitle: Text(
                                                savedPlaces[index + 2]['address'],
                                                style: TextStyle(
                                                    fontSize: SizeConfig.safeBlockHorizontal * 3.7,
                                                    color: Colors.black,
                                                    overflow: TextOverflow.ellipsis
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        separatorBuilder: (BuildContext context, int index) => const Divider(),
                                        itemCount: savedPlaces.length - 2,
                                        shrinkWrap: true,
                                        physics: const ClampingScrollPhysics(),
                                      ) : Container(),
                                      Container(
                                        padding: EdgeInsets.symmetric(vertical: SizeConfig.blockSizeVertical * 2, horizontal: SizeConfig.blockSizeHorizontal),
                                        color: Colors.white,
                                        child: ListView.separated(
                                          padding: const EdgeInsets.all(0.0),
                                          itemBuilder: (context, index){
                                            return GestureDetector(
                                              onTap: () async {
                                                PlacePredictions prediction = listForPlaces[index];
                                                LatLng? result = await findLatLong(prediction.placeId);
                                                if(result != null) {
                                                  setState(() {
                                                    dest.text = prediction.mainText;
                                                    dropOff = result;
                                                  });
                                                }
                                              },
                                              child: PredictionTiles(placePrediction: listForPlaces[index]),

                                            );

                                          },
                                          separatorBuilder: (BuildContext context, int index) => const Divider(),
                                          itemCount: listForPlaces.length,
                                          shrinkWrap: true,
                                          physics: const ClampingScrollPhysics(),

                                        ),
                                      )
                                    ],
                                  ),
                                ),

                              ),

                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        width: double.infinity,
                        height: SizeConfig.blockSizeVertical * 13,
                        color: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: SizeConfig.blockSizeHorizontal * 5, vertical: SizeConfig.blockSizeVertical * 3),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            disabledBackgroundColor: Colors.grey[800]
                          ),
                          onPressed: pickup != null && dropOff != null? ()  async{
                            double amount = 0.0;
                            if(pickUp == dest.text && count == 0 && (pickUp!.isNotEmpty && dest.text.isNotEmpty)){
                              showWarning(context);
                              count++;
                            }else{
                              if(pickUp!.isNotEmpty && dest.text.isNotEmpty){
                                await getRouteInfo(pickup!, dropOff!, trip.travelMode!);
                                final pickupLoc = GeoFirePoint(GeoPoint(pickup!.latitude, pickup!.longitude));
                                final dropOffLoc = GeoFirePoint(GeoPoint(dropOff!.latitude, dropOff!.longitude));
                                amount = distance! * trip.ratePerKm!;
                                bool result = databaseService.changeDropOff(widget.tripId, pickUp!, dest.text, dropOffLoc, pickupLoc, routePoints!, amount, distance ?? 0);
                                if(result){
                                  Navigator.pop(context);
                                }
                              }else{
                                showWarning2(context);
                              }
                            }
                          } : null,
                          child: Text('Confirm', style: TextStyle(color: Colors.white ,fontSize: SizeConfig.safeBlockHorizontal * 7, fontWeight: FontWeight.bold),),
                        ),
                      ),
                    )
                  ],
                ),
              )
          );
        }else{
          return const Loading();
        }
      },
      error: (e, stack) => ErrorCatch(error: e.toString()),
      loading: () => const Loading(),

    );
  }
}

class PredictionTiles extends StatelessWidget {

  final PlacePredictions placePrediction;

  const PredictionTiles({super.key, required this.placePrediction});

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Container(
      child: Column(
        children: [
          SizedBox(width: SizeConfig.blockSizeHorizontal * 3,),
          Row(
            children: [
              const Icon(Icons.add_location),
              SizedBox(width: SizeConfig.blockSizeHorizontal * 2,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: SizeConfig.blockSizeVertical,),
                    Text(
                      placePrediction.mainText,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 4.5
                      ),
                    ),
                    SizedBox(height: SizeConfig.blockSizeVertical,),
                    Text(
                      placePrediction.secondaryText,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 4,
                          color: Colors.grey
                      ),
                    ),
                    SizedBox(height: SizeConfig.blockSizeVertical,),

                  ],
                ),
              )
            ],
          ),
          SizedBox(width: SizeConfig.blockSizeHorizontal * 3,),
        ],
      ),
    );
  }
}
