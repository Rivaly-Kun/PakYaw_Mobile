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

  Widget _buildPaymentOption({
    required String title,
    required IconData icon,
    String? subtitle,
    VoidCallback? onTap,
    Widget? leading
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          onTap: onTap,
          leading: leading ?? Icon(icon, size: 28),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: subtitle != null ? Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentOption(
            title: 'Cash',
            icon: Icons.money,
            onTap: () {
              widget.paymentMethod('Cash', '');
              Navigator.pop(context);
            },
          ),
          if (eWallet.isNotEmpty) _buildPaymentOption(
            title: 'E-wallet',
            icon: Icons.account_balance_wallet,
            subtitle: eWallet['account_number'],
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.transparent,
              backgroundImage: const AssetImage("assets/Google.png"),
            ),
            onTap: () {
              widget.paymentMethod('E-wallet', eWallet['account_number']);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
