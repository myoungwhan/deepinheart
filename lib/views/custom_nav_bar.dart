import 'dart:io';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/screens/home/home_screen.dart';
import 'package:deepinheart/screens/mypage/my_page_screen.dart';
import 'package:deepinheart/screens/reservations/reservation_screen.dart';
import 'package:deepinheart/screens_consoler/chat/conversation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:deepinheart/screens/home/home_screen.dart';

import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/text_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomBottomNav extends StatefulWidget {
  final int? currentState;
  final Color? color;

  const CustomBottomNav(this.currentState, {super.key, this.color});

  @override
  _CustomBottomNavState createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav> {
  bool isSpecialUser = false;
  late int _currentIndex;
  var pref;

  DateTime? currentBackPressTime;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentState ?? 0;
    getPref();
  }

  Future<void> getPref() async {
    pref = await SharedPreferences.getInstance();
    isSpecialUser = pref.getBool('special_user') ?? false;
  }

  Future<bool> _onWillPop() async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('Do you want to exit the App'),
            actions: <Widget>[
              MaterialButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              MaterialButton(
                onPressed: () => exit(0),
                child: const Text('Yes'),
              ),
            ],
          ),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        DateTime now = DateTime.now();
        if (currentBackPressTime == null ||
            now.difference(currentBackPressTime!) >
                const Duration(seconds: 1)) {
          currentBackPressTime = now;
          Navigator.of(context).pop();
          return false;
        } else {
          return _onWillPop();
        }
      },
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
                // Add your navigation logic here
                switch (index) {
                  case 0:
                    // Navigate to HomeScreen
                    Get.off(HomeScreen());
                    break;
                  case 1:
                    // Navigate to BookingScreen
                    Get.off(ReservationScreen());
                    //    Get.off(BookingScreen());
                    break;
                  case 2:
                    Get.off(
                      ConversationScreen(isFromConsuler: false),
                      transition: Transition.noTransition,
                    );
                    // Navigate to OrdersScreen
                    // Get.off(MenuScreen());
                    break;
                  case 3:
                    // Navigate to AlertsScreen
                    Get.off(MyPageScreen());

                    break;
                  // case 4:
                  //   //   Get.off(SettingsScreen());

                  //   // Navigate to SettingsScreen
                  //   break;
                }
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: primaryColor,
              unselectedItemColor: Colors.grey[600],
              showUnselectedLabels: true,
              elevation: 0,
              backgroundColor: Colors.white,
              selectedLabelStyle: const TextStyle(fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              items: [
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _currentIndex == 0
                              ? primaryColor.withOpacity(0.2)
                              : Colors.transparent,
                    ),
                    child: Image.asset(
                      'images/nav/home.png',
                      width: 24.w,
                      color:
                          _currentIndex == 0 ? primaryColor : Color(0xff6B7280),
                    ), //const Icon(Icons.home_rounded),
                  ),
                  label: 'Home'.tr,
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _currentIndex == 1
                              ? primaryColor.withOpacity(0.2)
                              : Colors.transparent,
                    ),
                    child: Image.asset(
                      'images/nav/booking.png',
                      width: 24.w,
                      color:
                          _currentIndex == 1 ? primaryColor : Color(0xff6B7280),
                    ), //Icon(FontAwesomeIcons.calendarWeek),
                  ),
                  label: 'Booking'.tr,
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _currentIndex == 2
                              ? primaryColor.withOpacity(0.2)
                              : Colors.transparent,
                    ),
                    child: Consumer<UserViewModel>(
                      builder: (context, provider, child) {
                        return Icon(FontAwesomeIcons.message, size: 24.w);
                      },
                    ),
                  ),
                  label: 'Chat'.tr,
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _currentIndex == 3
                              ? primaryColor.withOpacity(0.2)
                              : Colors.transparent,
                    ),
                    child: Image.asset(
                      'images/nav/my.png',
                      width: 24.w,
                      color:
                          _currentIndex == 3 ? primaryColor : Color(0xff6B7280),
                    ), // const Icon(Icons.person_rounded),
                  ),
                  label: 'Me'.tr,
                ),

                // BottomNavigationBarItem(
                //   icon: Container(
                //     padding: const EdgeInsets.all(6),
                //     decoration: BoxDecoration(
                //       shape: BoxShape.circle,
                //       color:
                //           _currentIndex == 4
                //               ? primaryColor.withOpacity(0.2)
                //               : Colors.transparent,
                //     ),
                //     child: const Icon(Icons.settings_rounded),
                //   ),
                //   label: 'Settings',
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
