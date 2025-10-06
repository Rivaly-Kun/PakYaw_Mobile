import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pakyaw/assistants/request_assistant.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/shared/size_config.dart';

import '../../shared/global_var.dart';
import 'location_pick.dart';

class SaveAddressPage extends ConsumerStatefulWidget {
  final String address;
  final String typeOfSavedPlace;
  final String placeId;
  String? oldName;
  SaveAddressPage({super.key, this.oldName, required this.address, required this.typeOfSavedPlace, required this.placeId});

  @override
  ConsumerState<SaveAddressPage> createState() => _SaveAddressPageState();
}

class _SaveAddressPageState extends ConsumerState<SaveAddressPage> {

  TextEditingController name = TextEditingController();

  Future<GeoPoint?> findLatLong(String placeId) async {

    GeoPoint location = const GeoPoint(0,0);

    String detailsUrl = "https://maps.googleapis.com/maps/api/place/details/json?place_id=${widget.placeId}&fields=name,geometry&key=$googleMapKey";

    var details = await RequestAssistant.getRequest(detailsUrl);

    if(details['status'] == 'OK'){
      Map<String, dynamic> json = details['result'];
      location = GeoPoint(json['geometry']['location']['lat'], json['geometry']['location']['lng']);
      return location;
    }else if(details['status'] == 'ZERO_RESULTS'){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No results found. Try again with a different location."))
      );
      return null;
    }else if(details['status'] == 'INVALID_REQUEST'){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No results found. Invalid Request."))
      );
      return null;
    }else if(details['status'] == 'OVER_QUERY_LIMIT'){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No results found. Over Query Limit."))
      );
      return null;
    }else if(details['status'] == 'REQUEST_DENIED'){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request Denied"))
      );
      return null;
    }else if(details['status'] == 'UNKNOWN_ERROR'){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unknown Error."))
      );
      return null;
    }
    return null;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if(widget.oldName != null){
      name.text = widget.oldName!;
    }else if(widget.typeOfSavedPlace != 'New' && widget.typeOfSavedPlace != 'Saved'){
      name.text = widget.typeOfSavedPlace;
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final database = ref.watch(databaseServiceProvider);
    final user = ref.watch(authStateProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Save Address',
          style: TextStyle(
            fontSize: SizeConfig.safeBlockHorizontal * 5,
            color: Colors.black,
            fontWeight: FontWeight.w500
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              ListTile(
                title: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '*',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: SizeConfig.safeBlockHorizontal * 4
                        )
                      ),
                      TextSpan(
                        text: 'Name',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: SizeConfig.safeBlockHorizontal * 4,
                        )
                      )
                    ]
                  ),
                ),
                subtitle: widget.typeOfSavedPlace == 'Work' || widget.typeOfSavedPlace == 'Home' ? Text(
                  widget.typeOfSavedPlace,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: SizeConfig.safeBlockHorizontal * 4.7
                  ),
                ) : TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Park, Date',
                  ),
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: SizeConfig.safeBlockHorizontal * 5
                  ),
                  onChanged: (val) => name.text = val,
                ),
              ),
              ListTile(
                title: RichText(
                  text: TextSpan(
                      children: [
                        TextSpan(
                            text: '*',
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: SizeConfig.safeBlockHorizontal * 5
                            )
                        ),
                        TextSpan(
                            text: 'Address',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: SizeConfig.safeBlockHorizontal * 5,
                            )
                        )
                      ]
                  ),
                ),
                subtitle: GestureDetector(
                  onTap: () async {

                    if(widget.oldName != null){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PickLocation(typeOfSavedPlace: widget.typeOfSavedPlace, placeId: widget.placeId,)));
                    }else{
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PickLocation(typeOfSavedPlace: widget.typeOfSavedPlace, placeId: widget.placeId,)));
                    }

                  },
                  child: Text(
                    widget.address,
                    style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: SizeConfig.safeBlockHorizontal * 4.7,
                      overflow: TextOverflow.ellipsis
                    ),
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
              )
            ],
          ),
          Positioned(
            bottom: SizeConfig.blockSizeVertical *  7,
            left: SizeConfig.blockSizeVertical *  7,
            right: SizeConfig.blockSizeVertical *  7,
            child: Container(
              height: SizeConfig.blockSizeVertical *  7,
              decoration: ShapeDecoration(
                  color: name.text.isNotEmpty ? Colors.black : Colors.grey[700],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0)
                  )
              ),
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black
                  ),
                  onPressed: name.text.isNotEmpty ? () async {

                    GeoPoint? location = await findLatLong(widget.placeId);

                    if(widget.typeOfSavedPlace == 'Home' && location != null){
                      await database.updateSavedHomePlace(user!.uid, widget.address, location, widget.placeId);
                    }else if(widget.typeOfSavedPlace == 'Work' && location != null){
                      await database.updateSavedWorkPlace(user!.uid, widget.address, location, widget.placeId);
                    }else if(widget.typeOfSavedPlace == 'New' && location != null){
                      await database.addNewSavedPlace(user!.uid, name.text, widget.address, location, widget.placeId);
                    }else if(widget.typeOfSavedPlace == 'Saved' && location != null){
                      await database.updateSavedPlace(user!.uid, widget.oldName!, name.text, widget.address, location, widget.placeId);
                    }
                    
                    Navigator.popUntil(context, ModalRoute.withName('/SavedPlaces'));

                  } : null,
                  child: Text(
                    'Save Address',
                    style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 5,
                        fontWeight: FontWeight.bold,
                        color: name.text.isNotEmpty ? Colors.white : Colors.grey[800]
                    ),
                  )
              ),
            ),
          )
        ],
      ),
    );
  }
}
