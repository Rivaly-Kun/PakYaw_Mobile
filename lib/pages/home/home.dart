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

class _HomeState extends ConsumerState<Home> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late List<AnimationController> _iconAnimationControllers;

  // PAKYAW Brand Colors
  static const Color primaryNavy = Color(0xFF0B2E6B);
  static const Color brightBlue = Color(0xFF1C72DD);
  static const Color lightBlue = Color(0xFF1B99FF);
  static const Color darkGray = Color(0xFF303841);
  static const Color lightBackground = Color(0xFFF3F3F3);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Create animation controllers for each tab icon
    _iconAnimationControllers = List.generate(
      4,
          (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );

    // Start the initial animation for the first tab
    _iconAnimationControllers[0].forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _iconAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      // Reset previous tab animation
      _iconAnimationControllers[_currentIndex].reverse();

      setState(() {
        _currentIndex = index;
      });

      // Animate new tab
      _iconAnimationControllers[index].forward();
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  Widget _buildTabIcon(IconData icon, int index, String label) {
    final isSelected = _currentIndex == index;

    return AnimatedBuilder(
      animation: _iconAnimationControllers[index],
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? brightBlue.withOpacity(0.1)
                : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: isSelected
                    ? 1.0 + (_iconAnimationControllers[index].value * 0.2)
                    : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryNavy, brightBlue, lightBlue],
                    )
                        : null,
                    color: isSelected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: brightBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : darkGray.withOpacity(0.6),
                    size: SizeConfig.safeBlockHorizontal * 6.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: SizeConfig.safeBlockHorizontal * 3.2,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? brightBlue : darkGray.withOpacity(0.7),
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            lightBackground.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () => _onTabTapped(0),
                    child: _buildTabIcon(Icons.home_rounded, 0, 'Home'),
                  ),
                  GestureDetector(
                    onTap: () => _onTabTapped(1),
                    child: _buildTabIcon(Icons.group_rounded, 1, 'Carpool'),
                  ),
                  GestureDetector(
                    onTap: () => _onTabTapped(2),
                    child: _buildTabIcon(Icons.history_rounded, 2, 'History'),
                  ),
                  GestureDetector(
                    onTap: () => _onTabTapped(3),
                    child: _buildTabIcon(Icons.person_rounded, 3, 'Account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
            backgroundColor: lightBackground,
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  key: ValueKey<int>(_currentIndex),
                  child: Pages[_currentIndex],
                ),
              ),
            ),
            bottomNavigationBar: _buildBottomNavigationBar(),
          );
        }
      },
      error: (error, stack) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lightBackground,
              Colors.white,
            ],
          ),
        ),
        child: ErrorCatch(error: '$error'),
      ),
      loading: () => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lightBackground,
              Colors.white,
            ],
          ),
        ),
        child: const Loading(),
      ),
    );
  }
}