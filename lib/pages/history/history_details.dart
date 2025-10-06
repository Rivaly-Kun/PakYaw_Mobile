import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pakyaw/models/history_ride_model.dart';
import 'package:pakyaw/services/database.dart';
import 'package:pakyaw/shared/size_config.dart';

class HistoryDetails extends StatefulWidget {
  final Trips trip;
  const HistoryDetails({super.key, required this.trip});

  @override
  State<HistoryDetails> createState() => _HistoryDetailsState();
}

class _HistoryDetailsState extends State<HistoryDetails> {
  DatabaseService databaseService = DatabaseService();
  bool isChangedRoute = false;
  LatLng? position;
  LatLng? pickUp;
  LatLng? dest;

  Map<PolylineId, Polyline> polyLines = {};

  Completer<GoogleMapController> controller = Completer<GoogleMapController>();

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
    position = LatLng(points[half].latitude, points[half].longitude);
    setState(() {
      pickUp = LatLng(points[0].latitude, points[0].longitude);
      dest = LatLng(points[max].latitude, points[max].longitude);
    });

    GoogleMapController mapController = await controller.future;
    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  void getPolylineFromPoints(List<LatLng> coordinates) async {
    PolylineId polylineId = const PolylineId("driverToPickup");
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
    fitPolylineToMap(coordinates);
  }

  void getPolylineFromPoints2(List<LatLng> coordinates) async {
    PolylineId polylineId = const PolylineId("PickupToDest");
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
    fitPolylineToMap(coordinates);
  }

  String formatTimestamp(Timestamp timestamp){
    DateTime date = timestamp.toDate();
    final DateFormat dateFormat = DateFormat('MMM d, yyyy - hh:mm a');
    return dateFormat.format(date);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getPolylineFromPoints(widget.trip.route);
  }

  double getActualFare(double fare, double discount, bool vat){
    double vatVal = 0.0;
    if(vat){
      vatVal = (fare * discount) * 0.12;
    }
    if(discount == 0.0){
      return (fare + (fare * 0.03)) + vatVal;
    }else{
      double discounted = fare - (fare * discount);
      return (discounted + (discounted * 0.03)) + vatVal;
    }
  }

  showSuccess(BuildContext context1){
    SizeConfig().init(context1);
    showDialog(context: context, builder: (context) => AlertDialog(
      content: SizedBox(
        height: SizeConfig.blockSizeVertical * 23,
        child: Column(
          children: [
            Image(
              image: const AssetImage('assets/sent.png'),
              height: SizeConfig.blockSizeVertical * 10,
              width: SizeConfig.blockSizeHorizontal * 30,
            ),
            Text(
              'Report has been sent.',
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
    ));
  }
  showError(BuildContext context1){
    SizeConfig().init(context1);
    showDialog(context: context, builder: (context) => AlertDialog(
      content: SizedBox(
        height: SizeConfig.blockSizeVertical * 23,
        child: Column(
          children: [
            Image(
              image: const AssetImage('assets/cross.png'),
              height: SizeConfig.blockSizeVertical * 10,
              width: SizeConfig.blockSizeHorizontal * 30,
            ),
            Text(
              'An error occurred.',
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
    ));
  }

  showReportDialog(BuildContext context1, Map<String, dynamic> driverId, Map<String, dynamic> passengerId, String tripId){
    TextEditingController other = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image(
              image: const AssetImage('assets/alert.png'),
              height: SizeConfig.blockSizeVertical * 10,
              width: SizeConfig.blockSizeHorizontal * 30,
            ),
            const SizedBox(height: 10,),
            const Text('Report'),
          ],
        ),
        content: TextField(
          controller: other,
          minLines: 1,
          maxLines: null,
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4, fontWeight: FontWeight.w500),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              bool result = await databaseService.reportIncident(tripId, driverId, passengerId, other.text);
              if(result){
                Navigator.pop(context);
                showSuccess(context1);
              }else{
                Navigator.pop(context);
                showError(context1);
              }

            },
            child: const Text('Report', style: TextStyle(fontSize: 20.0),),

          )
        ]
    ));
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    int getDuration(String time){
      int seconds = int.parse(time.replaceAll('s', ''));
      if(seconds > 60){
        int minute = (seconds/60).round();
        return minute;
      }else{
        return seconds;
      }

    }
    int duration = getDuration(widget.trip.duration);
    double fare = widget.trip.fare + (widget.trip.fare * widget.trip.vatTax) + (widget.trip.fare * widget.trip.ccTax);
    double promoDiscount = fare * widget.trip.promo['discount'];
    double discountFare = fare - promoDiscount;
    double spDiscount = 0.0;
    if(widget.trip.discount['peso'] != 0.0){
      spDiscount = widget.trip.discount['peso'];
    }else if(widget.trip.discount['discount'] != 0.0){
      spDiscount = discountFare * widget.trip.discount['discount'];
    }
    double discountFare2 = discountFare - spDiscount;
    return Scaffold(
      appBar: AppBar(
        title: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Trip Details',
            style: TextStyle(
                fontSize: SizeConfig.safeBlockHorizontal * 6,
              fontWeight: FontWeight.bold
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              showReportDialog(context, widget.trip.driver, widget.trip.passenger, widget.trip.uid);
            },
            icon: const Icon(
              Icons.report,
              color: Colors.black,
            ),
            label: const Text(
              'Report',
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 10.0, right: 10.0),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0), ), ),
              expandedHeight: SizeConfig.blockSizeVertical * 30,
              pinned: false,
              floating: false,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Column(
                  children: [
                    if (widget.trip.changedRoute != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Text(
                              isChangedRoute ? 'Changed route' : 'Original route',
                              style: TextStyle(
                                  fontSize: SizeConfig.safeBlockHorizontal * 3.3,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black
                              ),
                            ),
                            Switch(
                              value: isChangedRoute,
                              onChanged: (value) {
                                if(isChangedRoute){
                                  getPolylineFromPoints(widget.trip.route);
                                }else{
                                  getPolylineFromPoints2(widget.trip.changedRoute!);
                                }
                                setState(() {
                                  isChangedRoute = !isChangedRoute;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0)
                        ),
                        child: GoogleMap(
                          onMapCreated: (GoogleMapController mapController) {
                            controller.complete(mapController);
                          },
                          zoomControlsEnabled: false,
                          initialCameraPosition: CameraPosition(
                            target: position!,
                            zoom: 12,
                          ),
                          polylines: Set<Polyline>.of(polyLines.values),
                          markers: {
                            Marker(
                                markerId: const MarkerId('pickUpLocation'),
                                position: pickUp!,
                                icon: BitmapDescriptor.defaultMarker
                            ),
                            Marker(
                                markerId: const MarkerId('dropOffLocation'),
                                position: dest!,
                                icon: BitmapDescriptor.defaultMarker
                            ),
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                SizedBox(height: SizeConfig.blockSizeVertical * 2,),
                Center(
                  child: Text(
                    'Trip ID: ${widget.trip.uid}',
                    style: TextStyle(
                      fontSize: SizeConfig.safeBlockHorizontal * 5,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.blockSizeVertical * 1.5,),
                Text(
                  'Date:${formatTimestamp(widget.trip.createdTime)}',
                  style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 5,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const Divider(thickness: 1.5,),
                SizedBox(height: SizeConfig.blockSizeVertical * 1.2,),
                Text(
                  int.parse(widget.trip.duration.replaceAll('s', '')) < 60 ? 'Duration: $duration sec' : 'Duration: $duration min',
                  style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 5,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const Divider(thickness: 1.5,),
                SizedBox(height: SizeConfig.blockSizeVertical * 1.2,),
                Text(
                  widget.trip.distance > 1 ? 'Distance:${widget.trip.distance}km'
                      : 'Distance:${(widget.trip.distance * 1000)}m',
                  style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 5,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const Divider(thickness: 1.5,),
                SizedBox(height: SizeConfig.blockSizeVertical * 1.2,),
                Text(
                  'Fare: ₱${fare.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 5,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const Divider(thickness: 1.5,),
                SizedBox(height: SizeConfig.blockSizeVertical * 1.2,),
                Text(
                  'Payment Method: ${widget.trip.paymentMethod['payment_method']}(${widget.trip.paymentMethod['account_num']})',
                  style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 5,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const Divider(thickness: 1.5,),
                SizedBox(height: SizeConfig.blockSizeVertical * 1.2,),
                Text(
                  'Promos Applied: ${promoDiscount != 0 ? '${widget.trip.promo['promo_name']}(-₱${promoDiscount.toStringAsFixed(2)})' : 'N/A'}',
                  style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 5,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const Divider(thickness: 1.5,),
                SizedBox(height: SizeConfig.blockSizeVertical * 1.2,),
                Text(
                  'Discount Applied: ${spDiscount != 0 ? '${widget.trip.discount['discount_name']}(-₱${spDiscount.toStringAsFixed(2)})' :  'N/A'}',
                  style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 5,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const Divider(thickness: 1.5,),
                SizedBox(height: SizeConfig.blockSizeVertical * 1.2,),
                Text(
                  'Driver:',
                  style: TextStyle(
                      fontSize: SizeConfig.safeBlockHorizontal * 6,
                      color: Colors.black,
                      fontWeight: FontWeight.w500
                  ),
                ),
                widget.trip.driver['driver_id'] != '' ? ListTile(
                  contentPadding: const EdgeInsets.only(left: 0),
                  leading: Container(
                    width: SizeConfig.safeBlockHorizontal * 13,
                    height: SizeConfig.blockSizeVertical * 8,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(widget.trip.driver['driver_profile']),
                      ),
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(widget.trip.driver['driver_name'], style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4, fontWeight: FontWeight.bold),),
                  subtitle: Row(
                    children: [
                      Icon(Icons.star, size: SizeConfig.safeBlockHorizontal * 6,),
                      Text('${widget.trip.driver['rating'].toStringAsFixed(1)}', style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4,),)
                    ],
                  ),
                ) : Container(),
                widget.trip.driver['driver_id'] != '' ? Text(
                  'Vehicle:${widget.trip.vehicle['model']}',
                  style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 5, fontWeight: FontWeight.normal),
                ) : Container(),
                Text(
                  'Type: ${widget.trip.vehicleType}',
                  style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 5, fontWeight: FontWeight.normal),
                ),
                const Divider(thickness: 1.5,),
                SizedBox(height: SizeConfig.blockSizeVertical * 1.2,),
                Text(
                  'Pickup Location',
                  style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: SizeConfig.blockSizeVertical * 1.2,),
                Text(
                  widget.trip.changedPickupAddress == '' ? widget.trip.pickupAddress : widget.trip.changedPickupAddress,
                  style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 5,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                SizedBox(height: SizeConfig.blockSizeVertical * 1.2,),
                widget.trip.changedPickupAddress != '' ? Text(
                  'Changed from: ${widget.trip.pickupAddress}',
                  style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 5,
                    fontWeight: FontWeight.normal,
                    overflow: TextOverflow.fade,
                    color: Colors.red
                  ),
                  maxLines: 2,
                ) : Container(),
                SizedBox(height: SizeConfig.blockSizeVertical * 1.7,),
                Text(
                  'Drop-off Location',
                  style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: SizeConfig.blockSizeVertical * 1.2,),
                Text(
                  widget.trip.changedDropOffAddress == '' ? widget.trip.dropOffAddress : widget.trip.changedDropOffAddress,
                  style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 5,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                SizedBox(height: SizeConfig.blockSizeVertical* 1.2,),
                widget.trip.changedDropOffAddress != '' ? Text(
                  'Changed from: ${widget.trip.dropOffAddress}',
                  style: TextStyle(
                      fontSize: SizeConfig.safeBlockHorizontal * 5,
                      fontWeight: FontWeight.normal,
                      overflow: TextOverflow.fade,
                      color: Colors.red
                  ),
                  maxLines: 2,
                ): Container(),
                const Divider(thickness: 1.5,),
                SizedBox(height: SizeConfig.blockSizeVertical * 1.2,),
                RichText(
                  text: TextSpan(
                      text: 'Status: ',
                      style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 5,
                          color: Colors.black,
                          fontWeight: FontWeight.normal
                      ),
                      children: [
                        TextSpan(text: widget.trip.status , style: TextStyle(color: widget.trip.status == 'cancelled' ? Colors.red : Colors.black))
                      ]
                  ),
                ),
                const Divider(thickness: 1.5,),
                SizedBox(height: SizeConfig.blockSizeVertical * 1.2,),
                Text(
                  'Total Amount: ₱${discountFare2.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Divider(thickness: 1.5,),
                SizedBox(height: SizeConfig.blockSizeVertical * 1.2,),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
