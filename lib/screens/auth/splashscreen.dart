import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:deepinheart/Controller/Viewmodel/setting_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/screens/auth/login_View.dart';
import 'package:deepinheart/screens/calls/widgets/rejoin_call_dialog.dart';
import 'package:deepinheart/services/call_state_manager.dart';
import 'package:deepinheart/views/logo_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreeen extends StatefulWidget {
  // required MaterialColor backgroundColor, required Duration duration, required nextPage, required Color iconBackgroundColor, required int circleHeight, required Icon child, required Text text
  SplashScreeen({Key? key}) : super(key: key);

  @override
  State<SplashScreeen> createState() => _SplashScreeenState();
}

class _SplashScreeenState extends State<SplashScreeen> {
  // late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    Provider.of<SettingProvider>(context, listen: false).fetchSettings(context);

    //  Provider.of<UserViewModel>(context, listen: false).fetchtaxonomie();
    _checkAutoLogin();
  }

  // Check if user has enabled auto-login
  Future<void> _checkAutoLogin() async {
    await Future.delayed(
      Duration(seconds: 2),
    ); // Show splash for at least 2 seconds

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? rememberMe = prefs.getBool('remember_me');

    if (rememberMe == true) {
      // User has enabled auto-login
      String? savedEmail = prefs.getString('saved_email');
      String? savedPassword = prefs.getString('saved_password');
      bool? savedIsRegularUser = prefs.getBool('saved_is_regular_user');

      if (savedEmail != null &&
          savedPassword != null &&
          savedIsRegularUser != null) {
        // Attempt auto-login
        print("Auto-login attempt for: $savedEmail");

        try {
          UserViewModel userViewModel = Provider.of<UserViewModel>(
            context,
            listen: false,
          );
          String role = savedIsRegularUser ? 'user' : 'counselor';

          await userViewModel.loginUser(
            context: context,
            role: role,
            email: savedEmail,
            password: savedPassword,
          );

          // After successful login, check for interrupted calls
          await _checkForInterruptedCall();

          // If login succeeds, userDataHandling will navigate to the appropriate screen
          // No need to navigate here
          return;
        } catch (e) {
          print("Auto-login failed: $e");
          // If auto-login fails, clear saved credentials and show login screen
          await prefs.remove('remember_me');
          await prefs.remove('saved_email');
          await prefs.remove('saved_password');
          await prefs.remove('saved_is_regular_user');
        }
      }
    }

    // No auto-login or auto-login failed, navigate to login screen
    await Future.delayed(Duration(seconds: 2)); // Show splash for a bit longer
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
    }
  }

  /// Check for interrupted call and show rejoin dialog
  Future<void> _checkForInterruptedCall() async {
    try {
      final callState = await CallStateManager.getCallState();

      if (callState != null && mounted) {
        // Wait a bit for the UI to settle after login
        await Future.delayed(Duration(milliseconds: 500));

        if (mounted) {
          // Show rejoin dialog
          await Get.dialog(
            RejoinCallDialog(callState: callState),
            barrierDismissible: false,
          );
        }
      }
    } catch (e) {
      print('❌ Error checking for interrupted call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //  Container(
      //   height: Get.height,
      //   width: Get.width,
      //   child: Lottie.asset(
      //     "animation/Animation - 1704882338607.json",
      //     width: Get.width,
      //     height: Get.height,
      //     fit: BoxFit.fill,
      //     // repeat: true,
      //     // reverse: true
      //   ),
      // ),
      body: Container(
        width: Get.width,
        height: Get.height,
        decoration: BoxDecoration(
          // image: DecorationImage(
          //   image: AssetImage("images/splashbackscreen.png"),
          //   fit: BoxFit.fill,
          // ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: Pulse(
              child: LogoView(width: Get.width * 0.4, height: 400.0),
            ),
          ),
        ),
        //  SvgPicture.asset(
        //   "images/splash_screen.gif",
        //   fit: BoxFit.fill,
        // )
      ),
    );
  }
}
