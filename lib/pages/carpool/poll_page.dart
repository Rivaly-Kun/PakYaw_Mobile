import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PassengerPollsPage extends StatefulWidget {
  const PassengerPollsPage({Key? key}) : super(key: key);

  @override
  State<PassengerPollsPage> createState() => _PassengerPollsPageState();
}

class _PassengerPollsPageState extends State<PassengerPollsPage> {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  String searchQuery = '';

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
    _cleanupOldUserCreatedPolls();
  }

  /// Generate unique ID for each route option
  String _generateOptionId(Map<String, dynamic> option) {
    return '${option['destinationName']}_${option['pickupName']}_${option['time']}'
        .replaceAll(' ', '_')
        .replaceAll(',', '')
        .toLowerCase();
  }

  /// Delete only user-created options that are older than today
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
        final type = opt['type'] ?? 'userCreated';
        if (type == 'permanent') {
          keep.add(opt);
        } else {
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

  void _showAddDestinationDialog(BuildContext context) {
    String? selectedDestination;
    Map<String, dynamic>? selectedRouteInfo;
    String? selectedTime;

    showDialog(
      context: context,
      builder: (dialogContext) => StreamBuilder<QuerySnapshot>(
        stream: _fs.collection('routes').snapshots(),
        builder: (context, routesSnapshot) {
          if (!routesSnapshot.hasData) {
            return AlertDialog(
              content: Center(child: CircularProgressIndicator()),
            );
          }

          // Get unique destination names from routes
          final routes = routesSnapshot.data!.docs;
          final Map<String, Map<String, dynamic>> destinationMapping = {};

          for (var doc in routes) {
            final data = doc.data() as Map<String, dynamic>;
            final destName = data['dropoffName'] as String?;
            if (destName != null && destName.isNotEmpty) {
              destinationMapping[destName] = {
                'pickupLabel': data['pickupName'],
                'pickupName': data['pickupName'],
                'pickupLat': data['pickupLat'],
                'pickupLng': data['pickupLng'],
                'dropoffName': data['dropoffName'],
                'dropoffLat': data['dropoffLat'],
                'dropoffLng': data['dropoffLng'],
              };
            }
          }

          return StatefulBuilder(
            builder: (statefulContext, setDialogState) {
              final pickupInfo = selectedDestination != null
                  ? destinationMapping[selectedDestination!]
                  : null;

              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
                        Icons.add_location_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Create Route',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Destination Dropdown
                      if (destinationMapping.isEmpty)
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No routes available. Please add routes first.',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: selectedDestination,
                          decoration: InputDecoration(
                            labelText: 'Select Destination',
                            labelStyle: TextStyle(
                              fontFamily: 'Montserrat',
                              color: darkGray,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: brightBlue, width: 2),
                            ),
                            prefixIcon: Icon(Icons.location_city, color: brightBlue),
                          ),
                          items: destinationMapping.keys.map((destination) {
                            return DropdownMenuItem<String>(
                              value: destination,
                              child: Text(
                                destination,
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedDestination = value;
                              selectedRouteInfo = value != null ? destinationMapping[value] : null;
                            });
                          },
                        ),

                      const SizedBox(height: 16),

                      // Time Selection with Clock Picker (15-minute increments)
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
                            labelStyle: TextStyle(
                              fontFamily: 'Montserrat',
                              color: darkGray,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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

                      const SizedBox(height: 16),

                      // Pickup Location Display (Read-only)
                      if (pickupInfo != null) ...[
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
                              Icon(
                                Icons.location_on,
                                color: successGreen,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  pickupInfo['pickupLabel'],
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
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontFamily: 'Montserrat'),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryNavy, brightBlue],
                      ),
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
                              const SnackBar(
                                content: Text('Please select destination and time.'),
                              ),
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

                        final destInfo = destinationMapping[selectedDestination!]!;

                        final newOption = {
                          'destinationName': selectedDestination!,
                          'pickupName': destInfo['pickupName'],
                          'pickupLat': destInfo['pickupLat'],
                          'pickupLng': destInfo['pickupLng'],
                          'dropoffName': destInfo['dropoffName'],
                          'dropoffLat': destInfo['dropoffLat'],
                          'dropoffLng': destInfo['dropoffLng'],
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
                            final current = List<Map<String, dynamic>>.from(
                                doc.data()?['options'] ?? []);

                            // Check if poll with same destination + time already exists
                            for (var opt in current) {
                              if (opt['destinationName'] == selectedDestination! &&
                                  opt['time'] == selectedTime!) {
                                pollExists = true;
                                existingOptionId = opt['optionId'] ?? _generateOptionId(opt);
                                break;
                              }
                            }

                            if (!pollExists) {
                              // Create new poll
                              current.add(newOption);
                              await docRef.update({'options': current});
                              existingOptionId = newOption['optionId'];
                            }
                          } else {
                            // Create document and first poll
                            await docRef.set({
                              'options': [newOption],
                              'createdAt': Timestamp.now()
                            });
                            existingOptionId = newOption['optionId'];
                          }

                          // Auto-vote user to the poll (new or existing)
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

                          // Show success message
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(pollExists
                                    ? 'Voted for existing route!'
                                    : 'Route created and voted!'),
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
      appBar: AppBar(
        title: const Text(
          'Carpool Polls',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: brightBlue,
      ),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.poll_outlined, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'No routes yet.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create your first poll!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            );
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
                final ta = a['type'] == 'permanent' ? 0 : 1;
                final tb = b['type'] == 'permanent' ? 0 : 1;
                if (ta != tb) return ta - tb;
                final da = a['createdAt'] as Timestamp?;
                final db = b['createdAt'] as Timestamp?;
                if (da == null || db == null) return 0;
                return db.compareTo(da);
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
                                  if (type == 'permanent')
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            successGreen,
                                            successGreen.withOpacity(0.8)
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'PERMANENT',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
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
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}