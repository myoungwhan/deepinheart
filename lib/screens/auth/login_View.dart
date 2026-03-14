import 'dart:io';

import 'package:deepinheart/screens/auth/register_screen.dart';
import 'package:deepinheart/screens/auth/widget/custom_socialbuttons.dart';
import 'package:deepinheart/screens/home/home_screen.dart';
import 'package:deepinheart/views/custom_appbar.dart';
import 'package:deepinheart/views/logo_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deepinheart/Controller/Viewmodel/loading_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/Controller/Viewmodel/setting_provider.dart';
import 'package:deepinheart/Controller/firebasehelper.dart';
import 'package:deepinheart/main.dart';
import 'package:deepinheart/screens/auth/forgot_password_screen.dart';

import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_button.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/custom_textfieldphone.dart';
import 'package:deepinheart/views/custom_textfiled.dart';
import 'package:deepinheart/views/custom_viewpager.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/logo_view.dart';
import 'package:deepinheart/views/text_styles.dart';
import 'package:deepinheart/views/ui_helpers.dart';

class SignInScreen extends StatefulWidget {
  SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  TextEditingController password = TextEditingController();

  TextEditingController email = TextEditingController();
  Color emailBorderColor = Colors.transparent;
  Color passwordBorderColor = Colors.transparent;
  Color suffixIconColor = Colors.transparent;

  bool isPasswordVisible = false;
  bool _isChecked = false;
  bool isRegularUser = true;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final _phoneFieldKey = GlobalKey<FormFieldState<PhoneNumber>>();

  String usermaneError = "";
  String passwordError = "";
  String emailError = "";
  String phoneError = "";

  bool isGoogleLogin = false;
  bool isAppleLogin = false;
  String? selectedCountry;
  TextEditingController phone = TextEditingController();

  @override
  void initState() {
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: isRegularUser ? 0 : 1,
    );
    _loadRememberMe();
    super.initState();
  }

  // Load saved credentials if "Remember Me" was checked
  Future<void> _loadRememberMe() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? rememberMe = prefs.getBool('remember_me');

    if (rememberMe == true) {
      String? savedEmail = prefs.getString('saved_email');
      String? savedPassword = prefs.getString('saved_password');
      bool? savedIsRegularUser = prefs.getBool('saved_is_regular_user');

      if (savedEmail != null && savedPassword != null) {
        setState(() {
          _isChecked = true;
          email.text = savedEmail;
          password.text = savedPassword;
          if (savedIsRegularUser != null) {
            isRegularUser = savedIsRegularUser;
            _tabController?.index = isRegularUser ? 0 : 1;
          }
        });
      }
    }
  }

  // Save credentials when "Remember Me" is checked
  Future<void> _saveRememberMe() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (_isChecked) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('saved_email', email.text.trim());
      await prefs.setString('saved_password', password.text);
      await prefs.setBool('saved_is_regular_user', isRegularUser);
    } else {
      // Clear saved credentials if unchecked
      await prefs.remove('remember_me');
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.remove('saved_is_regular_user');
    }
  }

  @override
  void dispose() {
    super.dispose();
    _tabController!.dispose();
  }

  // Login user method
  Future<void> _loginUser() async {
    //   try {
    LoadingProvider loadingProvider = context.read<LoadingProvider>();
    UserViewModel userViewModel = context.read<UserViewModel>();

    loadingProvider.showLoading();

    // Save credentials if "Remember Me" is checked
    await _saveRememberMe();

    // Determine role based on tab selection
    String role = isRegularUser ? 'user' : 'counselor';

    print("Login attempt:");
    print("Role: $role");
    print("Email: ${email.text}");

    // Call login API
    await userViewModel.loginUser(
      context: context,
      role: role,
      email: email.text.trim(),
      password: password.text,
    );

    loadingProvider.hideLoading();
    // } catch (e) {
    //   LoadingProvider loadingProvider = context.read<LoadingProvider>();
    //   loadingProvider.hideLoading();

    //   print("Login error: $e");
    //   UIHelper.showBottomFlash(
    //     context,
    //     title: "",
    //     message: "Login failed: ${e.toString()}",
    //     isError: true,
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return GestureDetector(
      onTap: () {
        UIHelper.hideKeyboard(context);
      },
      child: Scaffold(
        appBar: customAppBar(
          title: "Login".tr,
          leading: Container(width: 0.0),
          action: [Container(width: 0.0)],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 21),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  //   SizedBox(height: topPadding),
                  LogoView(height: 60.0, width: 60.0),
                  UIHelper.verticalSpaceSm5,
                  CustomText(
                    text: AppName,
                    fontSize: FontConstants.font_14,
                    weight: FontWeightConstants.medium,
                  ),

                  // SizedBox(height: 10),
                  UIHelper.verticalSpaceL,
                  Container(
                    height: 44.h,
                    decoration: BoxDecoration(
                      color: Color(0xffEFF0F6),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      overlayColor: WidgetStatePropertyAll(Colors.transparent),

                      onTap: (ta) {
                        isRegularUser = ta == 0;
                        setState(() {});
                      },
                      dividerHeight: 0.0,

                      isScrollable: false, // Enable scrolling
                      indicatorSize: TabBarIndicatorSize.tab,

                      automaticIndicatorColorAdjustment: false,
                      // give the indicator a decoration (color and border radius)
                      indicator: BoxDecoration(
                        boxShadow: [
                          // BoxShadow(
                          //     color: Color.fromRGBO(
                          //         0, 0, 0, 0.30000000149011612),
                          //     offset: Offset(0, 10),
                          //     blurRadius: 5)
                        ],
                        borderRadius: BorderRadius.circular(25.0),
                        color: primaryColor,
                      ),

                      indicatorPadding: EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 5,
                      ),
                      labelColor: Colors.white,
                      indicatorColor: Colors.grey,

                      labelStyle: textStyleRobotoRegular(
                        fontSize: FontConstants.font_14,
                        weight: FontWeightConstants.medium,
                      ),
                      unselectedLabelColor: lightGREY,
                      unselectedLabelStyle: textStyleRobotoRegular(
                        fontSize: FontConstants.font_14,
                        weight: FontWeightConstants.medium,
                      ),

                      tabs: [
                        Tab(text: "Regular User".tr),
                        Tab(text: "Counselor".tr),
                      ],
                    ),
                  ),

                  SizedBox(height: 25),

                  // Email field - only show if email registration is enabled
                  Consumer<SettingProvider>(
                    builder: (context, settingProvider, child) {
                      if (!settingProvider.isEmailRegistrationEnabled) {
                        return SizedBox.shrink();
                      }
                      return Customtextfield(
                        controller: email,
                        required: true,
                        hint: "example@gmail.com".tr,
                        text: "Email".tr,
                        prefix: Icon(Icons.email),
                        keyboard: TextInputType.emailAddress,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        suffix: Icon(
                          Icons.email,
                          size: 20,
                          color: suffixIconColor,
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Please insert email".tr;
                          } else if (!UIHelper.isEmailValid(value)) {
                            return "Insert valid email".tr;
                          } else {
                            return null;
                          }
                        },
                      );
                    },
                  ),

                  SizedBox(height: 5),

                  Customtextfield(
                    controller: password,
                    required: true,
                    hint: "Please enter your password".tr,
                    text: "Password".tr,
                    isObscure: true,
                    showPasswordToggle: true,
                    prefix: Icon(Icons.lock),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Insert password".tr;
                      } else if (value.length < 6) {
                        return "Password must grather than 6".tr;
                      } else {
                        return null;
                      }
                    },

                    suffix: GestureDetector(
                      onTap: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                      child: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  SizedBox(height: 5),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isChecked = !_isChecked;
                              });
                            },
                            child: Container(
                              width: 22.0.h,
                              height: 22.0.h,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(2.0),
                              ),
                              child:
                                  _isChecked
                                      ? Center(
                                        child: Icon(
                                          Icons.check,
                                          size: 15.0,
                                          color: Colors.black,
                                        ),
                                      )
                                      : null,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CustomText(
                              text: "Automatic login".tr,
                              isSemibold: true,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Get.to(ForgotPasswordScreen());
                        },
                        child: CustomText(
                          text: "Forget Password".tr,
                          isSemibold: true,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),
                  CustomButton(() async {
                    UIHelper.hideKeyboard(context);
                    final settingProvider = context.read<SettingProvider>();

                    // Validate form
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    // Check email if email registration is enabled
                    if (settingProvider.isEmailRegistrationEnabled &&
                        email.text.isEmpty) {
                      UIHelper.showBottomFlash(
                        context,
                        title: "",
                        message: "Please enter email".tr,
                        isError: true,
                      );
                      return;
                    }

                    if (password.text.isEmpty) {
                      UIHelper.showBottomFlash(
                        context,
                        title: "",
                        message: "Please enter password".tr,
                        isError: true,
                      );
                      return;
                    }

                    // Call login API
                    await _loginUser();
                  }, text: "Login".tr),
                  UIHelper.verticalSpaceMd,
                  InkWell(
                    onTap: () {
                      Get.to(RegisterScreen());
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomText(
                          text: "Don't have an account yet?".tr,
                          fontSize: FontConstants.font_14,
                        ),
                        UIHelper.horizontalSpaceSm,
                        CustomText(
                          text: "Register".tr,

                          weight: FontWeightConstants.medium,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ),
                  UIHelper.verticalSpaceMd,
                  // Only show social login if at least one integration is enabled
                  Consumer<SettingProvider>(
                    builder: (context, settingProvider, child) {
                      final hasAnySocialLogin =
                          settingProvider.isKakaoIntegrationEnabled ||
                          settingProvider.isAppleIntegrationEnabled;

                      if (!hasAnySocialLogin) {
                        return SizedBox.shrink();
                      }

                      return Column(
                        children: [
                          orDivider("Or Login with".tr),
                          UIHelper.verticalSpaceSm,
                          CustomSocialbuttons(isRegularUser: isRegularUser),
                        ],
                      );
                    },
                  ),
                  UIHelper.verticalSpaceL,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Row orDivider(text) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Expanded(child: Divider(thickness: 1, color: Colors.black)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: CustomText(text: text, color: Color(0xff6B7280)),
      ),
      Expanded(child: Divider(thickness: 1, color: Colors.black)),
    ],
  );
}

Widget socilbutton({img, onTap, bool? isLoading}) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 10),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45.sp,
        height: 45.sp,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 70, 59, 59).withOpacity(0.5),
              spreadRadius: 0,
              blurRadius: 3,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child:
            isLoading ?? false
                ? SizedBox(
                  height: 20,
                  width: 20,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: CircularProgressIndicator(color: orangeColor),
                  ),
                )
                : Image(image: AssetImage(img)),
      ),
    ),
  );
}
