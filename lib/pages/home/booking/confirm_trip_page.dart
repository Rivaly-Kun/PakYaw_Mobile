import 'dart:async';
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
class ExampleModel{
  final String description;
  final double discount;
  final String discountName;

  ExampleModel({
    required this.description,
    required this.discount,
    required this.discountName,
  });

  factory ExampleModel.fromDocument(String name, double discount, String des){
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

class _ConfirmTripPageState extends ConsumerState<ConfirmTripPage> {
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

  setPaymentMethod(value, value2){
    setState(() {
      paymentMethod = value;
      accountNum = value2;
    });
  }
  setPromos(value3, value2){
    setState(() {
      discount = value3;
      promosDisplay = '${(discount * 100)}%';
      promoName = value2;
    });
  }
  setDiscount(value3, value2){
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
      color: Colors.black,
      points: coordinates,
      width: 4
    );
    setState(() {
      polyLines[polylineId] = polyline;
    });
    fitPolylineToMap(coordinates);
  }

  showPaymentMethods(){
    showFlexibleBottomSheet(context: context, builder: _buildBottomSheet,
    minHeight: 0,
      initHeight: 1,
      maxHeight: 1,
      anchors: [0, 0.5, 1],
      isSafeArea: true,
    );
  }
  showPromos(){
    showFlexibleBottomSheet(context: context, builder: _buildBottomSheet2,
      minHeight: 0,
      initHeight: 1,
      maxHeight: 1,
      anchors: [0, 0.5, 1],
      isSafeArea: true,
    );
  }
  showDiscount(){
    showFlexibleBottomSheet(context: context, builder: _buildBottomSheet3,
      minHeight: 0,
      initHeight: 1,
      maxHeight: 1,
      anchors: [0, 0.5, 1],
      isSafeArea: true,
    );
  }

  void showNotePanel(String name){
    showModalBottomSheet(context: context, builder: (context){
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 60.0),
        child: Note(name: name),
      );
    });
  }

  Widget _buildBottomSheet2(BuildContext context, ScrollController scrollController,
      double bottomSheet){
    SizeConfig().init(context);

    return Padding(
      padding: EdgeInsets.only(top: SizeConfig.blockSizeHorizontal * 10),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: SizeConfig.safeBlockHorizontal * 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Promos',
              style: TextStyle(
                  fontSize: SizeConfig.safeBlockHorizontal * 6,
                  color: Colors.black,
                  fontWeight: FontWeight.w500
              ),
            ),
            SizedBox(height: SizeConfig.blockSizeVertical * 2,),
            Expanded(child: Promos(discount: setPromos, vehicleType: vehicleType,))
          ],
        ),
      )
    );
  }

  Widget _buildBottomSheet3(BuildContext context, ScrollController scrollController,
      double bottomSheet){
    SizeConfig().init(context);
    return Padding(
        padding: EdgeInsets.only(top: SizeConfig.blockSizeHorizontal * 10),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: SizeConfig.safeBlockHorizontal * 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discount',
                style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 6,
                    color: Colors.black,
                    fontWeight: FontWeight.w500
                ),
              ),
              SizedBox(height: SizeConfig.blockSizeVertical * 2,),
              Expanded(child: Discount(discount: setDiscount))
            ],
          ),
        )
    );
  }

  Widget _buildBottomSheet(BuildContext context, ScrollController scrollController,
      double bottomSheet){
    return ListView(
      controller: scrollController,
      children: [
        PaymentWay(paymentMethod: setPaymentMethod)
      ],
    );
  }

  void autoSelectSpecialDiscount(String userId, double fare) async {
    final user = await database.getCurrentUser(userId);

    // List to store available discounts
    List<Map<double, dynamic>> availableDiscounts = [];

    // Check and add available discounts based on user's properties
    if (user.student != null) {
      final studentDiscount = await database.getStudentDiscount();
      Map<double, Map<String, dynamic>> model = {};
      double disc = studentDiscount.discount;
      double peso = studentDiscount.peso;
      double tempDisc = 0.0;
      if(peso != 0){
        tempDisc = fare - peso;
        model[tempDisc] = {
          'discountName': studentDiscount.discountName,
          'discount': studentDiscount.discount,
          'peso': studentDiscount.peso,
          'description': studentDiscount.description,
        };
      }else if(disc != 0){
        tempDisc = fare - (fare * disc);
        model[tempDisc] = {
          'discountName': studentDiscount.discountName,
          'discount': studentDiscount.discount,
          'peso': studentDiscount.peso,
          'description': studentDiscount.description,
        };
      }

      availableDiscounts.add(model);
    }

    if (user.pwd != null) {
      final pwdDiscount = await database.getPWDDiscount();
      Map<double, Map<String, dynamic>> model = {};
      double disc = pwdDiscount.discount;
      double peso = pwdDiscount.peso;
      double tempDisc = 0.0;
      if(peso != 0){
        tempDisc = fare - peso;
        model[tempDisc] = {
          'discountName': pwdDiscount.discountName,
          'discount': pwdDiscount.discount,
          'peso': pwdDiscount.peso,
          'description': pwdDiscount.description,
        };
      }else if(disc != 0){
        tempDisc = fare - (fare * disc);
        model[tempDisc] = {
          'discountName': pwdDiscount.discountName,
          'discount': pwdDiscount.discount,
          'peso': pwdDiscount.peso,
          'description': pwdDiscount.description,
        };
      }
      availableDiscounts.add(model);
    }

    if (user.senior != null) {
      final seniorDiscount = await database.getSeniorDiscount();
      Map<double, Map<String, dynamic>> model = {};
      double disc = seniorDiscount.discount;
      double peso = seniorDiscount.peso;
      double tempDisc = 0.0;
      if(peso != 0){
        tempDisc = fare - peso;
        model[tempDisc] = {
          'discountName': seniorDiscount.discountName,
          'discount': seniorDiscount.discount,
          'peso': seniorDiscount.peso,
          'description': seniorDiscount.description,
        };
      }else if(disc != 0){
        tempDisc = fare - (fare * disc);
        model[tempDisc] = {
          'discountName': seniorDiscount.discountName,
          'discount': seniorDiscount.discount,
          'peso': seniorDiscount.peso,
          'description': seniorDiscount.description,
        };
      }
      availableDiscounts.add(model);
    }

    // Select the highest discount if any discounts are available
    if (availableDiscounts.isNotEmpty) {
      Map<double, dynamic> finalDiscount = availableDiscounts.reduce((current, next) =>
      current.keys.first > next.keys.first ? current : next
      );
      var temp = finalDiscount[finalDiscount.keys.first];
      setState(() {
        discountName = temp['discountName'];
        discount2 = temp['discount'];
        peso = temp['peso'];
        discountDisplay = temp['discountName'];
      });

    } else {
      // No discounts available, reset or handle accordingly
      discountName = '';
      discount2 = 0.0;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    ref.read(tripProvider.notifier).printTripDetails();
    final trip = ref.read(tripProvider);
    vehicleType = trip.vehicleType!;
    if (trip.route != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        getPolylineFromPoints(trip.route!);
      });
    }
    final user = ref.read(authStateProvider).value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      double fare = trip.fare! + (trip.fare! * trip.ccTax!) + (trip.fare! * trip.vatTax!);
      autoSelectSpecialDiscount(user!.uid, fare);
    });

  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    final trip = ref.watch(tripProvider);
    double fare = trip.fare! + (trip.fare! * trip.ccTax!) + (trip.fare! * trip.vatTax!);
    print('appliedccTAX: ${trip.fare! * trip.ccTax!} vatTax: ${trip.fare! + trip.vatTax!} fare: ${trip.fare!} newFare: ${trip.fare! + (trip.fare! * trip.ccTax!) + (trip.fare! + trip.vatTax!)}');
    final user = ref.read(usersProvider).value;
    return Scaffold(
      backgroundColor: Colors.grey[350],
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: currentPosition,
              polylines: Set<Polyline>.of(polyLines.values),
              onMapCreated: (GoogleMapController mapController){
                controller.complete(mapController);
              },
              markers: {
                Marker(
                    markerId: const MarkerId('pickUpLocation'),
                    position: trip.route![0],
                    icon: BitmapDescriptor.defaultMarker
                ),
                Marker(
                    markerId: const MarkerId('dropOffLocation'),
                    position: trip.route![trip.route!.length - 1],
                    icon: BitmapDescriptor.defaultMarker
                ),
              },
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
              top: 10.0,
              right: 10.0,
              child: GestureDetector(
                onTap: (){
                  showNotePanel(trip.notes ?? '');
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22.0),
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
                    child: Icon(Icons.edit_note, color: Colors.black,),
                  ),
                ),
              ),

            ),
            Positioned(
              top: 70.0,
              left: 22.0,
              right: 22.0,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 5.0,),
                        Icon(Icons.trip_origin, size: SizeConfig.safeBlockHorizontal * 5,),
                        const SizedBox(width: 3.0,),
                        Expanded(
                          child: ListTile(
                            title: Text(
                              trip.pickup ?? 'Not set',
                              style: TextStyle(
                                fontSize: SizeConfig.safeBlockHorizontal * 5,
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
                        const SizedBox(width: 5.0,),
                        Icon(Icons.pin_drop, size: SizeConfig.safeBlockHorizontal * 6,),
                        const SizedBox(width: 3.0,),
                        Expanded(
                          child: ListTile(
                            title: Text(
                              trip.dropOff ?? 'Not set',
                              style: TextStyle(
                                  fontSize: SizeConfig.safeBlockHorizontal * 5,
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

            ),
            Positioned(
              bottom: SizeConfig.blockSizeVertical * 13,
              left: SizeConfig.blockSizeHorizontal * 5,
              right: SizeConfig.blockSizeHorizontal * 5,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Image.network(trip.vehicleTypeImage!, width: SizeConfig.blockSizeHorizontal * 12, height: SizeConfig.blockSizeVertical * 7,),
                      title: Text(trip.vehicleType!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: SizeConfig.safeBlockHorizontal * 4),),
                      trailing: Text('₱${fare.toStringAsFixed(2)}', style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4, fontWeight: FontWeight.bold),),
                    ),
                    Divider(height: SizeConfig.blockSizeVertical * 1.5,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 33,
                          child: GestureDetector(
                            onTap: (){
                              showPaymentMethods();
                            },
                            child: Card(
                              elevation: 2,
                              child: Container(padding: const EdgeInsets.all(10), child: Center(child: Text(paymentMethod, style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4, fontWeight: FontWeight.bold),))),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 33,
                          child: GestureDetector(
                            onTap: (){
                              showDiscount();
                            },
                            child: Card(
                              elevation: 2,
                              child: Container(padding: const EdgeInsets.all(10), child: Center(child: Text(discountDisplay, style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4, fontWeight: FontWeight.bold),))),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 33,
                          child: GestureDetector(
                            onTap: (){
                              showPromos();
                            },
                            child: Card(
                              elevation: 2,
                              child: Container(padding: const EdgeInsets.all(10), child: Center(child: Text(promosDisplay, style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4, fontWeight: FontWeight.bold),))),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
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
                  backgroundColor: Colors.black
                ),
                onPressed: () async {
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
                    promos: promos,
                    paymentMethod: paymethod,
                    discount: discount3
                  ));
                  ref.read(tripProvider.notifier).printTripDetails();
                  String? results = await ref.read(tripProvider).saveToFireStore();
                  if(results != null) {
                    print(results);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => TripDetails(tripId: results)));
                  }else{
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("An error occurred please try again later."))
                    );
                  }
                },
                child: Text('Confirm', style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 7, fontWeight: FontWeight.bold, color: Colors.white),),

              ),
            ),


          ],
        ),
      ),
    );
  }
}
