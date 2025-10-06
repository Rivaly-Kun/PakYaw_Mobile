import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/pages/account/account_page.dart';
import 'package:pakyaw/pages/blocked_screen.dart';
import 'package:pakyaw/pages/history/history_page.dart';
import 'package:pakyaw/pages/home/home_page.dart';
import 'package:pakyaw/pages/carpool/carpool_page.dart';
import 'package:pakyaw/providers/user_provider.dart';
import 'package:pakyaw/shared/error.dart';
import 'package:pakyaw/shared/loading.dart';
import 'package:pakyaw/shared/size_config.dart';

class Home extends ConsumerStatefulWidget {
  final String id;
  const Home({super.key, required this.id});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(getUserProvider(widget.id));
    SizeConfig().init(context);

    List<Widget> Pages = [
      const HomePage(),
      const CarpoolPage(), // ✅ added Carpool page here
      const HistoryPage(),
      const AccountPage(),
    ];

    return user.when(
      data: (data) {
        if (data.blockedStatus) {
          return const BlockedScreen();
        } else {
          return Scaffold(
            body: Pages[_currentIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (int newIndex) {
                setState(() {
                  _currentIndex = newIndex;
                });
              },
              type: BottomNavigationBarType.fixed, // ✅ important for 4+ tabs
              items: [
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.home,
                    color: Colors.black,
                    size: SizeConfig.safeBlockHorizontal * 8,
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.group,
                    color: Colors.black,
                    size: SizeConfig.safeBlockHorizontal * 8,
                  ),
                  label: 'Carpool', // ✅ your new item
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.history,
                    color: Colors.black,
                    size: SizeConfig.safeBlockHorizontal * 8,
                  ),
                  label: 'History',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.person,
                    color: Colors.black,
                    size: SizeConfig.safeBlockHorizontal * 8,
                  ),
                  label: 'Account',
                ),
              ],
              elevation: 10.0,
              selectedLabelStyle: TextStyle(
                fontSize: SizeConfig.safeBlockHorizontal * 4.5,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: SizeConfig.safeBlockHorizontal * 4.2,
              ),
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.black,
            ),
          );
        }
      },
      error: (error, stack) => ErrorCatch(error: '$error'),
      loading: () => const Loading(),
    );
  }
}
