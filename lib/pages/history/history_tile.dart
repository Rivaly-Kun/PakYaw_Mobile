import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pakyaw/models/trip_models.dart';
import 'package:pakyaw/pages/history/history_details.dart';
import 'package:pakyaw/shared/size_config.dart';
import 'package:pakyaw/models/trip_models.dart';

class HistoryTile extends StatelessWidget {
  final BaseTrip trip;
  const HistoryTile({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    String formatTimestamp(Timestamp timestamp) {
      DateTime date = timestamp.toDate();
      final DateFormat dateFormat = DateFormat('hh:mm a - MMM d');
      return dateFormat.format(date);
    }

    SizeConfig().init(context);

    // Determine trip type and get display values
    String destination;
    double fare;
    String tripType;
    IconData typeIcon;
    Color typeColor;

    if (trip is PakyawTrip) {
      final pakyawTrip = trip as PakyawTrip;
      destination = pakyawTrip.dropOffAddress;
      fare = pakyawTrip.fare;
      tripType = 'PAKYAW';
      typeIcon = Icons.local_taxi;
      typeColor = Colors.orange;
    } else if (trip is CarpoolTrip) {
      final carpoolTrip = trip as CarpoolTrip;
      destination = carpoolTrip.dropoff['name'] ?? 'Unknown destination';
      fare = carpoolTrip.farePerPassenger;
      tripType = 'CARPOOL';
      typeIcon = Icons.people;
      typeColor = Colors.green;
    } else {
      destination = 'Unknown';
      fare = 0;
      tripType = 'UNKNOWN';
      typeIcon = Icons.help;
      typeColor = Colors.grey;
    }

    return Hero(
      tag: 'trip_${trip.uid}',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Material(
          elevation: 2,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HistoryDetails(trip: trip),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Trip type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              typeIcon,
                              size: 14,
                              color: typeColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tripType,
                              style: TextStyle(
                                color: typeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Timestamp
                      Text(
                        formatTimestamp(trip.createdTime),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Destination
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.red.shade400,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              destination,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  // Fare and status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.payments,
                            size: 18,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '₱${fare.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(trip.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(trip.status).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          trip.status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(trip.status),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'ongoing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}