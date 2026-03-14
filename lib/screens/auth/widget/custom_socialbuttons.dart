import 'dart:io';

import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/Controller/Viewmodel/setting_provider.dart';
import 'package:deepinheart/Controller/firebasehelper.dart';
import 'package:deepinheart/main.dart';
import 'package:deepinheart/screens/auth/login_View.dart';
import 'package:deepinheart/screens/auth/register_screen.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:deepinheart/Controller/Viewmodel/loading_provider.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:deepinheart/screens/home/home_screen.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;

class CustomSocialbuttons extends StatefulWidget {
  final bool isRegularUser;

  const CustomSocialbuttons({Key? key, this.isRegularUser = true})
    : super(key: key);

  @override
  _CustomSocialbuttonsState createState() => _CustomSocialbuttonsState();
}

class _CustomSocialbuttonsState extends State<CustomSocialbuttons> {
  bool isGoogleLogin = false;
  bool isAppleLogin = false;
  bool isFacebookLogin = false;
  bool isKakaoLogin = false;

  // Handle Google login
  Future<void> _handleGoogleLogin() async {
    try {
      setState(() {
        isGoogleLogin = true;
      });

      UserViewModel provider = Provider.of<UserViewModel>(
        context,
        listen: false,
      );
      LoadingProvider loadingProvider = Provider.of<LoadingProvider>(
        context,
        listen: false,
      );

      loadingProvider.showLoading();

      // Sign in with Google
      var googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        var email = googleUser.email;
        var name =
            googleUser.displayName ?? email.substring(0, email.indexOf('@'));
        var providerId = googleUser.id;

        // Determine role
        String role = widget.isRegularUser ? 'user' : 'counselor';

        print("Google login attempt:");
        print("Name: $name");
        print("Email: $email");
        print("Role: $role");
        print("Provider ID: $providerId");

        // Call social login API
        Map<String, dynamic> result = await provider.socialLoginWithAPI(
          name: name,
          role: role,
          email: email,
          providerId: providerId,
          socialType: 'google',
        );

        loadingProvider.hideLoading();

        if (result['success'] == true) {
          // Login successful
          UIHelper.showBottomFlash(
            context,
            title: "",
            message: result['message'] ?? "Google login successful".tr,
            isError: false,
          );

          // Store user data and token if needed
          if (result['token'] != null) {
            print("Google login token: ${result['token']}");
          }

          if (result['user'] != null) {
            print("Google user data: ${result['user']}");
          }

          // Navigate to home screen
          //  Get.offAll(HomeScreen());
        } else {
          // Login failed
          UIHelper.showBottomFlash(
            context,
            title: "",
            message: result['message'] ?? "Google login failed".tr,
            isError: true,
          );
        }
      } else {
        loadingProvider.hideLoading();
        // User cancelled Google sign in
        print("Google sign in cancelled");
      }
    } catch (error) {
      LoadingProvider loadingProvider = Provider.of<LoadingProvider>(
        context,
        listen: false,
      );
      loadingProvider.hideLoading();

      print("Google login error: $error");
      // UIHelper.showBottomFlash(
      //   context,
      //   title: "",
      //   message: "Google login failed: ${error.toString()}",
      //   isError: true,
      // );
    } finally {
      setState(() {
        isGoogleLogin = false;
      });
    }
  }

  // Handle Facebook login
  Future<void> _handleFacebookLogin() async {
    try {
      setState(() {
        isFacebookLogin = true;
      });

      UserViewModel provider = Provider.of<UserViewModel>(
        context,
        listen: false,
      );
      LoadingProvider loadingProvider = Provider.of<LoadingProvider>(
        context,
        listen: false,
      );

      loadingProvider.showLoading();

      // Sign in with Facebook
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        // Get user data from Facebook
        final userData = await FacebookAuth.instance.getUserData();

        var email = userData['email'] ?? '';
        var name = userData['name'] ?? email.substring(0, email.indexOf('@'));
        var providerId = userData['id'] ?? '';

        // Determine role
        String role = widget.isRegularUser ? 'user' : 'counselor';

        print("Facebook login attempt:");
        print("Name: $name");
        print("Email: $email");
        print("Role: $role");
        print("Provider ID: $providerId");

        // Call social login API
        Map<String, dynamic> apiResult = await provider.socialLoginWithAPI(
          name: name,
          role: role,
          email: email,
          providerId: providerId,
          socialType: 'facebook',
        );

        loadingProvider.hideLoading();

        if (apiResult['success'] == true) {
          // Login successful
          UIHelper.showBottomFlash(
            context,
            title: "",
            message: apiResult['message'] ?? "Facebook login successful".tr,
            isError: false,
          );

          // Store user data and token if needed
          if (apiResult['token'] != null) {
            print("Facebook login token: ${apiResult['token']}");
          }

          if (apiResult['user'] != null) {
            print("Facebook user data: ${apiResult['user']}");
          }

          // Navigate to home screen
          Get.offAll(HomeScreen());
        } else {
          // Login failed
          UIHelper.showBottomFlash(
            context,
            title: "",
            message: apiResult['message'] ?? "Facebook login failed".tr,
            isError: true,
          );
        }
      } else if (result.status == LoginStatus.cancelled) {
        loadingProvider.hideLoading();
        // User cancelled Facebook sign in
        print("Facebook sign in cancelled");
      } else {
        loadingProvider.hideLoading();
        // Facebook login failed
        UIHelper.showBottomFlash(
          context,
          title: "",
          message: "Facebook login failed: ${result.message}",
          isError: true,
        );
      }
    } catch (error) {
      LoadingProvider loadingProvider = Provider.of<LoadingProvider>(
        context,
        listen: false,
      );
      loadingProvider.hideLoading();

      print("Facebook login error: $error");
      UIHelper.showBottomFlash(
        context,
        title: "",
        message: "Facebook login failed: ${error.toString()}",
        isError: true,
      );
    } finally {
      setState(() {
        isFacebookLogin = false;
      });
    }
  }

  // Handle Kakao Login
  Future<void> _handleKakaoLogin() async {
    try {
      setState(() {
        isKakaoLogin = true;
      });

      UserViewModel provider = Provider.of<UserViewModel>(
        context,
        listen: false,
      );
      LoadingProvider loadingProvider = Provider.of<LoadingProvider>(
        context,
        listen: false,
      );

      loadingProvider.showLoading();

      // Check if KakaoTalk is installed
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          await kakao.UserApi.instance.loginWithKakaoTalk();
          print('Logged in with KakaoTalk');
        } catch (error) {
          print('KakaoTalk login failed: $error');

          // If user cancelled, stop here
          if (error is kakao.KakaoAuthException &&
              (error.message?.contains('cancelled') ?? false)) {
            loadingProvider.hideLoading();
            setState(() {
              isKakaoLogin = false;
            });
            return;
          }

          // Retry with Kakao Account
          try {
            await kakao.UserApi.instance.loginWithKakaoAccount();
            print('Logged in with Kakao Account');
          } catch (error) {
            print('Kakao Account login failed: $error');
            throw error;
          }
        }
      } else {
        try {
          await kakao.UserApi.instance.loginWithKakaoAccount();
          print('Logged in with Kakao Account');
        } catch (error) {
          print('Kakao Account login failed: $error');
          throw error;
        }
      }

      // Login successful, get user info
      kakao.User user = await kakao.UserApi.instance.me();

      var email = user.kakaoAccount?.email ?? '';
      var name =
          user.kakaoAccount?.profile?.nickname ??
          (email.isNotEmpty
              ? email.substring(0, email.indexOf('@'))
              : 'Kakao User');
      var providerId = user.id.toString();

      // Determine role
      String role = widget.isRegularUser ? 'user' : 'counselor';

      print("Kakao login attempt:");
      print("Name: $name");
      print("Email: $email");
      print("Role: $role");
      print("Provider ID: $providerId");

      // Call social login API
      Map<String, dynamic> apiResult = await provider.socialLoginWithAPI(
        name: name,
        role: role,
        email: email,
        providerId: providerId,
        socialType: 'kakao',
      );

      loadingProvider.hideLoading();

      if (apiResult['success'] == true) {
        // Login successful
        UIHelper.showBottomFlash(
          context,
          title: "",
          message: apiResult['message'] ?? "Kakao login successful".tr,
          isError: false,
        );

        // Navigate handled in socialLoginWithAPI or userviewmodel
      } else {
        // Login failed
        UIHelper.showBottomFlash(
          context,
          title: "",
          message: apiResult['message'] ?? "Kakao login failed".tr,
          isError: true,
        );
      }
    } catch (error) {
      LoadingProvider loadingProvider = Provider.of<LoadingProvider>(
        context,
        listen: false,
      );
      loadingProvider.hideLoading();

      print("Kakao login error: $error");
      UIHelper.showBottomFlash(
        context,
        title: "",
        message: "Kakao login failed: ${error.toString()}",
        isError: true,
      );
    } finally {
      setState(() {
        isKakaoLogin = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingProvider>(
      builder: (context, settingProvider, child) {
        return Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              socilbutton(
                img: AppIcons.googlelogo,
                isLoading: isGoogleLogin,
                onTap: () async {
                  await _handleGoogleLogin();
                },
              ),
              // Apple login - only show if enabled in settings and on iOS
              (Platform.isIOS && settingProvider.isAppleIntegrationEnabled)
                  ? socilbutton(
                    img: AppIcons.applelogo,
                    isLoading: isAppleLogin,
                    onTap: () async {
                      setState(() {
                        isAppleLogin = true;
                      });
                      try {
                        Services services = Services();
                        await services.loginWithApple(context);
                        setState(() {
                          isAppleLogin = false;
                        });
                      } catch (e) {
                        setState(() {
                          isAppleLogin = false;
                        });
                      }
                    },
                  )
                  : Container(),
              socilbutton(
                img: AppIcons.facbooklogo,
                isLoading: isFacebookLogin,
                onTap: () async {
                  await _handleFacebookLogin();
                },
              ),
              // Kakao login - only show if enabled in settings
              settingProvider.isKakaoIntegrationEnabled
                  ? socilbutton(
                    img: AppIcons.talklogo,
                    isLoading: isKakaoLogin,
                    onTap: () async {
                      await _handleKakaoLogin();
                    },
                  )
                  : Container(),
              socilbutton(img: AppIcons.nloginlogo),
            ],
          ),
        );
      },
    );
  }
}
