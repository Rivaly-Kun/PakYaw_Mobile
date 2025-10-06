import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/providers/user_provider.dart';
import 'package:pakyaw/services/database.dart';
import 'package:pakyaw/shared/size_config.dart';

import '../../shared/loading.dart';
import 'addEwallet/login_to_link.dart';

class PasswordChange extends ConsumerStatefulWidget {
  const PasswordChange({super.key});

  @override
  ConsumerState<PasswordChange> createState() => _PasswordChangeState();
}

class _PasswordChangeState extends ConsumerState<PasswordChange> {

  DatabaseService database = DatabaseService();
  String? id;
  int linkedAccount = 0;
  Map<String, dynamic>eWallet = {};

  void getLinkedAccount(String userId) async {
    try{
      int result = await database.getCurrentlyLinked(userId);
      setState(() {
        linkedAccount = result;
      });
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error occurred: $e"))
      );
    }
  }
  void getEwallet(String userId) async {
    try{
      final result = await database.get_Ewallet(userId);
      setState(() {
        eWallet = result;
      });
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error occurred: $e"))
      );
    }
  }
  
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    final user = ref.read(usersProvider).value;
    id = user!.uid;
    getEwallet(id!);
    getLinkedAccount(id!);
  }

  final _formkey = GlobalKey<FormState>();

  bool isViewable = false;
  bool isViewable2 = false;
  TextEditingController e_walletNum = TextEditingController();

  String error = '';

  showConfirmModal(DatabaseService database, String method, String uid, BuildContext context1){
    SizeConfig().init(context1);
    showDialog(context: context, builder: (context) => AlertDialog(
      content: Text(
        'Are you sure you want to remove $method?',
        style: TextStyle(
          fontSize: SizeConfig.safeBlockHorizontal * 5,
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
                    if(method == 'E-wallet'){
                      try{
                        final result = await database.remove_Ewallet(uid);
                        print(result);
                      }catch(e){
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error occurred: $e"))
                        );
                      }

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
    final database = ref.watch(databaseServiceProvider);
    final user = ref.watch(authStateProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Payment Methods',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(30.0, 20.0, 30.0, 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            linkedAccount != 0 ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Currently added',
                  style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: SizeConfig.safeBlockHorizontal * 5,
                      fontWeight: FontWeight.w500
                  ),
                ),
                SizedBox(height: SizeConfig.blockSizeVertical * 2,),
                eWallet.isNotEmpty ? ListTile(
                  contentPadding: const EdgeInsets.only(left: 0),
                  leading: Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage("assets/Google.png"),
                        fit: BoxFit.cover,
                      ),
                      color: Colors.grey[350],
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: const Text(
                    'E-wallet',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 20.0
                    ),
                  ),
                  subtitle: Text(
                    eWallet['account_number'],
                    style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 4,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500
                    ),
                  ),
                  trailing: GestureDetector(
                    onTap: (){
                      showConfirmModal(database, 'E-wallet', id!, context);
                    },
                    child: const Icon(Icons.delete),
                  ),
                ) : Container(),
              ],
            ) : Container(),
            SizedBox(height: SizeConfig.blockSizeVertical * 3,),
            linkedAccount == 0 ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add methods',
                  style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: SizeConfig.safeBlockHorizontal * 5,
                      fontWeight: FontWeight.w500
                  ),
                ),
                SizedBox(height: SizeConfig.blockSizeVertical * 2,),
                eWallet.isEmpty ? ListTile(
                  contentPadding: const EdgeInsets.only(left: 0),
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginToLink()));
                  },
                  leading: Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage("assets/Google.png"),
                        fit: BoxFit.cover,
                      ),
                      color: Colors.grey[350],
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    'E-wallet',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: SizeConfig.safeBlockHorizontal *  5,
                        fontWeight: FontWeight.w500
                    ),
                  ),
                ) : Container(),
              ],
            ) : Container()
          ],
        ),
      ),
    );
  }
}
