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

class _ConfirmVehicletypeState extends ConsumerState<ConfirmVehicletype> {

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
                'Select a vehicle type',
                style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 4,
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    ref.read(tripProvider.notifier).printTripDetails();
    final user = ref.read(authStateProvider).value;
    id = user!.uid;
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

  @override
  Widget build(BuildContext context) {
    final vehicleTypes = ref.watch(vehicleTypesProvider);
    final maxCapacity = ref.watch(maxCapacityProvider);
    final trip = ref.watch(tripProvider);
    return vehicleTypes.when(
      data: (data) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Vehicle Type',
              style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.black
              ),
            ),
          ),
          body: Column(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10.0,),
                      const Center(
                        child: Text(
                          'How many are riding?',
                          style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.w500,
                              color: Colors.black
                          ),
                        ),
                      ),
                      maxCapacity.when(
                        data: (data){
                          return Center(
                            child: SizedBox(
                              width: SizeConfig.blockSizeHorizontal * 20,
                              child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(color: Colors.black, width: 3.0),
                                    color: Colors.white
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                                  child: DropdownButton(
                                    menuMaxHeight: 200.0,
                                    underline: Container(),
                                    elevation: 0,
                                    onChanged: (int? value){
                                      setState(() {
                                        selectedCapacity = value;
                                      });
                                    },
                                    isExpanded: true,
                                    alignment: Alignment.bottomCenter,
                                    value: selectedCapacity,
                                    icon: const Icon(Icons.keyboard_arrow_down),
                                    //this is where I want to get the max capacity
                                    items: List<int>.generate(data.capacity,
                                            (int index) => index + 1).map(
                                          (val) {
                                        return DropdownMenuItem<int>(
                                          value: val,
                                          child: Text('$val'),
                                        );
                                      },
                                    ).toList(),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        error: (e, error) => Text('Error: $e'),
                        loading: () => const Loading(),
                  
                      ),
                      const SizedBox(height: 50.0,),
                      Expanded(
                        child: Container(
                          width: SizeConfig.screenWidth,
                          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: Colors.white,
                          ),
                  
                          child: Column(
                            children: [
                              Text(
                                error1,
                                style: TextStyle(
                                  fontSize: SizeConfig.safeBlockHorizontal * 3,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                              Expanded(
                                child: GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 10.0,
                                    mainAxisSpacing: 10.0,
                                  ),
                                  itemCount: data.length,
                                  itemBuilder: (context, index) {
                                    if(selectedCapacity! <= data[index].capacity){
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedIndex = index;
                                            selectedVehicle = data[index].type;
                                            baseRate = data[index].baseRate;
                                            ratePerKm = data[index].ratePerKm;
                                            typeImage = data[index].image;
                                            wheels = data[index].wheels;
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: selectedIndex == index ? Colors.grey[350] : Colors.white,
                                            border: Border.all(
                                              color: selectedIndex == index ? Colors.black : Colors.black,
                                              width: 3.0,
                                            ),
                                            borderRadius: BorderRadius.circular(10.0),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: <Widget>[
                                              Image(
                                                image: NetworkImage(data[index].image),
                                                height: 50.0,
                                                width: 50.0,
                                                fit: BoxFit.contain,
                                              ),
                                              const SizedBox(height: 10.0,),
                                              Text(
                                                data[index].type,
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }else{
                                      if(selectedVehicle == data[index].type){
                                        selectedVehicle = null;
                                      }
                                      return GestureDetector(
                                        onTap: () {
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            border: Border.all(
                                              color: Colors.black54,
                                              width: 3.0,
                                            ),
                                            borderRadius: BorderRadius.circular(10.0),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: <Widget>[
                                              Image(
                                                image: NetworkImage(data[index].image),
                                                height: SizeConfig.blockSizeVertical * 7,
                                                width: SizeConfig.blockSizeHorizontal * 10,
                                                color: Colors.black54,
                                                fit: BoxFit.contain,
                                              ),
                                              const SizedBox(height: 10.0,),
                                              Text(
                                                data[index].type,
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 15.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(22.0),
                  child: SizedBox(
                    height: SizeConfig.blockSizeVertical * 8,
                    width: SizeConfig.screenWidth,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black
                      ),
                      onPressed: () async {
                        double vatTax = await database.getVatTax();
                        double ccTax = await database.getCCTax();
                        double fare = 0;
                        double basekm = await database.getBaseKm();
                        double charge = await database.getPassengerCharge(id);

                        if(wheels! <= 3){
                          print('TWO_WHEELER');
                          await getRouteInfo(LatLng(trip.pickupLoc!.latitude, trip.pickupLoc!.longitude),
                             LatLng(trip.dropOffLoc!.latitude, trip.dropOffLoc!.longitude), 'TWO_WHEELER');
                          ref.read(tripProvider.notifier).updateTrip((trip) => trip.copyWith(travelMode: 'TWO_WHEELER'));
                          print('result of fare: ${distance! < basekm}');
                          if(distance! < basekm){
                            fare = baseRate!.toDouble();
                          }else{
                            fare = baseRate! + ((distance! - 1) * ratePerKm!);
                          }
                        }else{
                          print('Drive');
                          await getRouteInfo(LatLng(trip.pickupLoc!.latitude, trip.pickupLoc!.longitude),
                              LatLng(trip.dropOffLoc!.latitude, trip.dropOffLoc!.longitude), 'DRIVE');
                          ref.read(tripProvider.notifier).updateTrip((trip) => trip.copyWith(travelMode: 'DRIVE'));
                          print('result of fare: ${distance! < basekm}');
                          if(distance! < basekm){
                            fare = baseRate!.toDouble();
                          }else{
                            fare = baseRate! + ((distance! - 1) * ratePerKm!);
                          }
                        }
                        if(selectedVehicle != null) {
                          ref.read(tripProvider.notifier).updateTrip((trip) =>  trip.copyWith(
                            vehicleType: selectedVehicle,
                            baseRate: baseRate,
                            ratePerKm: ratePerKm,
                            vehicleTypeImage: typeImage,
                            duration: duration,
                            route: routePoints,
                            distance: distance,
                            vatTax: vatTax,
                            ccTax: ccTax,
                            fare: double.parse((fare + charge).toStringAsFixed(2)),
                          ));
                          Navigator.push(context, MaterialPageRoute(
                              builder: (context) => ConfirmTripPage()));
                        }else{
                          showWarning(context);
                        }
                      },
                      child: Text('Confirm', style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 7, fontWeight: FontWeight.bold, color: Colors.white),),

                    ),
                  ),
                ),
              ]
          ),
        );
      },
      error: (e, stack) {
        print(e.toString());
        print(stack.toString());
        return ErrorCatch(error: e.toString());
      },
      loading: () => const Loading(),

    );
  }
}
