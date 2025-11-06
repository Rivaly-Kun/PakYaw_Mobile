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
        if (user != null) {
          return Scaffold(
            backgroundColor: Colors.grey[100],
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[900]!, Colors.blue],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Account Info',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton.icon(
                  onPressed: () async {
                    await _authService.signOut();
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: Text(
                    'Logout',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Section
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => showProfileChange(),
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.blue, width: 3),
                                  image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: user.profilePicPath == '' 
                                      ? const AssetImage("assets/profile_pic.png")
                                      : NetworkImage(user.profilePicPath) as ImageProvider,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              value ? Icons.verified : Icons.unpublished,
                              color: value ? Colors.green : Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              value ? 'Verified Account' : 'Unverified Account',
                              style: TextStyle(
                                color: value ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Basic Info Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Basic Information'),
                        const SizedBox(height: 16),
                        _buildInfoTile(
                          icon: Icons.person_outline,
                          title: 'Name',
                          subtitle: user.name,
                          onTap: () => showNameChangePanel(user.name),
                        ),
                        _buildInfoTile(
                          icon: Icons.credit_card,
                          title: 'ID',
                          subtitle: 'View ID Details',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IdPage(
                                id: user.uid,
                                birthday: user.birthday,
                              ),
                            ),
                          ),
                        ),
                        _buildInfoTile(
                          icon: Icons.phone,
                          title: 'Phone',
                          subtitle: user.phoneNumber.isEmpty ? 'Not set' : user.phoneNumber,
                          onTap: () => showPhoneNumberChangePanel(
                            user.phoneNumber,
                            providerType,
                            context,
                          ),
                        ),
                        _buildInfoTile(
                          icon: Icons.email,
                          title: 'Email',
                          subtitle: user.email.isEmpty ? 'Not set' : user.email,
                          onTap: providerType != 'Google'
                              ? () => showEmailChangePanel(user.email)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Additional Settings Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Settings'),
                        const SizedBox(height: 16),
                        _buildSettingsTile(
                          icon: Icons.payment,
                          title: 'Payment Methods',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PasswordChange(),
                            ),
                          ),
                        ),
                        _buildSettingsTile(
                          icon: Icons.location_on,
                          title: 'Saved Places',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SavedPlaces(),
                            ),
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
        return const ErrorCatch(error: 'No data found');
      },
      error: (error, stack) => Text('Error: $error'),
      loading: () => const Loading(),

    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue[700]),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 14,
        ),
      ),
      trailing: onTap != null
          ? const Icon(Icons.arrow_forward_ios, size: 16)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue[700]),
      ),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
