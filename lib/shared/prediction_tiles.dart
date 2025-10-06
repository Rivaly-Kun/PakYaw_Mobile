import 'package:flutter/material.dart';
import 'package:pakyaw/shared/size_config.dart';

import '../models/place_predictions.dart';
import '../pages/account/save_address_page.dart';
class PredictionTiles extends StatelessWidget {

  final PlacePredictions placePrediction;
  final String typeOfSavedPlace;
  String? oldName;

  PredictionTiles({super.key, this.oldName, required this.placePrediction, required this.typeOfSavedPlace});

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Container(
      child: Column(
        children: [
          SizedBox(width: SizeConfig.blockSizeHorizontal * 3,),
          GestureDetector(
            onTap: (){
              if(oldName == null){
                Navigator.push(context, MaterialPageRoute(builder: (context) => SaveAddressPage(address: placePrediction.mainText, typeOfSavedPlace: typeOfSavedPlace, placeId: placePrediction.placeId,)));
              }else{
                Navigator.push(context, MaterialPageRoute(builder: (context) => SaveAddressPage(address: placePrediction.mainText, typeOfSavedPlace: typeOfSavedPlace, placeId: placePrediction.placeId, oldName: oldName,)));
              }

            },
            child: Row(
              children: [
                const Icon(Icons.add_location),
                SizedBox(width: SizeConfig.blockSizeHorizontal * 2,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: SizeConfig.blockSizeVertical,),
                      Text(
                        placePrediction.mainText,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 4.5
                        ),
                      ),
                      SizedBox(height: SizeConfig.blockSizeVertical,),
                      Text(
                        placePrediction.secondaryText,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 4,
                            color: Colors.grey
                        ),
                      ),
                      SizedBox(height: SizeConfig.blockSizeVertical,),

                    ],
                  ),
                )
              ],
            ),
          ),
          SizedBox(width: SizeConfig.blockSizeHorizontal * 3,),
        ],
      ),
    );
  }
}