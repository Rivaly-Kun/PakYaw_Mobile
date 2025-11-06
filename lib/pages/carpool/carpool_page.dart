import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pakyaw/pages/carpool/accepted_page.dart';
import 'package:firebase_database/firebase_database.dart';

class CarpoolPage extends StatefulWidget {
  const CarpoolPage({Key? key}) : super(key: key);

  @override
  State<CarpoolPage> createState() => _CarpoolPageState();
}
StreamSubscription<QuerySnapshot>? _statusMonitor; // Add this line

class _CarpoolPageState extends State<CarpoolPage> with TickerProviderStateMixin {
  final TextEditingController _destinationController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;
  String searchQuery = '';
  StreamSubscription<QuerySnapshot>? _joinedListener;
  late AnimationController _animationController;
  late TabController _tabController;
  bool _isLoading = false;
  bool _hasGlobalPendingRequest = false; // Tracks if user has ANY pending request

  // PAKYAW Brand Colors
  static const Color primaryNavy = Color(0xFF0B2E6B);
  static const Color brightBlue = Color(0xFF1C72DD);
  static const Color lightBlue = Color(0xFF1B99FF);
  static const Color darkGray = Color(0xFF303841);
  static const Color lightBackground = Color(0xFFF3F3F3);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _tabController = TabController(length: 2, vsync: this);

    // 🔹 Start continuous monitoring immediately
    _startContinuousMonitoring();
    _animationController.forward();
  }

  @override
  void dispose() {
    _statusMonitor?.cancel();
    _joinedListener?.cancel();
    _destinationController.dispose();
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// 🔹 NEW: Continuous monitoring of user's carpool status
  void _startContinuousMonitoring() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("❌ No user logged in");
      return;
    }

    debugPrint("🔵 Starting continuous status monitoring for user: ${user.uid}");

    // Monitor all joined documents for this user in real-time
    _statusMonitor = FirebaseFirestore.instance
        .collectionGroup('joined')
        .where('user_id', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      debugPrint("🔵 Status update received. Total documents: ${snapshot.docs.length}");

      bool foundPending = false;
      bool foundAccepted = false;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'];

        debugPrint("🟡 Status check: $status");

        if (status == 'accepted') {
          foundAccepted = true;
          debugPrint("🎉 USER ACCEPTED! Navigating to AcceptedPage...");

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && ModalRoute.of(context)?.isCurrent == true) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const AcceptedPage(),
                  settings: const RouteSettings(name: 'AcceptedPage'),
                ),
              );
            }
          });
          break; // Exit loop if accepted
        } else if (status == 'pending') {
          foundPending = true;
        }
      }

      // Update pending status if no accepted status was found
      if (!foundAccepted && mounted) {
        setState(() {
          _hasGlobalPendingRequest = foundPending;
        });
      }
    }, onError: (error) {
      debugPrint("❌ Status monitor error: $error");
    });

    debugPrint("✅ Continuous monitoring setup complete");
  }


  void _listenForAcceptedCarpools() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("❌ No user logged in");
      return;
    }

    debugPrint("🔵 Starting listener for user: ${user.uid}");

    _joinedListener = FirebaseFirestore.instance
        .collection('carpools')
        .snapshots()
        .listen((snapshot) async {
      debugPrint("🔵 Carpools snapshot received. Total carpools: ${snapshot.docs.length}");

      for (final carpoolDoc in snapshot.docs) {
        final carpoolId = carpoolDoc.id;
        debugPrint("🔵 Checking carpool: $carpoolId");

        try {
          // Check if user has a joined record in this carpool
          final joinedDoc = await FirebaseFirestore.instance
              .collection('carpools')
              .doc(carpoolId)
              .collection('joined')
              .doc(user.uid)
              .get();

          if (joinedDoc.exists) {
            final data = joinedDoc.data();
            debugPrint("✅ Found user in carpool $carpoolId");
            debugPrint("   - Status: ${data?['status']}");

            if (data != null && data['status'] == 'accepted') {
              debugPrint("🎉 USER ACCEPTED! Navigating to AcceptedPage...");

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  debugPrint("🔵 Widget is mounted, checking route...");

                  // Check if already on AcceptedPage
                  if (ModalRoute.of(context)?.isCurrent == true) {
                    debugPrint("🔵 Current route is active, navigating...");

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AcceptedPage(),
                        settings: const RouteSettings(name: 'AcceptedPage'),
                      ),
                    );
                    debugPrint("✅ Navigation triggered!");
                  }
                }
              });
              break;
            } else {
              debugPrint("   - Status is NOT accepted (${data?['status']})");
            }
          } else {
            debugPrint("   - User NOT found in carpool $carpoolId");
          }
        } catch (e) {
          debugPrint("❌ Error checking carpool $carpoolId: $e");
        }
      }
    }, onError: (error) {
      debugPrint("❌ Firestore listener error: $error");
    });

    debugPrint("✅ Listener setup complete");
  }

  void _showSnackBar(String message, {bool isSuccess = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? successGreen : Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 🔹 Send join request
 Future<void> _joinCarpool(String carpoolId, Map<String, dynamic> carpoolData) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar("Please log in first.", isSuccess: false);
      return;
    }

    // Optimistically update UI state
    if (mounted) {
      setState(() {
        _hasGlobalPendingRequest = true;
      });
    }

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final userName = userData['displayName'] ?? user.displayName ?? 'Anonymous User';
    final userEmail = user.email ?? '';
    final userPhoto = user.photoURL ?? '';
    final userPhone = userData['phone'] ?? '';
    final userLocation = userData['location'] ?? {};

    // Create the join request in a single transaction
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final joinedRef = FirebaseFirestore.instance
          .collection('carpools')
          .doc(carpoolId)
          .collection('joined')
          .doc(user.uid);

      transaction.set(joinedRef, {
        'user_id': user.uid,
        'user_name': userName,
        'user_email': userEmail,
        'user_photo': userPhoto,
        'user_phone': userPhone,
        'user_location': userLocation,
        'joined_at': Timestamp.now(),
        'status': 'pending',
      });
    });

    _showSnackBar("Join request sent to driver!");
  } catch (e) {
    // Revert optimistic update if there's an error
    if (mounted) {
      setState(() {
        _hasGlobalPendingRequest = false;
      });
    }
    debugPrint("❌ Join carpool error: $e");
    _showSnackBar("Error joining carpool. Please try again.", isSuccess: false);
  }
}

  /// 🔹 Cancel join request
  Future<void> _cancelJoinRequest(String carpoolId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar("Please log in first.", isSuccess: false);
        return;
      }

      await FirebaseFirestore.instance
          .collection('carpools')
          .doc(carpoolId)
          .collection('joined')
          .doc(user.uid)
          .delete();

      if (mounted) {
        setState(() {
          _hasGlobalPendingRequest = false;
        });
      }

      _showSnackBar("Join request cancelled successfully!");
    } catch (e) {
      debugPrint("❌ Cancel join request error: $e");
      _showSnackBar("Error cancelling request. Please try again.", isSuccess: false);
    }
  }

  /// 🔹 Check if user has pending request for a SPECIFIC carpool
  Future<bool> _hasPendingRequest(String carpoolId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final joinedDoc = await FirebaseFirestore.instance
          .collection('carpools')
          .doc(carpoolId)
          .collection('joined')
          .doc(user.uid)
          .get();

      if (joinedDoc.exists) {
        final data = joinedDoc.data();
        return data?['status'] == 'pending';
      }
      return false;
    } catch (e) {
      debugPrint("❌ Check pending request error: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false, // Remove back button
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryNavy, brightBlue],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.groups,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Carpool',
              style: TextStyle(
                color: darkGray,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: brightBlue,
          indicatorWeight: 3,
          labelColor: brightBlue,
          unselectedLabelColor: Colors.grey[600],
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
            fontSize: 16,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'Montserrat',
            fontSize: 16,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.directions_car),
              text: 'Available Rides',
            ),
            Tab(
              icon: Icon(Icons.poll),
              text: 'Route Polls',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Carpool List
          _buildCarpoolListTab(),
          // Tab 2: Polls
          _buildPollsTab(),
        ],
      ),
    );
  }

  Widget _buildCarpoolListTab() {
    return Column(
      children: [
        // Search bar
        _buildSearchBar(),

        // Carpools list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('carpools')
                .where('status', isEqualTo: 'waiting')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: brightBlue,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading carpools...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              final carpools = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final dropoffName = (data['dropoff']?['name'] ?? '').toString().toLowerCase();
                final pickupName = (data['pickup']?['name'] ?? '').toString().toLowerCase();
                return searchQuery.isEmpty ||
                    dropoffName.contains(searchQuery) ||
                    pickupName.contains(searchQuery);
              }).toList();

              if (carpools.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: carpools.length,
                itemBuilder: (context, index) {
                  final carpool = carpools[index].data() as Map<String, dynamic>;
                  return FadeTransition(
                    opacity: _animationController,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(
                          index * 0.1,
                          1.0,
                          curve: Curves.easeOutCubic,
                        ),
                      )),
                      child: _buildCarpoolCard(carpool, carpools[index].id),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPollsTab() {
    return PassengerPollsWidget();
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _destinationController,
        onChanged: (val) => setState(() => searchQuery = val.trim().toLowerCase()),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: darkGray,
          fontFamily: 'Montserrat',
        ),
        decoration: InputDecoration(
          hintText: "Search destinations...",
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontFamily: 'Montserrat',
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search,
              color: brightBlue,
              size: 24,
            ),
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
            onPressed: () {
              _destinationController.clear();
              setState(() => searchQuery = '');
            },
            icon: Icon(
              Icons.clear,
              color: Colors.grey[500],
            ),
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCarpoolCard(Map<String, dynamic> carpool, String carpoolId) {
    final pickup = carpool['pickup']?['name'] ?? "Unknown pickup";
    final dropoff = carpool['dropoff']?['name'] ?? "Unknown drop-off";
    final driverId = carpool['driverId'] ?? "";
    final fare = (carpool['fare'] ?? 0).toDouble();
    final distance = (carpool['distance_km'] ?? 0).toDouble();
    final departureTime = carpool['suggestedTime'] ?? "Not specified";
    final vehicleId = carpool['vehicleId'] ?? "";
    final vehicleTypeId = carpool['vehicleTypeId'] ?? "";

    // Format location names to be more readable
    String formatLocation(String location) {
      if (location.length > 30) {
        final parts = location.split(',');
        return parts.isNotEmpty ? parts.first.trim() : location;
      }
      return location;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            lightBackground.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with driver info and action button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryNavy, brightBlue],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('Driver')
                        .doc(driverId)
                        .get(),
                    builder: (context, driverSnapshot) {
                      String driverName = "Unknown driver";

                      if (driverSnapshot.hasData && driverSnapshot.data!.exists) {
                        final driverData = driverSnapshot.data!.data() as Map<String, dynamic>;
                        driverName = driverData['name'] ?? "Unknown driver";
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driverName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: darkGray,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          Text(
                            'Driver',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                FutureBuilder<bool>(
                  future: _hasPendingRequest(carpoolId),
                  builder: (context, snapshot) {
                    final hasPendingForThisCard = snapshot.data ?? false;

                    if (hasPendingForThisCard) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red[600]!, Colors.red[700]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isLoading ? null : () async {
                              setState(() => _isLoading = true);
                              await _cancelJoinRequest(carpoolId);
                              setState(() => _isLoading = false);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: _isLoading
                                  ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      return FutureBuilder<Map<String, dynamic>>(
                        future: _checkCarpoolCapacity(carpoolId, vehicleTypeId),
                        builder: (context, capacitySnapshot) {
                          bool isFull = false;
                          int currentPassengers = 0;
                          int maxCapacity = 0;

                          if (capacitySnapshot.hasData) {
                            isFull = capacitySnapshot.data!['isFull'] ?? false;
                            currentPassengers = capacitySnapshot.data!['currentPassengers'] ?? 0;
                            maxCapacity = capacitySnapshot.data!['maxCapacity'] ?? 0;
                          }

                          bool isButtonDisabled = _isLoading || _hasGlobalPendingRequest || isFull;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (capacitySnapshot.hasData) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isFull ? Colors.red[100] : successGreen.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 14,
                                        color: isFull ? Colors.red[700] : successGreen,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$currentPassengers/$maxCapacity',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isFull ? Colors.red[700] : successGreen,
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              Container(
                                decoration: BoxDecoration(
                                  gradient: isButtonDisabled
                                      ? LinearGradient(
                                    colors: [Colors.grey[400]!, Colors.grey[600]!],
                                  )
                                      : LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [primaryNavy, brightBlue, lightBlue],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isButtonDisabled
                                          ? Colors.grey.withOpacity(0.2)
                                          : brightBlue.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: isButtonDisabled ? null : () async {
                                      setState(() => _isLoading = true);
                                      await _joinCarpool(carpoolId, carpool);
                                      setState(() => _isLoading = false);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      child: _isLoading && !_hasGlobalPendingRequest
                                          ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                          : Text(
                                        isFull
                                            ? 'Full'
                                            : (_hasGlobalPendingRequest ? 'Pending...' : 'Join'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Vehicle Type & Capacity Info
            FutureBuilder<Map<String, dynamic>>(
              future: Future.wait([
                FirebaseFirestore.instance.collection('VehicleType').doc(vehicleTypeId).get(),
                FirebaseFirestore.instance
                    .collection('carpools')
                    .doc(carpoolId)
                    .collection('joined')
                    .where('status', isEqualTo: 'accepted')
                    .get(),
              ]).then((results) {
                final vehicleTypeDoc = results[0] as DocumentSnapshot;
                final joinedSnapshot = results[1] as QuerySnapshot;

                Map<String, dynamic> vehicleData = {
                  'type': 'Unknown',
                  'capacity': 4,
                };

                if (vehicleTypeDoc.exists) {
                  final data = vehicleTypeDoc.data() as Map<String, dynamic>;
                  vehicleData = {
                    'type': data['type'] ?? 'Unknown',
                    'capacity': data['capacity'] ?? 4,
                  };
                }

                final currentPassengers = joinedSnapshot.docs.length;
                final capacity = vehicleData['capacity'] as int;

                // Calculate fares
                final currentFare = currentPassengers > 0 ? fare / currentPassengers : fare;
                final estimatedFare = capacity > 0 ? fare / capacity : fare;

                return {
                  ...vehicleData,
                  'currentPassengers': currentPassengers,
                  'currentFare': currentFare,
                  'estimatedFare': estimatedFare,
                };
              }),
              builder: (context, vehicleSnapshot) {
                if (!vehicleSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final vehicleData = vehicleSnapshot.data!;
                final vehicleType = vehicleData['type'] as String;
                final capacity = vehicleData['capacity'] as int;
                final currentPassengers = vehicleData['currentPassengers'] as int;
                final currentFare = vehicleData['currentFare'] as double;
                final estimatedFare = vehicleData['estimatedFare'] as double;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryNavy.withOpacity(0.05),
                        brightBlue.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: brightBlue.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: brightBlue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.directions_car,
                              color: brightBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicleType,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: darkGray,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                Text(
                                  'Capacity: $currentPassengers/$capacity passengers',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 14,
                                        color: successGreen,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Current Fare',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₱${currentFare.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: successGreen,
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                  Text(
                                    'per person now',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey[500],
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.trending_down,
                                        size: 14,
                                        color: warningOrange,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'If Full',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₱${estimatedFare.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: warningOrange,
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                  Text(
                                    'per person',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey[500],
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Route information with departure time
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lightBackground.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: brightBlue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Departure Time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: brightBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.access_time,
                          color: brightBlue,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Departure',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            Text(
                              departureTime,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: darkGray,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Pickup location
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: successGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: successGreen,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pickup',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            Text(
                              pickup,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: darkGray,
                                fontFamily: 'Montserrat',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Route line
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        const SizedBox(width: 20),
                        Container(
                          width: 2,
                          height: 30,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [successGreen, Colors.red[600]!],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Icon(
                          Icons.trending_flat,
                          color: brightBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 12,
                            color: brightBlue,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dropoff location
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.flag,
                          color: Colors.red[600],
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Destination',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            Text(
                              formatLocation(dropoff),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: darkGray,
                                fontFamily: 'Montserrat',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Total Fare information
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [warningOrange.withOpacity(0.1), warningOrange.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: warningOrange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.payments,
                    color: warningOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Total Trip Fare: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  Text(
                    '₱${fare.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: warningOrange,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: successGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Available',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Add this new helper function to check carpool capacity
  Future<Map<String, dynamic>> _checkCarpoolCapacity(String carpoolId, String vehicleTypeId) async {
    try {
      // Get joined passengers count (only accepted ones)
      final joinedSnapshot = await FirebaseFirestore.instance
          .collection('carpools')
          .doc(carpoolId)
          .collection('joined')
          .where('status', isEqualTo: 'accepted')
          .get();

      final currentPassengers = joinedSnapshot.docs.length;

      // Get vehicle type capacity
      final vehicleTypeDoc = await FirebaseFirestore.instance
          .collection('VehicleType')
          .doc(vehicleTypeId)
          .get();

      int maxCapacity = 4; // Default capacity
      if (vehicleTypeDoc.exists) {
        final vehicleTypeData = vehicleTypeDoc.data() as Map<String, dynamic>;
        maxCapacity = (vehicleTypeData['capacity'] ?? 4) as int;
      }

      final isFull = currentPassengers >= maxCapacity;

      return {
        'isFull': isFull,
        'currentPassengers': currentPassengers,
        'maxCapacity': maxCapacity,
      };
    } catch (e) {
      debugPrint('Error checking capacity: $e');
      return {
        'isFull': false,
        'currentPassengers': 0,
        'maxCapacity': 4,
      };
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [brightBlue.withOpacity(0.1), lightBlue.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.groups,
                size: 64,
                color: brightBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              searchQuery.isEmpty
                  ? 'No carpools available right now'
                  : 'No carpools match your search',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: darkGray,
                fontFamily: 'Montserrat',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              searchQuery.isEmpty
                  ? 'Check back later or create a route poll to request a destination'
                  : 'Try searching for a different destination',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Montserrat',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Separate widget for the Polls tab content
class PassengerPollsWidget extends StatefulWidget {
  @override
  State<PassengerPollsWidget> createState() => _PassengerPollsWidgetState();
}

class _PassengerPollsWidgetState extends State<PassengerPollsWidget> {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  // PAKYAW Brand Colors
  static const Color primaryNavy = Color(0xFF0B2E6B);
  static const Color brightBlue = Color(0xFF1C72DD);
  static const Color lightBlue = Color(0xFF1B99FF);
  static const Color darkGray = Color(0xFF303841);
  static const Color lightBackground = Color(0xFFF3F3F3);
  static const Color successGreen = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _ensurePermanentPollsAndCleanup();
  }

  Future<void> _ensurePermanentPollsAndCleanup() async {
    await _cleanupOldUserCreatedPolls();
  }

  /// Generate unique ID for each route option
  String _generateOptionId(Map<String, dynamic> option) {
    return '${option['destinationName']}_${option['pickupName']}_${option['time']}'
        .replaceAll(' ', '_')
        .replaceAll(',', '')
        .toLowerCase();
  }



  Future<void> _cleanupOldUserCreatedPolls() async {
    try {
      final docRef = _fs.collection('polls').doc('destinations');
      final doc = await docRef.get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final options = List<Map<String, dynamic>>.from(data['options'] ?? []);

      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);

      final List<Map<String, dynamic>> keep = [];
      final List<String> toRemoveIds = [];

      for (var opt in options) {
        final createdAtTs = opt['createdAt'] as Timestamp?;
        if (createdAtTs == null) {
          final optionId = opt['optionId'] ?? _generateOptionId(opt);
          toRemoveIds.add(optionId);
        } else {
          final createdAt = createdAtTs.toDate();
          if (createdAt.isAfter(todayMidnight)) {
            keep.add(opt);
          } else {
            final optionId = opt['optionId'] ?? _generateOptionId(opt);
            toRemoveIds.add(optionId);
          }
        }
      }

      if (keep.length != options.length) {
        await docRef.update({'options': keep});

        // Remove votes that selected removed options
        for (var removedId in toRemoveIds) {
          if (removedId.trim().isEmpty) continue;
          final votesQuery = await docRef
              .collection('votes')
              .where('selectedOption', isEqualTo: removedId)
              .get();

          final batch = _fs.batch();
          for (var vDoc in votesQuery.docs) {
            batch.delete(vDoc.reference);
          }
          await batch.commit();
        }
      }
    } catch (e) {
      debugPrint('Cleanup old polls error: $e');
    }
  }

  Future<void> _castVote(BuildContext context, String pollId, String optionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Please log in to vote')));
      }
      return;
    }

    try {
      await _fs
          .collection('polls')
          .doc(pollId)
          .collection('votes')
          .doc(user.uid)
          .set({
        'userId': user.uid,
        'selectedOption': optionId,
        'votedAt': Timestamp.now(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Vote updated!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error voting: $e')));
      }
    }
  }

  void _showAddDestinationDialog(BuildContext context) async {
    String? selectedDestination;
    String? selectedTime;
    List<Map<String, dynamic>> availableRoutes = [];
    bool isLoadingRoutes = true;

    // Fetch routes from Firestore
    try {
      final routesSnapshot = await FirebaseFirestore.instance
          .collection('Routes')
          .get();

      availableRoutes = routesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'destinationName': data['dropoffName'] ?? 'Unknown',
          'pickupName': data['pickupName'] ?? 'Unknown',
          'pickupLat': data['pickupLat'] ?? 0.0,
          'pickupLng': data['pickupLng'] ?? 0.0,
          'dropoffName': data['dropoffName'] ?? 'Unknown',
          'dropoffLat': data['dropoffLat'] ?? 0.0,
          'dropoffLng': data['dropoffLng'] ?? 0.0,
        };
      }).toList();

      isLoadingRoutes = false;
    } catch (e) {
      debugPrint('Error fetching routes: $e');
      isLoadingRoutes = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading routes: $e')),
        );
        return;
      }
    }

    if (availableRoutes.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No routes available in database')),
        );
      }
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (statefulContext, setDialogState) {
          final selectedRoute = availableRoutes.firstWhere(
                (route) => route['destinationName'] == selectedDestination,
            orElse: () => {},
          );

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [primaryNavy, brightBlue]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_location_alt, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Create Poll', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Destination',
                      labelStyle: TextStyle(fontFamily: 'Montserrat', color: darkGray),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: brightBlue, width: 2),
                      ),
                    ),
                    value: selectedDestination,
                    items: availableRoutes
                        .map((route) => DropdownMenuItem<String>(
                      value: route['destinationName'],
                      child: Text(
                        route['destinationName'],
                        style: const TextStyle(fontFamily: 'Montserrat'),
                      ),
                    ))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedDestination = v),
                  ),
                  const SizedBox(height: 16),
                  if (selectedRoute.isNotEmpty) ...[
                    Text(
                      'Pickup Location',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: lightBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: successGreen.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: successGreen, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedRoute['pickupName'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: darkGray,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  InkWell(
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: statefulContext,
                        initialTime: TimeOfDay.now(),
                        builder: (context, child) {
                          return MediaQuery(
                            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        // Round to nearest 15 minutes
                        final totalMinutes = picked.hour * 60 + picked.minute;
                        final roundedMinutes = ((totalMinutes / 15).round() * 15) % 1440;
                        final roundedHour = roundedMinutes ~/ 60;
                        final roundedMinute = roundedMinutes % 60;

                        final roundedTime = TimeOfDay(hour: roundedHour, minute: roundedMinute);
                        setDialogState(() {
                          selectedTime = roundedTime.format(statefulContext);
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Pickup Time',
                        labelStyle: TextStyle(fontFamily: 'Montserrat', color: darkGray),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: brightBlue, width: 2),
                        ),
                        prefixIcon: Icon(Icons.access_time, color: brightBlue),
                      ),
                      child: Text(
                        selectedTime ?? 'Select a time',
                        style: const TextStyle(fontFamily: 'Montserrat'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel', style: TextStyle(fontFamily: 'Montserrat')),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryNavy, brightBlue]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  onPressed: () async {
                    if (selectedDestination == null || selectedTime == null) {
                      if (statefulContext.mounted) {
                        ScaffoldMessenger.of(statefulContext).showSnackBar(
                          const SnackBar(content: Text('Please select destination and time.')),
                        );
                      }
                      return;
                    }
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      Navigator.pop(dialogContext);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please log in first.')),
                        );
                      }
                      return;
                    }

                    final newOption = {
                      'destinationName': selectedRoute['destinationName'],
                      'pickupName': selectedRoute['pickupName'],
                      'pickupLat': selectedRoute['pickupLat'],
                      'pickupLng': selectedRoute['pickupLng'],
                      'dropoffName': selectedRoute['dropoffName'],
                      'dropoffLat': selectedRoute['dropoffLat'],
                      'dropoffLng': selectedRoute['dropoffLng'],
                      'time': selectedTime!,
                      'type': 'userCreated',
                      'createdAt': Timestamp.now(),
                    };
                    newOption['optionId'] = _generateOptionId(newOption);

                    try {
                      final docRef = _fs.collection('polls').doc('destinations');
                      final doc = await docRef.get();
                      bool pollExists = false;
                      String existingOptionId = '';

                      if (doc.exists) {
                        final current = List<Map<String, dynamic>>.from(doc.data()?['options'] ?? []);
                        for (var opt in current) {
                          if (opt['destinationName'] == selectedDestination && opt['time'] == selectedTime) {
                            pollExists = true;
                            existingOptionId = opt['optionId'] ?? _generateOptionId(opt);
                            break;
                          }
                        }
                        if (!pollExists) {
                          current.add(newOption);
                          await docRef.update({'options': current});
                          existingOptionId = newOption['optionId'];
                        }
                      } else {
                        await docRef.set({
                          'options': [newOption],
                          'createdAt': Timestamp.now(),
                        });
                        existingOptionId = newOption['optionId'];
                      }

                      await _fs
                          .collection('polls')
                          .doc('destinations')
                          .collection('votes')
                          .doc(user.uid)
                          .set({
                        'userId': user.uid,
                        'selectedOption': existingOptionId,
                        'votedAt': Timestamp.now(),
                      });

                      Navigator.pop(dialogContext);
                      if (context.mounted) {
                        final parentState = context.findAncestorStateOfType<_CarpoolPageState>();
                        if (parentState != null) {
                          parentState._tabController.animateTo(0);
                          parentState._destinationController.text = selectedRoute['dropoffName'];
                          parentState.setState(() {
                            parentState.searchQuery = selectedRoute['dropoffName'].toString().toLowerCase();
                          });
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(pollExists ? 'Voted for existing route!' : 'Route created and voted!'),
                          ),
                        );
                      }
                    } catch (e) {
                      Navigator.pop(dialogContext);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Create',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: lightBackground,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryNavy, brightBlue, lightBlue],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: brightBlue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddDestinationDialog(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_location_alt, color: Colors.white),
          label: const Text(
            'Create Poll',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _fs.collection('polls').doc('destinations').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading polls'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No routes yet.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final options = List<Map<String, dynamic>>.from(data['options'] ?? []);

          return StreamBuilder<QuerySnapshot>(
            stream: _fs
                .collection('polls')
                .doc('destinations')
                .collection('votes')
                .snapshots(),
            builder: (context, votesSnapshot) {
              Map<String, int> votesCount = {};
              String? userSelectedOptionId;
              final uid = user?.uid;

              for (var opt in options) {
                final optionId = opt['optionId'] ?? _generateOptionId(opt);
                votesCount[optionId] = 0;
              }

              if (votesSnapshot.hasData) {
                for (var doc in votesSnapshot.data!.docs) {
                  final vote = doc.data() as Map<String, dynamic>;
                  final sel = vote['selectedOption'];
                  if (sel != null && votesCount.containsKey(sel)) {
                    votesCount[sel] = votesCount[sel]! + 1;
                  }
                  if (doc.id == uid) {
                    userSelectedOptionId = vote['selectedOption'] as String?;
                  }
                }
              }

              final totalVotes = votesCount.values.fold<int>(0, (a, b) => a + b);

              options.sort((a, b) {
                final da = a['createdAt'] as Timestamp?;
                final db = b['createdAt'] as Timestamp?;
                if (da == null || db == null) return 0;
                return db.compareTo(da); // Most recent first
              });

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final opt = options[i];
                  final optionId = opt['optionId'] ?? _generateOptionId(opt);
                  final name = opt['destinationName']?.toString() ??
                      opt['dropoffName'].toString();
                  final votes = votesCount[optionId] ?? 0;
                  final isSelected = userSelectedOptionId == optionId;
                  final percent = totalVotes > 0
                      ? (votes / totalVotes * 100).toStringAsFixed(1)
                      : '0.0';
                  final type = opt['type'] ?? 'userCreated';

                  // Format location names to be more readable
                  String formatLocation(String location) {
                    if (location.length > 40) {
                      final parts = location.split(',');
                      return parts.isNotEmpty ? parts.first.trim() : location;
                    }
                    return location;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          lightBackground.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(color: brightBlue, width: 2)
                          : Border.all(color: Colors.grey.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _castVote(context, 'destinations', optionId),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with destination and badge
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '$name (${opt['time']})',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: darkGray,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                  ),

                                  if (isSelected)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [brightBlue, lightBlue],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'VOTED',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Route information
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: lightBackground.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: successGreen,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Pickup: ${formatLocation(opt['pickupName'])}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                              fontFamily: 'Montserrat',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.flag,
                                          color: Colors.red[600],
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Drop-off: ${formatLocation(opt['dropoffName'])}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                              fontFamily: 'Montserrat',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Voting progress
                              Row(
                                children: [
                                  Icon(
                                    Icons.how_to_vote,
                                    color: brightBlue,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Votes:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$percent% ($votes)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: brightBlue,
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              LinearProgressIndicator(
                                value: totalVotes > 0 ? votes / totalVotes : 0,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isSelected ? brightBlue : lightBlue,
                                ),
                                minHeight: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                  )  );
                },
              );
            },
          );
        },
      ),
    );
  }
}