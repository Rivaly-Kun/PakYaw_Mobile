import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/pages/account/location_pick.dart';
import 'package:pakyaw/pages/account/save_address_page.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/providers/user_provider.dart';
import 'package:pakyaw/services/database.dart';
import 'package:pakyaw/shared/loading.dart';
import 'package:pakyaw/shared/size_config.dart';

class SavedPlaces extends ConsumerStatefulWidget {
  const SavedPlaces({super.key});

  @override
  ConsumerState<SavedPlaces> createState() => _SavedPlacesState();
}

class _SavedPlacesState extends ConsumerState<SavedPlaces> {

  showConfirmModal(DatabaseService database, String name, String address, String placeId, GeoPoint location, String uid, BuildContext context1){
    SizeConfig().init(context1);
    showDialog(context: context, builder: (context) => AlertDialog(
      content: Text(
        'Remove "$name"?',
        style: TextStyle(
            fontSize: SizeConfig.safeBlockHorizontal * 6,
            color: Colors.black,
            fontWeight: FontWeight.w500
        ),
      ),
      actions: [
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                decoration: ShapeDecoration(
                    color: Colors.grey[350],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0)
                    )
                ),
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.safeBlockHorizontal * 4),
                child: TextButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  child: Text('Cancel', style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4, color: Colors.black),),

                ),
              ),
              Container(
                decoration: ShapeDecoration(
                    color: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0)
                    )
                ),
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.safeBlockHorizontal * 4),
                child: TextButton(
                  onPressed: () async {
                    await database.removeNewSavedPlace(uid, name, address, location, placeId);
                    Navigator.pop(context);
                  },
                  child: Text('Remove', style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4, color: Colors.white),),

                ),
              ),
            ],
          ),
        )
      ],
    ));
  }
  showConfirmModalHorW(DatabaseService database, String name, String uid, BuildContext context1){
    SizeConfig().init(context1);
    showDialog(context: context, builder: (context) => AlertDialog(
      content: Text(
        'Remove "$name"?',
        style: TextStyle(
            fontSize: SizeConfig.safeBlockHorizontal * 6,
            color: Colors.black,
            fontWeight: FontWeight.w500
        ),
      ),
      actions: [
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                decoration: ShapeDecoration(
                    color: Colors.grey[350],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0)
                    )
                ),
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.safeBlockHorizontal * 4),
                child: TextButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  child: Text('Cancel', style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4, color: Colors.black),),

                ),
              ),
              Container(
                decoration: ShapeDecoration(
                    color: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0)
                    )
                ),
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.safeBlockHorizontal * 4),
                child: TextButton(
                  onPressed: () async {
                    if(name == 'Home'){
                      await database.removeSavedHomePlace(uid);
                    }else if(name == 'Work'){
                      await database.removeSavedWorkPlace(uid);
                    }
                    Navigator.pop(context);
                  },
                  child: Text('Remove', style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4, color: Colors.white),),

                ),
              ),
            ],
          ),
        )
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final user = ref.watch(usersProvider);
    final userAuth = ref.watch(authStateProvider).value;
    final database = ref.watch(databaseServiceProvider);
    return user.when(
      data: (data){
        if(data != null) {
          final savedPlaces = data.savedPlaces;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Saved Places'),
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                children: [
                   savedPlaces[0]['address'] == '' ? ListTile(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PickLocation(typeOfSavedPlace: 'Home')));
                    },
                    leading: const Icon(Icons.home),
                    title: Text(
                      'Home',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: SizeConfig.safeBlockHorizontal * 4
                      ),
                    ),
                  ) : ListTile(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SaveAddressPage(address: savedPlaces[0]['address'], typeOfSavedPlace: 'Home', placeId: savedPlaces[0]['place_id'])));
                    },
                    leading: const Icon(Icons.home),
                    title: Text(
                      'Home',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: SizeConfig.safeBlockHorizontal * 4
                      ),
                    ),
                     subtitle: Text(
                       savedPlaces[0]['address'],
                       style: TextStyle(
                         fontSize: SizeConfig.safeBlockHorizontal * 3.7,
                         color: Colors.black,
                         overflow: TextOverflow.ellipsis
                       ),
                     ),
                     trailing: IconButton(
                       onPressed: () async {
                         showConfirmModalHorW(database, 'Home', userAuth!.uid, context);
                       },
                       icon: const Icon(Icons.delete),
                     ),
                  ),
                  const Divider(height: 10.0,),
                  savedPlaces[1]['address'] == '' ? ListTile(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PickLocation(typeOfSavedPlace: 'Work')));
                    },
                    leading: const Icon(Icons.luggage),
                    title: Text(
                      'Work',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: SizeConfig.safeBlockHorizontal * 4
                      ),
                    ),
                  ) : ListTile(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SaveAddressPage(address: savedPlaces[1]['address'], typeOfSavedPlace: 'Work', placeId: savedPlaces[1]['place_id'])));
                    },
                    leading: const Icon(Icons.luggage),
                    title: Text(
                      'Work',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: SizeConfig.safeBlockHorizontal * 4
                      ),
                    ),
                    subtitle: Text(
                      savedPlaces[1]['address'],
                      style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 3.7,
                          color: Colors.black,
                          overflow: TextOverflow.ellipsis
                      ),
                    ),
                    trailing: IconButton(
                      onPressed: () async {
                        showConfirmModalHorW(database, 'Work', userAuth!.uid, context);
                      },
                      icon: const Icon(Icons.delete),
                    ),
                  ),
                  const Divider(),
                  (savedPlaces.length > 2) ? ListView.separated(
                    padding: const EdgeInsets.all(0.0),
                    itemBuilder: (context, index){
                      return ListTile(
                        onTap: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context) => SaveAddressPage(address: savedPlaces[index + 2]['address'], typeOfSavedPlace: 'Saved', placeId: savedPlaces[index + 2]['place_id'], oldName: savedPlaces[index + 2]['name'],)));
                        },
                        leading: const Icon(Icons.place),
                        title: Text(
                          savedPlaces[index + 2]['name'],
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: SizeConfig.safeBlockHorizontal * 3.7
                          ),
                        ),
                        subtitle: Text(
                          savedPlaces[index + 2]['address'],
                          style: TextStyle(
                              fontSize: SizeConfig.safeBlockHorizontal * 3.7,
                              color: Colors.black,
                              overflow: TextOverflow.ellipsis
                          ),
                        ),
                        trailing: IconButton(
                          onPressed: () {
                            showConfirmModal(database, savedPlaces[index + 2]['name'], savedPlaces[index + 2]['address'], savedPlaces[index + 2]['place_id'], savedPlaces[index + 2]['location'], userAuth!.uid, context);
                          },
                          icon: const Icon(Icons.delete),
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) => const Divider(),
                    itemCount: savedPlaces.length - 2,
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                  ) : Container(),
                  ListTile(
                    contentPadding: EdgeInsets.only(left: SizeConfig.blockSizeHorizontal * 4.5),
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PickLocation(typeOfSavedPlace: 'New',)));
                    },
                    leading: const Icon(Icons.add),
                    title: Text(
                      'New',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: SizeConfig.safeBlockHorizontal * 4
                      ),
                    ),
                    subtitle: Text(
                      'Add your favorite places',
                      style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 3.7,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500
                      ),
                    ),
                  ),
                  const Divider(height: 10.0,),
                ],
              ),
            ),
          );
        }else{
          return const Loading();
        }
      },
      error: (e, stack) => Text('error $e'),
      loading: () => const Loading(),

    );
  }
}
