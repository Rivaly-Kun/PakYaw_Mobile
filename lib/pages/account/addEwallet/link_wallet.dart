import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_provider.dart';
import '../../../services/database.dart';
import '../../../shared/size_config.dart';

class LinkWallet extends ConsumerWidget {
  final String mobileNum;
  const LinkWallet({super.key, required this.mobileNum});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAuth = ref.read(authStateProvider).value;
    String id = userAuth!.uid;
    DatabaseService databaseService = DatabaseService();
    SizeConfig().init(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Linking E-wallet',
          style: TextStyle(
              fontSize: SizeConfig.safeBlockHorizontal * 5,
              color: Colors.black,
              fontWeight: FontWeight.w500
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0.0,
            child: Container(
              color: Colors.blue[800],
              height: SizeConfig.blockSizeVertical * 23,
              width: SizeConfig.screenWidth,
            ),
          ),
          Positioned(
            top: SizeConfig.blockSizeVertical * 9,
            left: SizeConfig.blockSizeHorizontal * 5,
            right: SizeConfig.blockSizeHorizontal * 5,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: SizeConfig.blockSizeVertical * 3, horizontal: SizeConfig.blockSizeHorizontal * 5),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: const Offset(0,3), // changes position of shadow
                  ),
                ],
              ),
              height: SizeConfig.blockSizeVertical * 30.2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enjoy a faster checkout experience!',
                    style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 4,
                        color: Colors.black,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  Text(
                    'Link your E-Wallet account for one-click checkout on all future purchases with this partner.',
                    style: TextStyle(
                      fontSize: SizeConfig.safeBlockHorizontal * 3.5,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: SizeConfig.blockSizeVertical * 1.2,),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800]
                      ),
                      onPressed: () async {
                        try{
                          await databaseService.add_Ewallet(
                              id, mobileNum);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Successfully added E-wallet"))
                          );
                          Navigator.popUntil(context, ModalRoute.withName('/PaymentMethods'));
                        }catch(e){
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("$e"))
                          );
                        }
                      },
                      child: Text(
                        'Link',
                        style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
