import 'package:another_telephony/telephony.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:pakyaw/pages/home/booking/map.dart';
import 'package:pakyaw/pages/home/vehicle_options.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/providers/promo_provider.dart';
import 'package:pakyaw/services/database.dart';
import 'package:pakyaw/services/sms_service.dart';
import 'package:pakyaw/shared/error.dart';
import 'package:pakyaw/shared/global_var.dart';
import 'package:pakyaw/shared/loading.dart';
import 'package:pakyaw/shared/size_config.dart';
import 'package:url_launcher/url_launcher.dart';


import '../../models/promo_model.dart';
import '../../services/DirectCall.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with RouteAware, WidgetsBindingObserver {
  String id = '';
  String vehicleTypeSelected = 'Vehicle';
  final Telephony telephony = Telephony.instance;

  void changeSelectedVehicle(value){
    setState(() => vehicleTypeSelected = value);
  }

  void showVehicleOptions(){
    showModalBottomSheet(
        context: context,
        builder: (context){
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
            child: VehicleOptions(vehicletype: changeSelectedVehicle,),
          );
        }

    );
  }
  void _showToast() {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
       const SnackBar(
        content: Text('Select a vehicle type'),
      ),
    );
  }

Future<void> sendEmail() async {
    final smtpServer = gmail(email, password);

    final message = Message()
      ..from = Address(email, 'Pakyaw')
      ..recipients.add('lancepact@gmail.com')
      ..subject = 'Testing receipt'
      ..text = 'This is a test email body'
      ..html =
      '''
      <!DOCTYPE html>
<html>
<head>
<style>
  body {
    font-family: Arial, sans-serif;
    line-height: 1.6;
    color: #333;
    max-width: 600px;
    margin: 0 auto;
  }
  .receipt {
    border: 1px solid #ddd;
    padding: 20px;
    border-radius: 8px;
  }
  .header {
    text-align: center;
    margin-bottom: 20px;
  }
  .logo {
    width: 100px;
    height: 100px;
    background: #f0f0f0;
    margin: 0 auto;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
  }
  .trip-id {
    color: #666;
    font-size: 14px;
  }
  .detail-row {
    display: flex;
    justify-content: space-between;
    margin-bottom: 10px;
    padding: 5px 0;
    border-bottom: 1px solid #eee;
  }
  .label {
    font-weight: bold;
    color: #555;
  }
  .value {
    text-align: right;
  }
  .address {
    margin-bottom: 15px;
  }
  .total {
    font-size: 18px;
    font-weight: bold;
    margin-top: 20px;
    padding-top: 10px;
    border-top: 2px solid #333;
  }
  .changed {
    color: #e74c3c;
    font-size: 14px;
  }
</style>
</head>
<body>
  <div class="receipt">
    <div class="header">
      <h1>Trip Receipt</h1>
      <p class="trip-id">Trip ID: TRP-12345678</p>
    </div>

    <div class="detail-row">
      <span class="label">Time:</span>
      <span class="value">Oct 4, 2024 14:30</span>
    </div>

    <div class="detail-row">
      <span class="label">Distance:</span>
      <span class="value">5.7 km</span>
    </div>

    <div class="detail-row">
      <span class="label">Fare:</span>
      <span class="value">\$15.50</span>
    </div>

    <div class="detail-row">
      <span class="label">Payment Method:</span>
      <span class="value">Credit Card (**** 1234)</span>
    </div>

    <div class="detail-row">
      <span class="label">Promos Applied:</span>
      <span class="value">RIDE10 (-\$2.00)</span>
    </div>

    <div class="address">
      <h3>Pickup Location</h3>
      <p>123 Main St, Downtown, City</p>
      <p class="changed">Changed from: 456 Park Ave, Midtown, City</p>
    </div>

    <div class="address">
      <h3>Drop-off Location</h3>
      <p>789 Broadway, Uptown, City</p>
      <p class="changed">Changed from: 321 River Rd, Westside, City</p>
    </div>

    <div class="detail-row total">
      <span class="label">Total Amount:</span>
      <span class="value">\$13.50</span>
    </div>
  </div>
</body>
</html>
      ''';
    try{
      final sendReport = await send(message, smtpServer);
      print('Message sent: $sendReport');
    } on MailerException catch (e){
      print('Message not sent. Error: $e');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
}
  listener(SendStatus status){
    if(status == SendStatus.SENT){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sent SMS successfully"))
      );
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Delivered SMS successfully"))
      );
    }
  }
Future<void> sendText() async {
    telephony.sendSms(
      to: '+639661637528',
      message: 'Brad test receipt',
      statusListener: listener
    );
}

Future<void> callNumber() async {
    await telephony.dialPhoneNumber("+639661637528");
}

Future<void> initTelephony() async {
    final bool? result = await telephony.requestPhoneAndSmsPermissions;
    if(result != null && result){
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("There would limited functionality."))
      );
    }
}

Future<void> resetCancellations() async {
    print('running man');
  DatabaseService database = DatabaseService();
  await database.resetCancellations(id);
}

Future<void> updateSubmittedIDS(String userId) async {
    DatabaseService database = DatabaseService();
    database.updateSubmittedID(userId);
}

@override
  void initState() {
    // TODO: implement initState
    super.initState();
    initTelephony();
    final user = ref.read(authStateProvider).value;
    id = user!.uid;
    WidgetsBinding.instance.addPostFrameCallback((_){
      resetCancellations();
    });
    updateSubmittedIDS(id);

  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState
    super.didChangeAppLifecycleState(state);
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    var route = ModalRoute.of(context);
    print('Route in didChangeDependencies: ${route?.settings.name}');
    resetCancellations();
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPush() {
    // Called when the page is pushed onto the navigator
    print("Page 1: didPush");
    resetCancellations();
  }

  @override
  void didPopNext() {
    print('Page 1: something');
    resetCancellations();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final promos = ref.watch(allPromoProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.fromLTRB(25.0, 50.0, 0.0, 10.0),
              child: Text(
                'Pakyaw',
                style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 11,
                    fontWeight: FontWeight.bold
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40.0),
                color: Colors.grey[350],
              ),
              padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 10.0),
              margin: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 0.0),
              child: Container(
                height: 60.0,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: <Widget>[
                    const SizedBox(width: 3.0,),
                    Icon(
                      Icons.search,
                      size: SizeConfig.safeBlockHorizontal * 11,
                      weight: 50.0,
                    ),
                    const SizedBox(width: 3.0,),
                    SizedBox(
                      width: SizeConfig.blockSizeHorizontal * 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.fromLTRB(10.0, 4.0, 10.0, 8.0),
                          backgroundColor: Colors.grey[350],
                          elevation: 0,
                        ),
                        onPressed: () => {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => DropOffSelect()))
                        },
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Where to?',
                            style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 25.0,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ),

                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: SizeConfig.screenWidth,
              height: SizeConfig.blockSizeVertical * 35,
              margin: const EdgeInsets.fromLTRB(5.0, 20.0, 0.0, 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 10),
                    child: Text(
                      'Promos',
                      style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 7,
                        color: Colors.black,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                  ),
                  Expanded(
                    child: promos.when(
                      data: (data){
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: data.length,
                          itemBuilder: (context, index){
                            return PromoTileHomePage(promoModel: data[index],);
                          },
                        );
                      },
                      error: (e, stack) {
                        print(e.toString());
                        print(stack.toString());
                        return ErrorCatch(error: e.toString(),);
                      },
                      loading: () => const Loading(),
                    ),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PromoTileHomePage extends StatelessWidget {
  final PromoModel promoModel;
  const PromoTileHomePage({super.key, required this.promoModel});

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    DateTime startingDate = promoModel.startDate.toDate();
    DateTime endingDate = promoModel.endDate.toDate();
    String formattedStartDate = DateFormat('MM/dd/yyyy').format(startingDate);
    String formattedEndDate = DateFormat('MM/dd/yyyy').format(endingDate);
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.blockSizeVertical * 3, left: SizeConfig.blockSizeHorizontal * 2,
          right: SizeConfig.blockSizeHorizontal * 2),
      height: SizeConfig.blockSizeVertical * 30,
      width: SizeConfig.blockSizeHorizontal * 90,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: const BorderRadius.all(Radius.circular(10.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: SizeConfig.blockSizeVertical * 12,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0)),
              image: DecorationImage(
                image: NetworkImage(promoModel.banner),
                fit: BoxFit.cover,
              )
            ),
          ),
          SizedBox(height: SizeConfig.blockSizeVertical * 2,),
          Padding(
            padding: EdgeInsets.only(left: SizeConfig.blockSizeHorizontal * 5,),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${promoModel.promoName}:   ${(promoModel.discount * 100).toStringAsFixed(0)}% OFF',
                  style: TextStyle(
                      fontSize: SizeConfig.safeBlockHorizontal * 5,
                      color: Colors.black,
                      fontWeight: FontWeight.w500
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Start: $formattedStartDate',
                      style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 3,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      ', End: $formattedEndDate',
                      style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 3,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                Text(
                  promoModel.description,
                  style: TextStyle(
                      fontSize: SizeConfig.safeBlockHorizontal * 4,
                      color: Colors.black,
                      overflow: TextOverflow.fade
                  ),
                  maxLines: 2,
                )
              ],
            ),
          ),

        ],
      ),
    );
  }
}
