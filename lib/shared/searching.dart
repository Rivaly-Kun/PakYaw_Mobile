import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Searching extends StatelessWidget {
  const Searching({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: const Column(
        children: [
          Text(
            'Finding your Rider',
            style: TextStyle(
              fontSize: 25.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20.0,),
          SpinKitThreeInOut(
          color: Colors.black,
          size: 20.0,
        ),
          SizedBox(height: 10.0,)
      ]
      ),
    );
  }
}
