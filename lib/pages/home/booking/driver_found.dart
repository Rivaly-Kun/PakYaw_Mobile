import 'package:flutter/material.dart';
import 'package:pakyaw/shared/size_config.dart';

class DriverFound extends StatelessWidget {
  final Map<String, dynamic> driver;
  final Map<String, dynamic> vehicle;
  const DriverFound({super.key, required this.driver, required this.vehicle});

  @override
  Widget build(BuildContext context) {

    int getDuration(String time){
      int seconds = int.parse(time.replaceAll('s', ''));
      if(seconds >= 60){
        int minute = (seconds/60).round();
        return minute;
      }else{
        return seconds;
      }

    }
      SizeConfig().init(context);
    int duration = getDuration(driver['duration']);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      decoration: BoxDecoration(
        color: Colors.grey[350],
        borderRadius: const BorderRadius.all(Radius.circular(15.0))
      ),
      child: Column(
        children: [
          ListTile(
            leading: Image.network(vehicle['vehicle_image'], width: SizeConfig.blockSizeHorizontal * 14, height: SizeConfig.blockSizeVertical * 7, fit: BoxFit.cover,),
            title: Text(vehicle['model'], style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 5, fontWeight: FontWeight.bold),),
            subtitle: Text('PLATE: ${vehicle['plate_num']}', style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4.5, fontWeight: FontWeight.bold, color: Colors.black),),
          ),
          ListTile(
            leading: Container(
              width: SizeConfig.blockSizeHorizontal * 10,
              height: SizeConfig.blockSizeVertical * 5,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(driver['driver_profile']),
                ),
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            title: Text(driver['driver_name'], style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4, fontWeight: FontWeight.w500, overflow: TextOverflow.ellipsis),),
            subtitle: Row(
              children: [
                Icon(Icons.star, size: SizeConfig.safeBlockHorizontal * 6,),
                Text('${driver['rating'].toStringAsFixed(1)}', style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4,),)
              ],
            ),
            trailing: duration < 1 ? SizedBox(
              width: SizeConfig.blockSizeHorizontal * 19.5,
              child: Text(
                duration <= 60 ? 'Arriving:  $duration sec' : 'Arriving:  $duration minute/s',
                style: TextStyle(
                  fontSize: SizeConfig.safeBlockHorizontal * 4,
                  fontWeight: FontWeight.w500,
                  color: Colors.black
                ),
                maxLines: 2,
              ),
            ) : SizedBox(
              width: SizeConfig.blockSizeHorizontal,
            ),
          )
        ],
      ),
    );
  }
}
