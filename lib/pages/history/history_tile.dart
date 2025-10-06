import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pakyaw/models/history_ride_model.dart';
import 'package:pakyaw/pages/history/history_details.dart';
import 'package:pakyaw/shared/size_config.dart';

class HistoryTile extends StatelessWidget {

  final Trips trip;

  const HistoryTile({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {

    String formatTimestamp(Timestamp timestamp){
      DateTime date = timestamp.toDate();
      final DateFormat dateFormat = DateFormat('hh:mm a - MMM d');
      return dateFormat.format(date);
    }

    SizeConfig().init(context);
    double fare = trip.fare + (trip.fare * trip.vatTax) + (trip.fare * trip.ccTax);
    double promoDiscount = fare * trip.promo['discount'];
    double discountFare = fare - promoDiscount;
    double spDiscount = discountFare * trip.discount['discount'];
    double discountFare2 = discountFare - spDiscount;
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Card(
        margin: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 0.0),
        child: ListTile(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryDetails(trip: trip))),
          title: Text(
            trip.dropOffAddress,
            style: TextStyle(
              fontSize: SizeConfig.safeBlockHorizontal * 5.5,
              fontWeight: FontWeight.bold,
              overflow: TextOverflow.ellipsis
            ),
          ),
          subtitle: Text(
            formatTimestamp(trip.createdTime),
            style: TextStyle(
              fontSize: SizeConfig.safeBlockHorizontal * 4,
            ),
          ),
          trailing: Text(
            '₱${discountFare2.toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: SizeConfig.safeBlockHorizontal * 4,
                fontWeight: FontWeight.bold
            ),
          ),
        ),
      ),
    );
  }
}
