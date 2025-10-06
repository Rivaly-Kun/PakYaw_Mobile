import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/pages/account/change_email.dart';
import 'package:pakyaw/pages/account/change_name.dart';
import 'package:pakyaw/pages/account/change_password.dart';
import 'package:pakyaw/pages/account/change_phonenumber.dart';
import 'package:pakyaw/pages/account/change_profile.dart';
import 'package:pakyaw/pages/account/id_page.dart';
import 'package:pakyaw/pages/account/saved_places.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/providers/user_provider.dart';
import 'package:pakyaw/services/database.dart';
import 'package:pakyaw/shared/error.dart';
import 'package:pakyaw/shared/loading.dart';
import 'package:pakyaw/shared/size_config.dart';

import '../../services/auth.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  DatabaseService database = DatabaseService();
  bool value = false;
  final AuthService _authService = AuthService(FirebaseAuth.instance);
  String? providerType = '';

  void showNameChangePanel(String name){
    showModalBottomSheet(context: context, builder: (context){
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 60.0),
        child: NameChange(name: name),
      );
    });
  }
  void showEmailChangePanel(String email){
    showModalBottomSheet(context: context, builder: (context){
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 60.0),
        child: EmailChange(email: email),
      );
    });
  }
  void showPhoneNumberChangePanel(String number, String? providerType, BuildContext context1){
    showModalBottomSheet(context: context1, builder: (context){
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 60.0),
        child: PhoneChange(number: number, providerType: providerType, context1: context1),
      );
    });
  }
  void showProfileChange(){
    showModalBottomSheet(context: context, builder: (context){
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 60.0),
        child: const ChangeProfile(),
      );
    });
  }

  Future<String> getSignInMethod() async {
    final User? user = FirebaseAuth.instance.currentUser;

    String providerId = user!.providerData[0].providerId;
    switch (providerId) {
      case 'google.com':
        return 'Google';
      case 'phone':
        return 'Phone';
      default:
        return providerId;
    }
  }

  Future<void> loadProviderType() async {
    String val = await getSignInMethod();
    setState(() {
      providerType = val;
    });
  }
  Future<void> getIfVerified(String userId) async {
    value = await database.checkVerified(userId);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadProviderType();
    final user = ref.read(authStateProvider).value;
    getIfVerified(user!.uid);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final userDetails = ref.watch(usersProvider);
    return userDetails.when(
      data: (user) {
        if(user != null ){
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Container(
                margin: EdgeInsets.only(left: SizeConfig.blockSizeHorizontal * 0.1),
                child: Text(
                  'Account Info',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: SizeConfig.safeBlockHorizontal * 7
                  ),
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () async {
                    await _authService.signOut();
                  },
                  icon: const Icon(
                    Icons.person,
                    color: Colors.black,
                  ),
                  label: const Text(
                    'Log out',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            body: Container(
              margin: const EdgeInsets.only(top: 20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: GestureDetector(
                        onTap: (){
                          showProfileChange();
                        },
                        child: Container(
                          width: 120.0,
                          height: 120.0,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: user.profilePicPath == '' ? const AssetImage("assets/profile_pic.png") : NetworkImage(user.profilePicPath),
                            ),
                            color: Colors.grey[350],
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    value ? Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified, color: Colors.black,),
                          Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: SizeConfig.safeBlockHorizontal * 5.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ) : Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.unpublished, color: Colors.black,),
                          Text(
                            'UnVerified',
                            style: TextStyle(
                              fontSize: SizeConfig.safeBlockHorizontal * 5.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0,),
                    const Text(
                      '  Basic Info',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 25.0
                      ),
                    ),
                    const SizedBox(height: 10.0,),
                    ListTile(
                      shape: const Border(
                          bottom: BorderSide(
                              color: Colors.grey,
                              width: 1.0
                          )
                      ),
                      onTap: () {
                        showNameChangePanel(user.name);
                      },
                      title: const Text(
                        'Name',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0
                        ),
                      ),
                      subtitle: Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 18.0,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                    ),
                    ListTile(
                      leading: Icon(Icons.credit_card_sharp, size: SizeConfig.safeBlockHorizontal * 5, color: Colors.black,),
                      shape: const Border(
                          bottom: BorderSide(
                              color: Colors.grey,
                              width: 1.0
                          )
                      ),
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(settings: const RouteSettings(name: '/IDPage'), builder: (context) => IdPage(id: user.uid, birthday: user.birthday)));
                      },
                      title: const Text(
                        'ID',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                    ),
                    ListTile(
                      leading: Icon(Icons.phone, size: SizeConfig.safeBlockHorizontal * 5, color: Colors.black,),
                      shape: const Border(
                          bottom: BorderSide(
                              color: Colors.grey,
                              width: 1.0
                          )
                      ),
                      onTap: (){
                        showPhoneNumberChangePanel(user.phoneNumber, providerType, context);
                      },
                      title: const Text(
                        'Phone number',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0
                        ),
                      ),
                      subtitle: Text(
                        user.phoneNumber == '' ? 'N/A' : user.phoneNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 18.0,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                    ),
                    ListTile(
                      leading: Icon(Icons.email, size: SizeConfig.safeBlockHorizontal * 5, color: Colors.black,),
                      shape: const Border(
                          bottom: BorderSide(
                              color: Colors.grey,
                              width: 1.0
                          )
                      ),
                      onTap: providerType != 'Google' ? (){
                        showEmailChangePanel(user.email);
                      } : null,
                      title: const Text(
                        'Email',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0
                        ),
                      ),
                      subtitle: Text(
                        user.email == '' ? 'N/A' : user.email,
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 18.0,
                        ),
                      ),
                      trailing: providerType != 'Google' ? const Icon(Icons.arrow_forward_ios) : null,
                    ),
                    ListTile(
                      leading: Icon(Icons.wallet, size: SizeConfig.safeBlockHorizontal * 5, color: Colors.black,),
                      contentPadding: EdgeInsets.fromLTRB(SizeConfig.blockSizeHorizontal * 4.4, SizeConfig.blockSizeVertical, SizeConfig.blockSizeHorizontal * 7.3, SizeConfig.safeBlockVertical),
                      shape: const Border(
                          bottom: BorderSide(
                              color: Colors.grey,
                              width: 1.0
                          )
                      ),
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(settings: const RouteSettings(name: '/PaymentMethods'), builder: (context) => const PasswordChange()));
                      },
                      title: const Text(
                        'Payment Methods',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                    ),
                    ListTile(
                      leading: Icon(Icons.place, size: SizeConfig.safeBlockHorizontal * 5, color: Colors.black,),
                      contentPadding: EdgeInsets.fromLTRB(SizeConfig.blockSizeHorizontal * 4.4, SizeConfig.blockSizeVertical, SizeConfig.blockSizeHorizontal * 7.3, SizeConfig.safeBlockVertical),
                      shape: const Border(
                          bottom: BorderSide(
                              color: Colors.grey,
                              width: 1.0
                          )
                      ),
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(settings: const RouteSettings(name: '/SavedPlaces'), builder: (context) => const SavedPlaces()));
                      },
                      title: const Text(
                        'Saved Places',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                    ),
                  ],
                ),
              ),
            ),
          );
        }else{
          return const ErrorCatch(error: 'No data found');
        }

      },
      error: (error, stack) => Text('Error: $error'),
      loading: () => const Loading(),

    );
  }
}
