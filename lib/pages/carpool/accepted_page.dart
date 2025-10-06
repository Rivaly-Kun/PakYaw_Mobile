import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class AcceptedPage extends StatefulWidget {
  const AcceptedPage({Key? key}) : super(key: key);

  @override
  State<AcceptedPage> createState() => _AcceptedPageState();
}

class _AcceptedPageState extends State<AcceptedPage> {
  String? currentCarpoolId;

  Future<Map<String, dynamic>?> _getAcceptedCarpool() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final carpools = await FirebaseFirestore.instance.collection('carpools').get();

      DateTime? mostRecentJoinTime;
      Map<String, dynamic>? targetCarpool;

      for (var carpoolDoc in carpools.docs) {
        final joinedRef = carpoolDoc.reference.collection('joined').doc(user.uid);
        final joinedSnap = await joinedRef.get();

        if (joinedSnap.exists && joinedSnap.data()?['status'] == 'accepted') {
          final joinedAt = (joinedSnap.data()?['joined_at'] as Timestamp?)?.toDate();

          if (joinedAt != null) {
            if (mostRecentJoinTime == null || joinedAt.isAfter(mostRecentJoinTime)) {
              mostRecentJoinTime = joinedAt;
              final carpoolData = carpoolDoc.data();
              targetCarpool = {
                'carpoolId': carpoolDoc.id,
                ...carpoolData,
              };
            }
          }
        }
      }

      if (targetCarpool != null) {
        currentCarpoolId = targetCarpool['carpoolId'];
      }

      return targetCarpool;
    } catch (e) {
      debugPrint("Error loading carpool: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getDriverData(String driverId) async {
    try {
      final driverDoc = await FirebaseFirestore.instance
          .collection('Driver')
          .doc(driverId)
          .get();
      return driverDoc.exists ? driverDoc.data() : null;
    } catch (e) {
      debugPrint("Error loading driver: $e");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _getPassengers(String carpoolId) async {
    try {
      final joinedSnapshot = await FirebaseFirestore.instance
          .collection('carpools')
          .doc(carpoolId)
          .collection('joined')
          .where('status', isEqualTo: 'accepted')
          .get();

      List<Map<String, dynamic>> passengers = [];

      for (var joinedDoc in joinedSnapshot.docs) {
        final joinedData = joinedDoc.data();
        final passengerId = joinedData['user_id'] as String?;

        if (passengerId != null) {
          final passengerDoc = await FirebaseFirestore.instance
              .collection('Passengers')
              .doc(passengerId)
              .get();

          if (passengerDoc.exists) {
            passengers.add({
              ...passengerDoc.data()!,
              'user_id': passengerId,
            });
          }
        }
      }

      return passengers;
    } catch (e) {
      debugPrint("Error loading passengers: $e");
      return [];
    }
  }

  Future<int> _getRejectedCount(String carpoolId) async {
    try {
      final rejectedSnapshot = await FirebaseFirestore.instance
          .collection('carpools')
          .doc(carpoolId)
          .collection('joined')
          .where('status', isEqualTo: 'rejected')
          .get();
      return rejectedSnapshot.docs.length;
    } catch (e) {
      debugPrint("Error counting rejected: $e");
      return 0;
    }
  }

  double _calculateSplitFare(double totalFare, int passengerCount) {
    if (passengerCount <= 0) return totalFare;
    return totalFare / passengerCount;
  }

  String _getTripStatus(String? status) {
    switch (status) {
      case 'waiting':
        return 'Waiting for Driver to Start';
      case 'in-progress':
        return 'Trip in Progress';
      case 'completed':
        return 'Trip Completed';
      default:
        return 'Status Unknown';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'waiting':
        return Colors.orange;
      case 'in-progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Carpool"),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getAcceptedCarpool(),
        builder: (context, initialSnapshot) {
          if (initialSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!initialSnapshot.hasData || initialSnapshot.data == null) {
            return const Center(
              child: Text("No accepted carpool found."),
            );
          }

          final carpoolId = initialSnapshot.data!['carpoolId'] as String;

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('carpools')
                .doc(carpoolId)
                .snapshots(),
            builder: (context, carpoolSnapshot) {
              // Add loading state
              if (carpoolSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Check if carpool was deleted (trip ended)
              if (!carpoolSnapshot.hasData || !carpoolSnapshot.data!.exists) {
                // Use a flag to prevent multiple dialogs
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && Navigator.canPop(context)) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => WillPopScope(
                        onWillPop: () async => false,
                        child: AlertDialog(
                          title: const Text("Trip Completed"),
                          content: const Text(
                            "Your carpool trip has ended. Thank you for riding with us!",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close dialog
                                Navigator.of(context).pop(); // Go back to dashboard
                              },
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                });

                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 80, color: Colors.green),
                      SizedBox(height: 20),
                      Text(
                        "Trip Completed!",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }

              // Add error handling
              if (carpoolSnapshot.hasError) {
                return Center(
                  child: Text("Error loading trip: ${carpoolSnapshot.error}"),
                );
              }

              final carpool = carpoolSnapshot.data!.data() as Map<String, dynamic>?;

              // Check if data is null
              if (carpool == null) {
                return const Center(
                  child: Text("Carpool data not available"),
                );
              }
              final driverId = carpool['driverId'] as String?;

              final pickup = carpool['pickup']?['name'] ?? 'Unknown pickup';
              final dropoff = carpool['dropoff']?['name'] ?? 'Unknown dropoff';
              final fare = (carpool['fare'] ?? 0).toDouble();
              final distance = (carpool['distance_km'] ?? 0).toDouble();
              final capacity = carpool['capacity'] ?? 0;
              final status = carpool['status'] as String?;
              final plateNum = carpool['plate_num'] ?? 'N/A';
              final vehicleModel = carpool['vehicleModel'] ?? 'Unknown';

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Trip Status Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: _getStatusColor(status),
                      child: Text(
                        _getTripStatus(status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Route Info
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.green, size: 30),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  pickup,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            height: 40,
                            width: 2,
                            color: Colors.grey,
                          ),
                          Row(
                            children: [
                              const Icon(Icons.flag, color: Colors.red, size: 30),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  dropoff,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Fare, Distance, Passengers Counter with Split Fare
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _getPassengers(carpoolId),
                            builder: (context, passengerSnapshot) {
                              final passengerCount = passengerSnapshot.data?.length ?? 0;
                              final splitFare = _calculateSplitFare(fare, passengerCount);

                              return Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        children: [
                                          const Text("Your Fare", style: TextStyle(color: Colors.grey)),
                                          Text(
                                            "₱${splitFare.toStringAsFixed(2)}",
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                                          ),
                                          if (passengerCount > 1)
                                            Text(
                                              "Split $passengerCount ways",
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                            ),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          const Text("Distance", style: TextStyle(color: Colors.grey)),
                                          Text(
                                            "${distance.toStringAsFixed(1)} km",
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          const Text("Passengers", style: TextStyle(color: Colors.grey)),
                                          Text(
                                            "$passengerCount/$capacity",
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (passengerCount > 1) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.savings_outlined, size: 16, color: Colors.green.shade700),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Original fare ₱${fare.toStringAsFixed(2)} • You save ₱${(fare - splitFare).toStringAsFixed(2)}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

                    // Route Map Preview
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenMapPage(
                              pickupLat: carpool['pickup']?['lat'] ?? 0.0,
                              pickupLng: carpool['pickup']?['lng'] ?? 0.0,
                              dropoffLat: carpool['dropoff']?['lat'] ?? 0.0,
                              dropoffLng: carpool['dropoff']?['lng'] ?? 0.0,
                              encodedPolyline: carpool['encoded_polyline'] ?? '',
                              pickupName: pickup,
                              dropoffName: dropoff,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(
                                    carpool['pickup']?['lat'] ?? 0.0,
                                    carpool['pickup']?['lng'] ?? 0.0,
                                  ),
                                  zoom: 12,
                                ),
                                markers: {
                                  Marker(
                                    markerId: const MarkerId('pickup'),
                                    position: LatLng(
                                      carpool['pickup']?['lat'] ?? 0.0,
                                      carpool['pickup']?['lng'] ?? 0.0,
                                    ),
                                    icon: BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueGreen,
                                    ),
                                  ),
                                  Marker(
                                    markerId: const MarkerId('dropoff'),
                                    position: LatLng(
                                      carpool['dropoff']?['lat'] ?? 0.0,
                                      carpool['dropoff']?['lng'] ?? 0.0,
                                    ),
                                    icon: BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueRed,
                                    ),
                                  ),
                                },
                                polylines: {
                                  if (carpool['encoded_polyline'] != null)
                                    Polyline(
                                      polylineId: const PolylineId('route'),
                                      points: PolylinePoints()
                                          .decodePolyline(carpool['encoded_polyline'])
                                          .map((point) => LatLng(point.latitude, point.longitude))
                                          .toList(),
                                      color: Colors.blue,
                                      width: 5,
                                    ),
                                },
                                zoomControlsEnabled: false,
                                myLocationButtonEnabled: false,
                                mapToolbarEnabled: false,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.3),
                                    ],
                                  ),
                                ),
                              ),
                              const Positioned(
                                bottom: 10,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Text(
                                    "Tap to view full route",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

                    // Driver Info
                    if (driverId != null)
                      FutureBuilder<Map<String, dynamic>?>(
                        future: _getDriverData(driverId),
                        builder: (context, driverSnapshot) {
                          if (!driverSnapshot.hasData || driverSnapshot.data == null) {
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text("Loading driver info..."),
                            );
                          }

                          final driver = driverSnapshot.data!;
                          final driverName = driver['name'] ?? 'Unknown Driver';
                          final driverPhoto = driver['profile_pic'] ?? '';
                          final driverRating = (driver['rating'] ?? 0).toDouble();
                          final driverPhone = driver['phone_number'] ?? '';

                          return Container(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Your Driver",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 35,
                                      backgroundImage: driverPhoto.isNotEmpty
                                          ? NetworkImage(driverPhoto)
                                          : null,
                                      child: driverPhoto.isEmpty
                                          ? const Icon(Icons.person, size: 40)
                                          : null,
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            driverName,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.star, color: Colors.amber, size: 18),
                                              const SizedBox(width: 5),
                                              Text(
                                                driverRating.toStringAsFixed(1),
                                                style: const TextStyle(fontSize: 16),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            "$vehicleModel • $plateNum",
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.phone, color: Colors.blue, size: 28),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Call $driverPhone")),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

                    // Other Passengers
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _getPassengers(carpoolId),
                      builder: (context, passengerSnapshot) {
                        if (passengerSnapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          );
                        }

                        final passengers = passengerSnapshot.data ?? [];

                        if (passengers.length <= 1) {
                          return const SizedBox.shrink();
                        }

                        return Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Other Passengers",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 15),
                              ...passengers.map((passenger) {
                                final name = passenger['name'] ?? 'Unknown';
                                final photo = passenger['profile_pic'] ?? '';
                                final rating = (passenger['rating'] ?? 0).toDouble();

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundImage: photo.isNotEmpty
                                            ? NetworkImage(photo)
                                            : null,
                                        child: photo.isEmpty
                                            ? const Icon(Icons.person)
                                            : null,
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                                const SizedBox(width: 5),
                                                Text(
                                                  rating.toStringAsFixed(1),
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        );
                      },
                    ),

                    // Rejected Passengers Alert
                    FutureBuilder<int>(
                      future: _getRejectedCount(carpoolId),
                      builder: (context, rejectedSnapshot) {
                        final rejectedCount = rejectedSnapshot.data ?? 0;

                        if (rejectedCount == 0) {
                          return const SizedBox.shrink();
                        }

                        return Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.red.shade700),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "$rejectedCount passenger(s) were rejected by the driver",
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Cancel Button (only show if trip is waiting)
                    if (status == 'waiting')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Cancel Carpool?"),
                                  content: const Text("Are you sure you want to cancel this carpool?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text("No"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text("Yes", style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true && mounted) {
                                try {
                                  final user = FirebaseAuth.instance.currentUser;
                                  if (user != null) {
                                    await FirebaseFirestore.instance
                                        .collection('carpools')
                                        .doc(carpoolId)
                                        .collection('joined')
                                        .doc(user.uid)
                                        .delete();

                                    if (mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Carpool cancelled")),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Error: $e")),
                                    );
                                  }
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                            ),
                            child: const Text(
                              "Cancel Carpool",
                              style: TextStyle(color: Colors.red, fontSize: 16),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Full Screen Map Page remains the same
class FullScreenMapPage extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final String encodedPolyline;
  final String pickupName;
  final String dropoffName;

  const FullScreenMapPage({
    Key? key,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.encodedPolyline,
    required this.pickupName,
    required this.dropoffName,
  }) : super(key: key);

  @override
  State<FullScreenMapPage> createState() => _FullScreenMapPageState();
}

class _FullScreenMapPageState extends State<FullScreenMapPage> {
  GoogleMapController? mapController;
  Set<Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    _decodePolyline();
  }

  void _decodePolyline() {
    if (widget.encodedPolyline.isNotEmpty) {
      List<LatLng> routePoints = PolylinePoints()
          .decodePolyline(widget.encodedPolyline)
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      setState(() {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: routePoints,
            color: Colors.blue,
            width: 6,
          ),
        );
      });
    }
  }

  void _fitBounds() {
    if (mapController == null) return;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        widget.pickupLat < widget.dropoffLat ? widget.pickupLat : widget.dropoffLat,
        widget.pickupLng < widget.dropoffLng ? widget.pickupLng : widget.dropoffLng,
      ),
      northeast: LatLng(
        widget.pickupLat > widget.dropoffLat ? widget.pickupLat : widget.dropoffLat,
        widget.pickupLng > widget.dropoffLng ? widget.pickupLng : widget.dropoffLng,
      ),
    );

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Route Map"),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.pickupLat, widget.pickupLng),
              zoom: 13,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('pickup'),
                position: LatLng(widget.pickupLat, widget.pickupLng),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
                infoWindow: InfoWindow(
                  title: 'Pickup',
                  snippet: widget.pickupName,
                ),
              ),
              Marker(
                markerId: const MarkerId('dropoff'),
                position: LatLng(widget.dropoffLat, widget.dropoffLng),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
                infoWindow: InfoWindow(
                  title: 'Drop-off',
                  snippet: widget.dropoffName,
                ),
              ),
            },
            polylines: polylines,
            onMapCreated: (controller) {
              mapController = controller;
              Future.delayed(const Duration(milliseconds: 500), _fitBounds);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapToolbarEnabled: true,
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.location_on, color: Colors.green, size: 20),
                      SizedBox(width: 5),
                      Text("Pickup", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: const [
                      Icon(Icons.flag, color: Colors.red, size: 20),
                      SizedBox(width: 5),
                      Text("Drop-off", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}