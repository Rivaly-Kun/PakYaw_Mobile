import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:pakyaw/pages/carpool/carpool_page.dart';

import '../home/home.dart';

class AcceptedPage extends StatefulWidget {
  const AcceptedPage({Key? key}) : super(key: key);

  @override
  State<AcceptedPage> createState() => _AcceptedPageState();
}

class _AcceptedPageState extends State<AcceptedPage> {
  String? currentCarpoolId;
  bool hasConfirmed = false;
  bool isConfirming = false;
  String? previousStatus; // Track previous status to detect changes

  Future<bool> _checkUserConfirmation(String carpoolId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final joinedDoc = await FirebaseFirestore.instance
          .collection('carpools')
          .doc(carpoolId)
          .collection('joined')
          .doc(user.uid)
          .get();

      if (joinedDoc.exists) {
        final data = joinedDoc.data();
        return data?['confirmed'] == true;
      }
    } catch (e) {
      debugPrint("Error checking confirmation: $e");
    }
    return false;
  }

  Future<void> _showTripStartWarning(BuildContext context, String carpoolId, int passengerCount, int capacity, double splitFare) async {
    final shouldContinue = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 10),
            Text("Trip Starting"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "The driver is starting the trip now!",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 15),
            Text(
              "Only $passengerCount out of $capacity seats are filled.",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("Your fare: ₱${splitFare.toStringAsFixed(2)}"),
            const SizedBox(height: 5),
            Text(
              "This is higher than if all seats were filled.",
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 15),
            const Text(
              "Do you want to continue with this trip, or leave now?",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Leave Trip",
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Continue Trip"),
          ),
        ],
      ),
    );

    if (shouldContinue != true) {
      // User chose to leave - remove them from carpool
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
              const SnackBar(content: Text("You have left the trip")),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error leaving trip: $e")),
          );
        }
      }
    }
  }
// NEW: Report submission functions
  Future<void> _submitReport(String carpoolId, String driverId, String driverName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final reasons = [
      'Unsafe Driving',
      'Rude Behavior',
      'Vehicle Condition',
      'Route Deviation',
      'Overcharging',
      'No-Show',
      'Other',
    ];

    String? reportReason;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Report Driver"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select a reason:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...reasons.map((reason) => RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: reportReason,
                onChanged: (value) {
                  Navigator.pop(context);
                  _showMessageDialog(carpoolId, driverId, driverName, value!);
                },
                contentPadding: EdgeInsets.zero,
              )).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Future<void> _showMessageDialog(String carpoolId, String driverId, String driverName, String reason) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final messageController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Report: $reason"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Reporting driver: $driverName"),
            const SizedBox(height: 15),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: "Additional details (optional)",
                hintText: "Describe what happened...",
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              maxLength: 500,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Submit Report"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('UserReports').add({
          'createdAt': Timestamp.now(),
          'message': messageController.text.trim().isEmpty
              ? 'Passenger-${user.uid} reported Driver-$driverId for: $reason (Trip-$carpoolId)'
              : '${messageController.text.trim()} (Passenger-${user.uid} reported Driver-$driverId for: $reason, Trip-$carpoolId)',
          'resolve': false,
          'severity': _getSeverityLevel(reason),
          'tag': 'Driver Report',
          'user_id': user.uid,
          'user_type': 'passenger',
          'reported_user_id': driverId,
          'reported_user_type': 'driver',
          'carpool_id': carpoolId,
          'reason': reason,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Text("Report submitted successfully"),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error submitting report: $e")),
          );
        }
      }
    }
  }

  int _getSeverityLevel(String reason) {
    switch (reason) {
      case 'Unsafe Driving':
        return 3;
      case 'Rude Behavior':
        return 2;
      case 'Vehicle Condition':
        return 2;
      case 'Route Deviation':
        return 1;
      case 'Overcharging':
        return 2;
      case 'No-Show':
        return 3;
      default:
        return 1;
    }
  }
  Future<void> _confirmRide(String carpoolId, int passengerCount, int capacity, double splitFare) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isConfirming = true);

    try {
      // Show warning if passenger count is low
      if (passengerCount < capacity) {
        final shouldContinue = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.warning_amber, color: Colors.orange),
                SizedBox(width: 10),
                Text("Fare Warning"),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Only $passengerCount out of $capacity seats are filled.",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text("Your fare will be: ₱${splitFare.toStringAsFixed(2)}"),
                const SizedBox(height: 5),
                Text(
                  "This is higher than if all seats were filled. The driver may start the trip soon.",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Do you agree to continue with this fare?",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Leave Carpool",
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("I Agree"),
              ),
            ],
          ),
        );

        if (shouldContinue != true) {
          // User declined - remove them from carpool
          await FirebaseFirestore.instance
              .collection('carpools')
              .doc(carpoolId)
              .collection('joined')
              .doc(user.uid)
              .delete();

          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("You have left the carpool")),
            );
          }
          return;
        }
      }

      // User confirmed - update their status
      await FirebaseFirestore.instance
          .collection('carpools')
          .doc(carpoolId)
          .collection('joined')
          .doc(user.uid)
          .update({
        'confirmed': true,
        'confirmedAt': Timestamp.now(),
      });

      setState(() {
        hasConfirmed = true;
        isConfirming = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ride confirmed!")),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      setState(() => isConfirming = false);
    }
  }

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
    return WillPopScope(
      onWillPop: () async {
        // Navigate to Home when back button is pressed
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => Home(id: user.uid)),
                (route) => false,
          );
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Your Carpool"),
          backgroundColor: Colors.blue,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Navigate to Home when AppBar back button is pressed
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => Home(id: user.uid)),
                      (route) => false,
                );
              }
            },
          ),
        ),
        // ... rest of your code
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
              if (carpoolSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!carpoolSnapshot.hasData || !carpoolSnapshot.data!.exists) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    // Get the current user ID
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      // Navigate to Home widget with Carpool tab (index 1)
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => Home(id: user.uid),
                        ),
                            (route) => false,
                      );

                      // Show success message after navigation
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Trip completed! Thank you for riding with us.',
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      });
                    }
                  }
                });

                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (carpoolSnapshot.hasError) {
                return Center(
                  child: Text("Error loading trip: ${carpoolSnapshot.error}"),
                );
              }

              final carpool = carpoolSnapshot.data!.data() as Map<String, dynamic>?;

              if (carpool == null) {
                return const Center(
                  child: Text("Carpool data not available"),
                );
              }

              final currentStatus = carpool['status'] as String?;
              final capacity = carpool['capacity'] ?? 0;
              final fare = (carpool['fare'] ?? 0).toDouble();

              // Detect status change from 'waiting' to 'in-progress'
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (previousStatus == 'waiting' && currentStatus == 'in-progress') {
                  // Trip just started, check if seats are not full
                  final passengers = await _getPassengers(carpoolId);
                  final passengerCount = passengers.length;

                  if (passengerCount < capacity && mounted) {
                    final splitFare = _calculateSplitFare(fare, passengerCount);
                    _showTripStartWarning(context, carpoolId, passengerCount, capacity, splitFare);
                  }
                }
                previousStatus = currentStatus;
              });

              final driverId = carpool['driverId'] as String?;
              final pickup = carpool['pickup']?['name'] ?? 'Unknown pickup';
              final dropoff = carpool['dropoff']?['name'] ?? 'Unknown dropoff';
              final distance = (carpool['distance_km'] ?? 0).toDouble();
              final plateNum = carpool['plate_num'] ?? 'N/A';
              final vehicleModel = carpool['vehicleModel'] ?? 'Unknown';

              return SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: _getStatusColor(currentStatus),
                      child: Text(
                        _getTripStatus(currentStatus),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

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

                                  // CONFIRMATION BUTTON
                                  if (currentStatus == 'waiting')
                                    FutureBuilder<bool>(
                                      future: _checkUserConfirmation(carpoolId),
                                      builder: (context, confirmSnapshot) {
                                        final isConfirmed = confirmSnapshot.data ?? false;

                                        if (isConfirmed) {
                                          return Container(
                                            margin: const EdgeInsets.only(top: 12),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.check_circle, size: 20, color: Colors.green.shade700),
                                                const SizedBox(width: 8),
                                                Text(
                                                  "Ride Confirmed - Waiting for driver",
                                                  style: TextStyle(
                                                    color: Colors.green.shade700,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        return Container(
                                          margin: const EdgeInsets.only(top: 12),
                                          child: ElevatedButton(
                                            onPressed: isConfirming
                                                ? null
                                                : () => _confirmRide(
                                              carpoolId,
                                              passengerCount,
                                              capacity,
                                              splitFare,
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            ),
                                            child: isConfirming
                                                ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                                : const Text(
                                              "Confirm Ride & Fare",
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

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
                                    IconButton(
                                      icon: const Icon(Icons.flag, color: Colors.red, size: 28),
                                      onPressed: () {
                                        _submitReport(carpoolId, driverId, driverName);
                                      },
                                      tooltip: "Report Driver",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

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

                    if (currentStatus == 'waiting')
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
        ),
    );
  }
}

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