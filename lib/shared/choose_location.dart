import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pakyaw/pages/account/save_address_page.dart';
import 'package:pakyaw/shared/global_var.dart';
import 'package:pakyaw/shared/size_config.dart';
import 'package:permission_handler/permission_handler.dart';

import '../assistants/request_assistant.dart';

class ChooseLocation extends StatefulWidget {
  String? oldName;
  final String typeOfSavedPlace;
  String? placeId;
  ChooseLocation({super.key, this.oldName, required this.typeOfSavedPlace, this.placeId});

  @override
  State<ChooseLocation> createState() => _ChooseLocationState();
}

class _ChooseLocationState extends State<ChooseLocation> {

  final Completer<GoogleMapController> googleMapController = Completer<GoogleMapController>();
  Position? currentPositionOfUser;
  GoogleMapController? controllerGoogleMap;
  CameraPosition currentPosition = const CameraPosition(
    target: LatLng(11.00639, 124.6075),
    zoom: 19,
  );
  String addressName = "";
  String addressDetails = "";
  late LatLng draggedLocation;
  late LatLng location;
  String placeId = "";
  Timer? _debounce;

  Future<GeoPoint> findLatLong(String placeId) async {

    GeoPoint location = const GeoPoint(0,0);

    String detailsUrl = "https://maps.googleapis.com/maps/api/place/details/json?place_id=${widget.placeId}&fields=name,geometry&key=$googleMapKey";

    var details = await RequestAssistant.getRequest(detailsUrl);

    if(details['status'] == 'OK'){
      Map<String, dynamic> json = details['result'];
      location = GeoPoint(json['geometry']['location']['lat'], json['geometry']['location']['lng']);
    }
    print(location);
    return location;

  }

  getCurrentLiveLocationOfUser() async {
    LatLng positionOfUserInLatLng = const LatLng(0, 0);
    if(widget.placeId == null){
      Position positionOfUser = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      currentPositionOfUser = positionOfUser;

      positionOfUserInLatLng = LatLng(
          currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
      draggedLocation = LatLng(
          currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
      print('This is the placeId: ${widget.placeId}');
    }else{
      GeoPoint location = await findLatLong(widget.placeId!);
      positionOfUserInLatLng = LatLng(
          location.latitude, location.longitude);
      draggedLocation = LatLng(
          location.latitude, location.longitude);
    }

    print('${positionOfUserInLatLng.latitude} - ${positionOfUserInLatLng.longitude}');

    CameraPosition cameraPosition = CameraPosition(
      target: positionOfUserInLatLng,
      zoom: 19,
    );

    controllerGoogleMap!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    getAddress(positionOfUserInLatLng);

  }

  void _onCameraMove(CameraPosition position) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      draggedLocation = position.target;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  getAddress(LatLng position) async {

    final String places = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleMapKey';

     var res = await RequestAssistant.getRequest(places);
     if(res['status'] == 'OK') {
       final result = res['results'][0];
       print(result);
       final newPosition = LatLng(result['geometry']['location']['lat'], result['geometry']['location']['lng']);
       String street = result['address_components'][0]['short_name'];
       String route = result['address_components'][1]['short_name'];
       String neighborhiid = result['address_components'][2]['short_name'];
       if(mounted) {
         setState(() {
         addressName = '$street, $route, $neighborhiid';
         addressDetails = result['formatted_address'];
         placeId = result['place_id'];
       });
       }

       CameraPosition cameraPosition = CameraPosition(
         target: newPosition,
         zoom: 19,
       );

       controllerGoogleMap!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

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
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              mapType: MapType.hybrid,
              initialCameraPosition: currentPosition,
              myLocationEnabled: true,
              onCameraIdle: (){
                getAddress(draggedLocation);
              },
              onCameraMove: _onCameraMove,
              onMapCreated: (GoogleMapController mapController){
                controllerGoogleMap = mapController;
                googleMapController.complete(controllerGoogleMap);

                getCurrentLiveLocationOfUser();
              },

            ),
            Positioned(
              top: 10.0,
              left: 10.0,
              child: GestureDetector(
                onTap: (){
                  Navigator.popUntil(context, ModalRoute.withName('/SavedPlaces'));
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
            const Center(
              child: Icon(Icons.location_pin, color: Colors.red, size: 36),
            ),
            Positioned(
              bottom: SizeConfig.blockSizeVertical *  12,
              left: SizeConfig.blockSizeVertical *  4,
              right: SizeConfig.blockSizeVertical *  4,
              child: Container(
                height: SizeConfig.blockSizeVertical *  9,
                decoration: ShapeDecoration(
                    color: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0)
                    )
                ),
                child: ListTile(
                  leading: const Icon(Icons.circle_outlined),
                  title: Text(
                    addressName,
                    style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 4,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        overflow: TextOverflow.ellipsis
                    ),
                  ),
                  subtitle: Text(
                    addressDetails,
                    style: TextStyle(
                      fontSize: SizeConfig.safeBlockHorizontal * 3,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                      overflow: TextOverflow.ellipsis
                    ),
                  ),
                )
              ),
            ),
            Positioned(
              bottom: SizeConfig.blockSizeVertical *  4,
              left: SizeConfig.blockSizeVertical *  7,
              right: SizeConfig.blockSizeVertical *  7,
              child: Container(
              height: SizeConfig.blockSizeVertical *  7,
              decoration: ShapeDecoration(
                  color: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0)
                  )
              ),
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black
                  ),
                  onPressed: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SaveAddressPage(address: addressName, typeOfSavedPlace: widget.typeOfSavedPlace, placeId: placeId, oldName: widget.oldName,)));
                  },
                  child: Text(
                    'Save Location',
                    style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white
                    ),
                  )
              ),
            ),
            )
          ],
        ),
      ),
    );
  }
}
