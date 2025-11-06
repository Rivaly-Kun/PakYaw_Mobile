import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pakyaw/models/trip_models.dart';
import 'package:pakyaw/shared/size_config.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';


class HistoryDetails extends StatefulWidget {
  final BaseTrip trip;
  const HistoryDetails({super.key, required this.trip});

  @override
  State<HistoryDetails> createState() => _HistoryDetailsState();
}

class _HistoryDetailsState extends State<HistoryDetails> {
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  bool isLoadingRoute = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    if (widget.trip is PakyawTrip) {
      _initializePakyawMap();
    } else if (widget.trip is CarpoolTrip) {
      await _initializeCarpoolMap();
    }
  }

  void _initializePakyawMap() {
    final pakyawTrip = widget.trip as PakyawTrip;

    // Add markers
    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(
          pakyawTrip.pickUpLoc.latitude,
          pakyawTrip.pickUpLoc.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Pickup'),
      ),
    );

    markers.add(
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(
          pakyawTrip.dropOffLoc.latitude,
          pakyawTrip.dropOffLoc.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Drop-off'),
      ),
    );

    // Add polyline
    if (pakyawTrip.route.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: pakyawTrip.route,
          color: Colors.blue,
          width: 5,
        ),
      );
    }

    setState(() {
      isLoadingRoute = false;
    });
  }

  Future<void> _initializeCarpoolMap() async {
    final carpoolTrip = widget.trip as CarpoolTrip;

    // Add markers
    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(
          carpoolTrip.pickup['lat'],
          carpoolTrip.pickup['lng'],
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: carpoolTrip.pickup['name'] ?? 'Pickup'),
      ),
    );

    markers.add(
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(
          carpoolTrip.dropoff['lat'],
          carpoolTrip.dropoff['lng'],
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: carpoolTrip.dropoff['name'] ?? 'Drop-off'),
      ),
    );

    // Decode polyline
    if (carpoolTrip.routeTaken.isNotEmpty) {
      try {
        PolylinePoints polylinePoints = PolylinePoints();
        List<PointLatLng> result = polylinePoints.decodePolyline(carpoolTrip.routeTaken);

        List<LatLng> polylineCoordinates = result
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: polylineCoordinates,
            color: Colors.green,
            width: 5,
          ),
        );
      } catch (e) {
        print('Error decoding polyline: $e');
      }
    }

    setState(() {
      isLoadingRoute = false;
    });
  }

  LatLng _getInitialCameraPosition() {
    if (widget.trip is PakyawTrip) {
      final pakyawTrip = widget.trip as PakyawTrip;
      return LatLng(
        pakyawTrip.pickUpLoc.latitude,
        pakyawTrip.pickUpLoc.longitude,
      );
    } else if (widget.trip is CarpoolTrip) {
      final carpoolTrip = widget.trip as CarpoolTrip;
      return LatLng(
        carpoolTrip.pickup['lat'],
        carpoolTrip.pickup['lng'],
      );
    }
    return const LatLng(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Trip Details',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Map Section
            Hero(
              tag: 'trip_${widget.trip.uid}',
              child: Container(
                height: 300,
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: isLoadingRoute
                    ? const Center(child: CircularProgressIndicator())
                    : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _getInitialCameraPosition(),
                    zoom: 13,
                  ),
                  markers: markers,
                  polylines: polylines,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Trip Details
            if (widget.trip is PakyawTrip)
              _buildPakyawDetails()
            else if (widget.trip is CarpoolTrip)
              _buildCarpoolDetails(),
          ],
        ),
      ),
    );
  }



  Widget _buildPakyawDetails() {
    final trip = widget.trip as PakyawTrip;

    // 🧮 Compute fare values
    double baseFare = trip.fare;
    double vatAmount = trip.fare * (trip.vatTax ?? 0.0);

    // Discount (peso or percentage)
    double discount = 0.0;
    if ((trip.discount?['peso'] ?? 0.0) != 0.0) {
      discount = trip.discount['peso'];
    } else if ((trip.discount?['discount'] ?? 0.0) != 0.0) {
      discount = (baseFare + vatAmount) * trip.discount['discount'];
    }

    // Final total fare
    double totalFare = (baseFare + vatAmount) - discount;

    // Currency format (₱)
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

    return Column(
      children: [
        // 🗺️ Route Information
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Route Information', Icons.route),
              const SizedBox(height: 16),
              _buildLocationRow(Icons.circle, Colors.green, 'Pickup', trip.pickupAddress),
              const SizedBox(height: 12),
              _buildLocationRow(Icons.location_on, Colors.red, 'Drop-off', trip.dropOffAddress),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(Icons.straighten, '${trip.distance.toStringAsFixed(2)} km'),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.access_time, trip.duration),
                ],
              ),
            ],
          ),
        ),

        // 👨‍✈️ Driver Information
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Driver Information', Icons.person),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: trip.driver['driver_profile'] != null &&
                        trip.driver['driver_profile'].isNotEmpty
                        ? NetworkImage(trip.driver['driver_profile'])
                        : null,
                    child: trip.driver['driver_profile'] == null ||
                        trip.driver['driver_profile'].isEmpty
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.driver['driver_name'] ?? 'Unknown Driver',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber[700]),
                            const SizedBox(width: 4),
                            Text(
                              '${trip.driver['rating'] ?? 0.0}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 🚗 Vehicle Information
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Vehicle Information', Icons.directions_car),
              const SizedBox(height: 16),
              _buildInfoRow('Model', trip.vehicle['model'] ?? 'N/A'),
              _buildInfoRow('Plate Number', trip.vehicle['plate_num'] ?? 'N/A'),
              _buildInfoRow('Type', trip.vehicleType),
            ],
          ),
        ),

        // 💳 Payment Information
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Payment Information', Icons.payment),
              const SizedBox(height: 16),
              _buildFareRow('Base Fare', baseFare),
              if (vatAmount > 0) _buildFareRow('VAT', vatAmount),
              if (discount > 0)
                _buildFareRow(
                  'Discount (${trip.discount['discount_name'] ?? ''})',
                  -discount,
                  isDiscount: true,
                ),
              const Divider(height: 24),
              _buildFareRow('Total', totalFare, isTotal: true),
              const SizedBox(height: 12),
              _buildInfoRow('Payment Method', trip.paymentMethod['payment_method'] ?? 'Cash'),
            ],
          ),
        ),

        // 📋 Trip Status
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Trip Status', Icons.info),
              const SizedBox(height: 16),
              _buildInfoRow('Status', trip.status.toUpperCase()),
              _buildInfoRow(
                'Date',
                DateFormat('MMMM dd, yyyy - hh:mm a').format(trip.createdTime.toDate()),
              ),
              if (trip.rating > 0) _buildInfoRow('Your Rating', '${trip.rating} ⭐'),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildCarpoolDetails() {
    final trip = widget.trip as CarpoolTrip;

    return Column(
      children: [
        // Trip Type Badge
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'CARPOOL TRIP',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Route Information
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Route Information', Icons.route),
              const SizedBox(height: 16),
              _buildLocationRow(
                Icons.circle,
                Colors.green,
                'Pickup',
                trip.pickup['name'] ?? 'Unknown location',
              ),
              const SizedBox(height: 12),
              _buildLocationRow(
                Icons.location_on,
                Colors.red,
                'Drop-off',
                trip.dropoff['name'] ?? 'Unknown location',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.straighten,
                    '${trip.distanceKm.toStringAsFixed(2)} km',
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.access_time,
                    '${(trip.durationSeconds / 60).toStringAsFixed(0)} min',
                  ),
                ],
              ),
            ],
          ),
        ),

        // Driver Information
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Driver Information', Icons.person),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.person, size: 30, color: Colors.blue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.driverName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Carpool Driver',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Vehicle Information
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Vehicle Information', Icons.directions_car),
              const SizedBox(height: 16),
              _buildInfoRow('Model', trip.vehicleModel),
              _buildInfoRow('Plate Number', trip.plateNum),
            ],
          ),
        ),

        // Passengers Information
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'Passengers (${trip.passengerCount})',
                Icons.people,
              ),
              const SizedBox(height: 16),
              ...trip.passengers.map((passenger) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.shade300,
                      child: Text(
                        passenger.userName[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            passenger.userName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            passenger.userEmail,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₱${passenger.fareOwed.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),

        // Payment Information
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Payment Information', Icons.payment),
              const SizedBox(height: 16),
              _buildFareRow('Fare per Passenger', trip.farePerPassenger),
              _buildFareRow('Total Fare', trip.fareTotal),
              const SizedBox(height: 12),
              _buildInfoRow('Payment Method', trip.paymentMethod),
            ],
          ),
        ),

        // Trip Status
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Trip Status', Icons.info),
              const SizedBox(height: 16),
              _buildInfoRow('Status', trip.status.toUpperCase()),
              _buildInfoRow(
                'Started',
                DateFormat('MMMM dd, yyyy - hh:mm a')
                    .format(trip.startedAt.toDate()),
              ),
              _buildInfoRow(
                'Completed',
                DateFormat('MMMM dd, yyyy - hh:mm a')
                    .format(trip.completedAt.toDate()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.blue.shade700),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow(
      IconData icon,
      Color color,
      String label,
      String address,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareRow(
      String label,
      double amount, {
        bool isDiscount = false,
        bool isTotal = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black87 : Colors.grey[600],
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}₱${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal
                  ? Colors.green.shade700
                  : isDiscount
                  ? Colors.red
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}