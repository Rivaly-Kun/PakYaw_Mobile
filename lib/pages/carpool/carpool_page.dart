import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pakyaw/pages/carpool/accepted_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pakyaw/pages/carpool/poll_page.dart';


class CarpoolPage extends StatefulWidget {
  const CarpoolPage({Key? key}) : super(key: key);

  @override
  State<CarpoolPage> createState() => _CarpoolPageState();
}

class _CarpoolPageState extends State<CarpoolPage> {
  final TextEditingController _destinationController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;
  String searchQuery = '';
  StreamSubscription<QuerySnapshot>? _joinedListener;

  @override
  void initState() {
    super.initState();

    // 🔹 Slight delay ensures Firestore & context are ready
    Future.delayed(const Duration(milliseconds: 300), _checkIfAlreadyJoined);
    _listenForAcceptedCarpools();
  }

  @override
  void dispose() {
    _joinedListener?.cancel();
    _destinationController.dispose();
    super.dispose();
  }

  /// 🔹 Immediately check if user has already joined a carpool
  Future<void> _checkIfAlreadyJoined() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final query = await FirebaseFirestore.instance
          .collectionGroup('joined')
          .where('user_id', isEqualTo: user.uid)
          .get();

      for (final doc in query.docs) {
        final data = doc.data();
        print("🟡 Initial join check: ${data['status']}");
        if (data['status'] == 'accepted') {
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AcceptedPage()),
              );
            });
          }
          return;
        } else if (data['status'] == 'pending') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("You already have a pending join request."),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Error in _checkIfAlreadyJoined: $e");
    }
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
            debugPrint("   - User ID: ${data?['user_id']}");
            debugPrint("   - Joined at: ${data?['joined_at']}");

            // Check if joined within last 10 minutes
            final joinedAt = (data?['joined_at'] as Timestamp?)?.toDate();
            if (joinedAt != null) {
              final now = DateTime.now();
              final difference = now.difference(joinedAt).inMinutes;

              debugPrint("   - Joined $difference minutes ago");

              if (difference > 10) {
                debugPrint("⚠️ Carpool is too old (${difference} minutes), skipping");
                continue; // Skip this carpool, it's older than 10 minutes
              }
            }
            if (data != null && data['status'] == 'accepted') {
              debugPrint("🎉 USER ACCEPTED! Navigating to AcceptedPage...");

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  debugPrint("🔵 Widget is mounted, checking route...");

                  // Check if already on AcceptedPage
                  if (ModalRoute.of(context)?.isCurrent == true) {
                    debugPrint("🔵 Current route is active, navigating...");

                    // Check if AcceptedPage is already in stack
                    bool canNavigate = true;
                    Navigator.popUntil(context, (route) {
                      if (route.settings.name == 'AcceptedPage') {
                        canNavigate = false;
                      }
                      return true;
                    });

                    if (canNavigate) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AcceptedPage(),
                          settings: const RouteSettings(name: 'AcceptedPage'),
                        ),
                      );
                      debugPrint("✅ Navigation triggered!");
                    } else {
                      debugPrint("⚠️ AcceptedPage already in stack");
                    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Carpools"),
        actions: [
          IconButton(
            icon: const Icon(Icons.poll),
            tooltip: 'View Route Polls',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PassengerPollsPage()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _destinationController,
              onChanged: (val) => setState(() => searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search destination...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('carpools')
            .where('status', isEqualTo: 'waiting')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No carpools available right now."));
          }

          final carpools = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final dropoffName = (data['dropoff']?['name'] ?? '').toString().toLowerCase();
            return searchQuery.isEmpty || dropoffName.contains(searchQuery);
          }).toList();

          if (carpools.isEmpty) {
            return const Center(child: Text("No carpools match your search."));
          }

          return ListView.builder(
            itemCount: carpools.length,
            itemBuilder: (context, index) {
              final carpool = carpools[index].data() as Map<String, dynamic>;
              final pickup = carpool['pickup']?['name'] ?? "Unknown pickup";
              final dropoff = carpool['dropoff']?['name'] ?? "Unknown drop-off";
              final driverName = carpool['driver_name'] ?? "Unknown driver";
              final fare = (carpool['fare'] ?? 0).toDouble();
              final distance = (carpool['distance_km'] ?? 0).toDouble();

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: const Icon(Icons.directions_car, color: Colors.blue),
                  title: Text("$pickup ➜ $dropoff"),
                  subtitle: Text(
                    "Driver: $driverName\nFare: ₱${fare.toStringAsFixed(2)} • ${distance.toStringAsFixed(2)} km",
                  ),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await _joinCarpool(carpools[index].id, carpool);
                    },
                    child: const Text("Join"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 🔹 Send join request
  Future<void> _joinCarpool(String carpoolId, Map<String, dynamic> carpoolData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in first.")),
        );
        return;
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final userName = userData['displayName'] ?? user.displayName ?? 'Anonymous User';
      final userEmail = user.email ?? '';
      final userPhoto = user.photoURL ?? '';
      final userPhone = userData['phone'] ?? '';
      final userLocation = userData['location'] ?? {};

      await FirebaseFirestore.instance
          .collection('carpools')
          .doc(carpoolId)
          .collection('joined')
          .doc(user.uid)
          .set({
        'user_id': user.uid,
        'user_name': userName,
        'user_email': userEmail,
        'user_photo': userPhoto,
        'user_phone': userPhone,
        'user_location': userLocation,
        'joined_at': Timestamp.now(),
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Join request sent to driver!")),
      );
    } catch (e) {
      debugPrint("❌ Join carpool error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error joining carpool: $e")),
      );
    }
  }
}
