// lib/pages/home/home_page.dart

import 'package:another_telephony/telephony.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

// Model for popular destination
class PopularDestination {
  final String name;
  final double lat;
  final double lng;
  final String subtitle;
  final IconData icon;

  PopularDestination({
    required this.name,
    required this.lat,
    required this.lng,
    required this.subtitle,
    required this.icon,
  });
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with RouteAware, WidgetsBindingObserver {
  String id = '';
  String vehicleTypeSelected = 'Vehicle';
  final Telephony telephony = Telephony.instance;

  // PAKYAW Brand Colors
  static const Color primaryNavy = Color(0xFF0B2E6B);
  static const Color brightBlue = Color(0xFF1C72DD);
  static const Color lightBlue = Color(0xFF1B99FF);
  static const Color darkGray = Color(0xFF303841);
  static const Color lightBackground = Color(0xFFF3F3F3);
  static const Color successGreen = Color(0xFF10B981);

  // Popular destinations data
  final List<PopularDestination> popularDestinations = [
    PopularDestination(
      name: 'Robinson Mall',
      lat: 11.025301161022764,
      lng: 124.60485188565477,
      subtitle: 'Shopping Mall',
      icon: Icons.store_mall_directory,
    ),
    PopularDestination(
      name: 'Ormoc City District Hospital',
      lat: 11.022779455801421,
      lng: 124.60316911445099,
      subtitle: 'Hospital',
      icon: Icons.local_hospital,
    ),
    PopularDestination(
      name: 'Ormoc City Superdome',
      lat: 11.004263098845255,
      lng: 124.60955226050235,
      subtitle: 'Sports Complex',
      icon: Icons.school,
    ),
    PopularDestination(
      name: 'New City Hall',
      lat: 11.013180121398674,
      lng: 124.60519370081639,
      subtitle: 'Government Building',
      icon: Icons.business,
    ),
  ];

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

  // Navigate to map with pre-filled destination
  void _navigateToMapWithDestination(PopularDestination destination) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DropOffSelect(
          prefilledDestination: destination.name,
          prefilledLatLng: LatLng(destination.lat, destination.lng),
        ),
      ),
    );
  }

  Widget _buildRecentDestination({
    required IconData icon,
    required String location,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: lightBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: brightBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location,
                        style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 3.8,
                          fontWeight: FontWeight.w600,
                          color: darkGray,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 3,
                          color: Colors.grey[600],
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
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
    super.didChangeAppLifecycleState(state);
  }

  @override
  void didChangeDependencies() {
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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lightBackground,
              Colors.white,
              lightBackground.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                // Header Section
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.fromLTRB(25.0, 30.0, 25.0, 10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 60,
                              child: SvgPicture.asset(
                                'assets/pakyaw_logo.svg',
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryNavy, brightBlue],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: brightBlue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_circle,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Container(
                  margin: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16.0),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DropOffSelect()),
                      ),
                      child: Container(
                        height: 56.0,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: brightBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.search,
                                color: brightBlue,
                                size: SizeConfig.safeBlockHorizontal * 6,
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Text(
                                'Where to?',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: SizeConfig.safeBlockHorizontal * 4.5,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Recent/Popular Destinations
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Popular Destinations',
                        style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 5.5,
                          color: darkGray,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...popularDestinations.map((destination) {
                        return _buildRecentDestination(
                          icon: destination.icon,
                          location: destination.name,
                          subtitle: destination.subtitle,
                          onTap: () => _navigateToMapWithDestination(destination),
                        );
                      }).toList(),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}