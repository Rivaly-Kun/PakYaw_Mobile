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
import 'package:pakyaw/pages/home/booking/confirm_trip_page.dart';
import 'package:pakyaw/pages/home/booking/confirm_vehicletype.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/providers/history_trip_provider.dart';
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
  const DropOffSelect({super.key});

  @override
  ConsumerState<DropOffSelect> createState() => _DropOffSelectState();
}

class _DropOffSelectState extends ConsumerState<DropOffSelect> {

  double _currentHeight = SizeConfig.blockSizeVertical * 76; // Initial height
  final double _minHeight = SizeConfig.blockSizeVertical * 23;
  final double _maxHeight = SizeConfig.blockSizeVertical * 76;

  int count = 0;

  bool stopCameraLoop = false;

  TextEditingController pickUp = TextEditingController();
  TextEditingController dest = TextEditingController();



  final Completer<GoogleMapController> googleMapController = Completer<GoogleMapController>();
  Position? currentPositionOfUser;
  GoogleMapController? controllerGoogleMap;
  CameraPosition currentPosition = const CameraPosition(
    target: LatLng(11.00639, 124.6075),
    zoom: 19,
  );
  LatLng? draggedLocation;
  LatLng? pickup;
  LatLng? dropOff;
  String? tokenForSession;
  Timer? _debounce;
  bool isLoading = false;

  bool isPickUp = true;
  List<dynamic> listForPlaces = [];

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

  void _onPickUpSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (pickUp.text.length >= 2) {
        setState(() {
          isLoading = true;
          listForPlaces.clear();
        });
        findPlaces(pickUp.text);
      } else {
        setState(() {
          listForPlaces.clear();
          isLoading = false;
        });

      }
    });
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

  Future<void> getCurrentLocation() async {
    print('Some thing happening?');
    print('heydude3?');
    Position positionOfUser = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    print('heydude4?');
    currentPositionOfUser = positionOfUser;
    print('heydude2?');
    LatLng positionOfUserInLatLng = LatLng(
        currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
    draggedLocation = positionOfUserInLatLng;

    CameraPosition cameraPosition = CameraPosition(
      target: positionOfUserInLatLng,
      zoom: 19,
    );
    controllerGoogleMap!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    print('heydude?');
    getAddress(positionOfUserInLatLng);
  }

  // getAddress(LatLng position) async {
  //
  //   final String places = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleMapKey';
  //
  //   var res = await RequestAssistant.getRequest(places);
  //   if(res['status'] == 'OK') {
  //     final result = res['results'][0];
  //     if(mounted) {
  //       setState(() {
  //         pickUp.text = result['formatted_address'];
  //       });
  //     }
  //
  //   }else if(res['status'] == 'ZERO_RESULTS'){
  //     print('Zero_results');
  //   }else if(res['status'] == 'INVALID_REQUEST'){
  //     print('INVALID_REQUEST');
  //   }else if(res['status'] == 'OVER_QUERY_LIMIT'){
  //     print('OVER_QUERY_LIMIT');
  //   }else if(res['status'] == 'REQUEST_DENIED'){
  //     print('REQUEST_DENIED');
  //   }else if(res['status'] == 'UNKNOWN_ERROR'){
  //     print('UNKNOWN_ERROR');
  //   }
  // }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      getCurrentLocation();
    });
    tokenForSession ??= const Uuid().v4();
    pickUp.addListener((){
      setState(() {
        isPickUp = true;
        listForPlaces.clear();
      });
      _onPickUpSearchChanged();
    });
    dest.addListener((){
      setState(() {
        isPickUp = false;
        listForPlaces.clear();
      });
      _onDestSearchChanged();
    });
  }

  void _onCameraMove(CameraPosition position) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      stopCameraLoop = false;
      draggedLocation = position.target;
      if(isPickUp){
        setState(() {
          pickup = draggedLocation;
        });
      }else{
        setState(() {
          dropOff = draggedLocation;
        });
      }
    });
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

  getAddress(LatLng position) async {
    print('didSomething happen?');
    if(stopCameraLoop) return;
    print('yesss?');
    stopCameraLoop = true;

    final String places = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleMapKey';

    var res = await RequestAssistant.getRequest(places);
    if(res['status'] == 'OK') {
      final result = res['results'][0];
      print(result);
      final newPosition = LatLng(result['geometry']['location']['lat'], result['geometry']['location']['lng']);
      if(mounted) {
        if(isPickUp){
          setState(() {
            pickUp.text = result['formatted_address'];
          });
        }else if((_currentHeight == _minHeight)){
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

  @override
  void dispose() {
    // TODO: implement dispose
    _debounce?.cancel();
    pickUp.removeListener(_onPickUpSearchChanged);
    dest.removeListener(_onDestSearchChanged);
    pickUp.dispose();
    dest.dispose();
    tokenForSession = null;
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final userAuth = ref.watch(authStateProvider).value;
    final user = ref.watch(usersProvider);
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
                      onCameraMove: _onCameraMove,
                      onMapCreated: (GoogleMapController mapController){
                        controllerGoogleMap = mapController;
                        googleMapController.complete(controllerGoogleMap);

                        getCurrentLocation();
                      },
                      onCameraIdle: (){
                        if(!stopCameraLoop){
                          if(draggedLocation != null){
                            getAddress(draggedLocation!);
                          }

                        }
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
                                  const Icon(Icons.trip_origin, size: 25.0,),
                                  const SizedBox(width: 18.0,),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Colors.grey[350],
                                          borderRadius: BorderRadius.circular(5)
                                      ),
                                      child: TextField(
                                        controller: pickUp,
                                        decoration: const InputDecoration(
                                          hintText: 'pickup address',
                                          fillColor: Colors.white12,
                                          filled: true,
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.only(left: 11, top: 9, bottom: 9),
                                        ),
                                        style: const TextStyle(
                                            overflow: TextOverflow.ellipsis,
                                            color: Colors.black
                                        ),
                                      ),
                                    ),

                                  ),
                                  const SizedBox(width: 40.0,)

                                ],
                              ),
                              const SizedBox(height: 11.0,),
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
                                            if(isPickUp){
                                              setState(() {
                                                pickUp.text = savedPlaces[0]['address'];
                                                GeoPoint temp = savedPlaces[0]['location'];
                                                print(temp);
                                                pickup = LatLng(temp.latitude, temp.longitude);
                                              });
                                            }else{
                                              setState(() {
                                                dest.text = savedPlaces[0]['address'];
                                                GeoPoint temp = savedPlaces[0]['location'];
                                                print(temp);
                                                dropOff = LatLng(temp.latitude, temp.longitude);
                                              });
                                            }
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
                                            if(isPickUp){
                                              setState(() {
                                                pickUp.text = savedPlaces[1]['address'];
                                                GeoPoint temp = savedPlaces[1]['location'];
                                                print(temp.latitude);
                                                print(temp.longitude);
                                                pickup = LatLng(temp.latitude, temp.longitude);
                                              });
                                            }else{
                                              setState(() {
                                                dest.text = savedPlaces[1]['address'];
                                                GeoPoint temp = savedPlaces[1]['location'];
                                                print(temp.latitude);
                                                print(temp.longitude);
                                                dropOff = LatLng(temp.latitude, temp.longitude);
                                              });
                                            }
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
                                                if(isPickUp){
                                                  setState(() {
                                                    pickUp.text = savedPlaces[index + 2]['address'];
                                                    GeoPoint temp = savedPlaces[index + 2]['location'];
                                                    print(temp.latitude);
                                                    print(temp.longitude);
                                                    pickup = LatLng(temp.latitude, temp.longitude);
                                                  });
                                                }else{
                                                  setState(() {
                                                    dest.text = savedPlaces[index + 2]['address'];
                                                    GeoPoint temp = savedPlaces[index + 2]['location'];
                                                    print(temp.latitude);
                                                    print(temp.longitude);
                                                    dropOff = LatLng(temp.latitude, temp.longitude);
                                                  });
                                                }
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
                                            print('pick Up: $isPickUp');
                                            if(isPickUp){
                                              return GestureDetector(
                                                onTap: () async {
                                                  PlacePredictions prediction = listForPlaces[index];
                                                  LatLng? result = await findLatLong(prediction.placeId);
                                                  if(result != null){
                                                    setState(() {
                                                      pickUp.text = prediction.mainText;
                                                      pickup = result;
                                                    });
                                                  }
                                                },
                                                child: PredictionTiles(placePrediction: listForPlaces[index]),

                                              );
                                            }else{
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
                                            }

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
                          ),
                          onPressed: () async {
                            DatabaseService database = DatabaseService();
                            double appChargeValue = await database.getAppCharge();
                            if(pickUp.text == dest.text && count == 0 && (pickUp.text.isNotEmpty && dest.text.isNotEmpty)){
                              showWarning(context);
                              count++;
                            }else{
                              if(pickUp.text.isNotEmpty && dest.text.isNotEmpty){
                                Navigator.push(context, MaterialPageRoute(
                                    builder: (context) => ConfirmVehicletype()));
                              }else{
                                showWarning2(context);
                              }
                            }
                            Map<String, dynamic> passenger = {
                              'passenger_id': userAuth!.uid,
                              'passenger_name': data.name,
                              'passenger_profile': data.profilePicPath,
                              'rating': (data.totalRating / data.ratingCount)
                            };
                            final pickupLoc = GeoFirePoint(GeoPoint(pickup!.latitude, pickup!.longitude));
                            final dropOffLoc = GeoFirePoint(GeoPoint(dropOff!.latitude, dropOff!.longitude));
                            ref.read(tripProvider.notifier).updateTrip((trip) => trip.copyWith(
                              pickup: pickUp.text,
                              pickupLoc: pickupLoc,
                              dropOff: dest.text,
                              dropOffLoc: dropOffLoc,
                              rider: passenger,
                              appCharge: appChargeValue
                            ));
                          },
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
