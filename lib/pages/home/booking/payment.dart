import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/providers/user_provider.dart';
import 'package:pakyaw/shared/error.dart';
import 'package:pakyaw/shared/loading.dart';
import 'package:pakyaw/shared/size_config.dart';

import '../../../services/database.dart';

class PaymentWay extends ConsumerStatefulWidget {
  final Function paymentMethod;
  const PaymentWay({super.key, required this.paymentMethod});

  @override
  ConsumerState<PaymentWay> createState() => _PaymentWayState();
}

class _PaymentWayState extends ConsumerState<PaymentWay> {

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

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.blockSizeHorizontal * 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.blockSizeVertical * 1.5,),
          Text(
            'Payment Method',
            style: TextStyle(
                fontSize: SizeConfig.safeBlockHorizontal * 6,
                color: Colors.black,
                fontWeight: FontWeight.w500
            ),
          ),
          SizedBox(height: SizeConfig.blockSizeVertical * 2,),
          ListTile(
            leading: Icon(Icons.money, size: SizeConfig.safeBlockHorizontal * 10,),
            shape: const Border(
                bottom: BorderSide(
                    color: Colors.grey,
                    width: 1.0
                )
            ),
            onTap: (){
              widget.paymentMethod('Cash', '');
              Navigator.pop(context);
            },
            title: Text(
              'Cash',
              style: TextStyle(
                  fontSize: SizeConfig.safeBlockHorizontal * 5,
                  color: Colors.black,
                  fontWeight: FontWeight.w500
              ),
            ),
          ),
          eWallet.isNotEmpty ? ListTile(
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
            onTap: (){
              widget.paymentMethod('E-wallet', eWallet['account_number']);
              Navigator.pop(context);
            },
            shape: const Border(
                bottom: BorderSide(
                    color: Colors.grey,
                    width: 1.0
                )
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
          ) : Container(),
        ],
      ),
    );
  }
}
