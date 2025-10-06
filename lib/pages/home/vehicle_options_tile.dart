import 'package:flutter/material.dart';

class VehicleOptionsTile extends StatelessWidget {

  final String vehicleType;

  const VehicleOptionsTile({super.key, required this.vehicleType});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 3.0),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0
        ),
        onPressed: (){
          print(vehicleType);

        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(
              image: AssetImage('assets/$vehicleType.png'),
              height: 50.0,
              width: 50.0,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10.0,),
            Text(
              vehicleType,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
