import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pakyaw/assistants/request_assistant.dart';
import 'package:pakyaw/models/place_predictions.dart';
import 'package:pakyaw/pages/account/save_address_page.dart';
import 'package:pakyaw/shared/choose_location.dart';
import 'package:pakyaw/shared/global_var.dart';
import 'package:pakyaw/shared/loading.dart';
import 'package:pakyaw/shared/size_config.dart';
import 'package:uuid/uuid.dart';

import '../../shared/prediction_tiles.dart';

class PickLocation extends StatefulWidget {
  final String typeOfSavedPlace;
  String? oldName;
  String? placeId;
  PickLocation({super.key, this.oldName, required this.typeOfSavedPlace, this.placeId});

  @override
  State<PickLocation> createState() => _PickLocationState();
}

class _PickLocationState extends State<PickLocation> {

  String? tokenForSession;
  Timer? _debounce;

  bool isLoading = false;

  List<dynamic> listForPlaces = [];

  final TextEditingController searchController = TextEditingController();
  void findPlaces(String placeName) async {
    if(placeName.length > 2){
      String autoCompleteUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&location=11.0384%2C124.6105&radius=14000&strictbounds=true&key=$googleMapKey&sessiontoken=$tokenForSession";

      var res = await RequestAssistant.getRequest(autoCompleteUrl);

      if(res == "Failed"){
        setState(() {
          isLoading = false;
        });
        return;
      }

      if(res['status'] == 'OK'){
        var predictions = res['predictions'];

        var placeList = (predictions as List).map((e) => PlacePredictions.fromJson(e)).toList();
        setState(() {
          listForPlaces = placeList;
          isLoading = false;
        });
      }else if(res['status'] == 'ZERO_RESULTS'){
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No results found. Try again with a different location."))
        );
      }else if(res['status'] == 'INVALID_REQUEST'){
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No results found. Invalid Request."))
        );
      }else if(res['status'] == 'OVER_QUERY_LIMIT'){
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No results found. Over Query Limit."))
        );
      }else if(res['status'] == 'REQUEST_DENIED'){
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Request Denied"))
        );
      }else if(res['status'] == 'UNKNOWN_ERROR'){
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Unknown Error."))
        );
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (searchController.text.length > 2) {
        setState(() {
          isLoading = true;
        });
        findPlaces(searchController.text);
      } else {
        setState(() {
          listForPlaces.clear();
          isLoading = false;
        });

      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _debounce?.cancel();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    tokenForSession = null;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    tokenForSession ??= const Uuid().v4();
    searchController.addListener(_onSearchChanged);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: Container(
          width: double.infinity,
          height: SizeConfig.blockSizeHorizontal * 12,
          decoration: BoxDecoration(
            color: Colors.grey[350],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Enter a location',
              border: InputBorder.none
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if(isLoading) const Loading()
              else if (listForPlaces.isNotEmpty)
                Container(
                padding: EdgeInsets.symmetric(vertical: SizeConfig.blockSizeVertical * 2, horizontal: SizeConfig.blockSizeHorizontal),
                color: Colors.white,
                child: ListView.separated(
                  padding: const EdgeInsets.all(0.0),
                  itemBuilder: (context, index){
                    return PredictionTiles(placePrediction: listForPlaces[index], typeOfSavedPlace: widget.typeOfSavedPlace, oldName: widget.oldName,);
                  },
                  separatorBuilder: (BuildContext context, int index) => const Divider(),
                  itemCount: listForPlaces.length,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),

                ),
              ) else
                Container(
                  height: SizeConfig.blockSizeVertical * 40,
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.blockSizeHorizontal * 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image(
                        image: const AssetImage('assets/design_icon.png'),
                        height: SizeConfig.blockSizeVertical * 25,
                        width: SizeConfig.blockSizeHorizontal * 45,
                        fit: BoxFit.contain,
                      ),
                      Text(
                        'Always using the same locations?',
                        style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 5.7,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      const SizedBox(height: 3.0,),
                      Text(
                        'Save them and make your bookings easily.',
                        style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 4.1,
                        ),
                      )
                    ],
                  ),
              ),
              SizedBox(height: SizeConfig.blockSizeVertical * 20,),
            ],
          ),
        ),
          GestureDetector(
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context) => ChooseLocation(typeOfSavedPlace: widget.typeOfSavedPlace, oldName: widget.oldName, placeId: widget.placeId,)));
            },
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: SizeConfig.blockSizeVertical * 7,
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(15.0), topRight: Radius.circular(15.0))
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map),
                    Text('Choose from Map', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),)
                  ],
                ),
              ),
            ),
          )
      ],
      )
    );
  }
}

