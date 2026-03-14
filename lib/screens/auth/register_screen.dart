import 'dart:async';
import 'dart:convert';

import 'package:deepinheart/Controller/Model/texnomy_model.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:deepinheart/screens/auth/document_registeration_screen.dart';
import 'package:deepinheart/screens/auth/login_View.dart';
import 'package:deepinheart/screens/auth/widget/category_gridview.dart';
import 'package:deepinheart/screens/auth/widget/custom_socialbuttons.dart';
import 'package:deepinheart/screens/auth/widget/custom_tabbar.dart';
import 'package:deepinheart/views/custom_appbar.dart';
import 'package:deepinheart/views/logo_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:deepinheart/Controller/Viewmodel/loading_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/Controller/Viewmodel/setting_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_button.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/custom_textfieldphone.dart';
import 'package:deepinheart/views/custom_textfiled.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';

class RegisterScreen extends StatefulWidget {
  RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  TextEditingController password = TextEditingController();
  TextEditingController cpassword = TextEditingController();
  TextEditingController nameController = TextEditingController();

  TextEditingController email = TextEditingController();
  Color emailBorderColor = Colors.transparent;
  Color passwordBorderColor = Colors.transparent;
  Color suffixIconColor = Colors.transparent;

  bool isPasswordVisible = false;
  bool iscPasswordVisible = false;

  // Email existence check variables
  bool _isCheckingEmail = false;
  bool? _emailExists;
  Timer? _emailCheckTimer;

  bool _isChecked = false;
  bool isRegularUser = true;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String usermaneError = "";
  String passwordError = "";
  String emailError = "";
  String phoneError = "";

  String? selectedCountry;
  TextEditingController phone = TextEditingController();

  // OTP verification variables
  String? verificationId;
  bool isOtpSent = false;
  bool isOtpVerified = false;
  int? resendToken;
  TextEditingController otpController = TextEditingController();

  List<FocusNode> otpFocusNodes = List.generate(6, (index) => FocusNode());

  // Timer variables
  Timer? _timer;
  int _countdown = 300; // 5 minutes in seconds
  final Map<String, List<String>> sections = {
    'fortune_telling': [
      'tarot',
      'saju',
      'sinjeom',
      'jakmyeong',
      'pungsujiri',
      'gwansang_songeum',
    ],
    'psych_counseling': [
      'simni_sangdam',
      'simni_geomsa',
      'yeonae_sangdam',
      'gomin_sangdam',
    ],
  };

  final List<Category> selectedFortunes = [];
  final List<Category> selectedCounslings = [];

  @override
  void initState() {
    super.initState();
    email.addListener(_onEmailChanged);
  }

  // Handle email text changes with debouncing
  void _onEmailChanged() {
    _emailCheckTimer?.cancel();
    _emailExists = null; // Reset email exists status

    final emailValue = email.text.trim();
    if (emailValue.isEmpty) {
      setState(() {
        _isCheckingEmail = false;
        _emailExists = null;
      });
      return;
    }

    // Only check if email is valid format
    if (!UIHelper.isEmailValid(emailValue)) {
      setState(() {
        _isCheckingEmail = false;
        _emailExists = null;
      });
      return;
    }

    // Debounce: wait 500ms after user stops typing
    _emailCheckTimer = Timer(Duration(milliseconds: 500), () {
      _checkEmailExists(emailValue);
    });
  }

  // Check if email already exists via API
  Future<void> _checkEmailExists(String emailValue) async {
    if (!mounted) return;

    setState(() {
      _isCheckingEmail = true;
      _emailExists = null;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiEndPoints.BASE_URL}check-exit-email'),
      );

      request.fields['email'] = emailValue;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isCheckingEmail = false;
          _emailExists = data['data'] == true; // true means email exists
        });
      } else {
        setState(() {
          _isCheckingEmail = false;
          _emailExists = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCheckingEmail = false;
        _emailExists = null;
      });
      print('Error checking email: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailCheckTimer?.cancel();
    email.removeListener(_onEmailChanged);

    for (var focusNode in otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  // Start countdown timer
  void _startTimer() {
    _countdown = 300; // Reset to 5 minutes
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  // Format timer display
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Build email suffix icon based on state
  Widget _buildEmailSuffixIcon() {
    if (_isCheckingEmail) {
      // Show circular progress indicator while checking
      return SizedBox(
        width: 20,
        height: 20,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      );
    } else if (_emailExists == true) {
      // Show error icon if email exists
      return Icon(Icons.error_outline, size: 20, color: Colors.red);
    } else if (_emailExists == false) {
      // Show success icon if email is available
      return Icon(Icons.check_circle_outline, size: 20, color: Colors.green);
    } else {
      // Default email icon
      return Icon(Icons.email, size: 20, color: suffixIconColor);
    }
  }

  // Get OTP from individual controllers
  String _getOTP() {
    return otpController.text;
  }

  // Send OTP to phone number
  Future<void> _sendOTP() async {
    if (phone.text.isEmpty) {
      UIHelper.showBottomFlash(
        context,
        title: "",
        message: "Please enter phone number".tr,
        isError: true,
      );
      return;
    }

    try {
      LoadingProvider loadingProvider = context.read<LoadingProvider>();
      loadingProvider.showLoading();

      String phoneNumber = '${selectedCountry ?? ''}${phone.text}';
      // Remove any double plus signs
      if (phoneNumber.startsWith('++')) {
        phoneNumber = phoneNumber.substring(1);
      }
      // Ensure it starts with +
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+$phoneNumber';
      }

      print("=== SENDING OTP DEBUG ===");
      print("Phone Number: '$phoneNumber'");
      print("Country Code: '$selectedCountry'");
      print("Phone Text: '${phone.text}'");
      print("=========================");

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed
          await _verifyOTP(credential.smsCode ?? '');
        },
        verificationFailed: (FirebaseAuthException e) {
          loadingProvider.hideLoading();
          UIHelper.showBottomFlash(
            context,
            title: "",
            message: e.message ?? "Verification failed".tr,
            isError: true,
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          loadingProvider.hideLoading();

          print("=== OTP SENT DEBUG ===");
          print("Verification ID: '$verificationId'");
          print("Resend Token: $resendToken");
          print("======================");

          setState(() {
            this.verificationId = verificationId;
            this.resendToken = resendToken;
            isOtpSent = true;
          });
          _startTimer(); // Start the countdown timer
          UIHelper.showBottomFlash(
            context,
            title: "",
            message: "OTP sent successfully".tr,
            isError: false,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          this.verificationId = verificationId;
        },
        timeout: Duration(seconds: 60),
      );
    } catch (e) {
      LoadingProvider loadingProvider = context.read<LoadingProvider>();
      loadingProvider.hideLoading();
      UIHelper.showBottomFlash(
        context,
        title: "",
        message: "Error sending OTP: ${e.toString()}",
        isError: true,
      );
    }
  }

  // Verify OTP
  Future<void> _verifyOTP(String otp) async {
    if (verificationId == null) {
      UIHelper.showBottomFlash(
        context,
        title: "",
        message: "Please send OTP first".tr,
        isError: true,
      );
      return;
    }

    print("=== OTP DEBUG INFO ===");
    print("Entered OTP: '$otp'");
    print("OTP Length: ${otp.length}");
    print("Verification ID: '$verificationId'");
    print("Phone Number: '+${selectedCountry ?? ''}${phone.text}'");
    print("=====================");

    try {
      LoadingProvider loadingProvider = context.read<LoadingProvider>();
      loadingProvider.showLoading();

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otp,
      );

      print("Credential created successfully");

      // Verify the credential by attempting to sign in
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithCredential(credential);
        print("Firebase sign in successful");
        print("User ID: ${userCredential.user?.uid}");
        print("Phone Number: ${userCredential.user?.phoneNumber}");

        // Sign out immediately after verification
        await FirebaseAuth.instance.signOut();
        print("Signed out after verification");
      } catch (signInError) {
        // Check if this is the known type casting error that occurs AFTER successful authentication
        if (signInError.toString().contains(
              "is not a subtype of type 'PigeonUserDetails'",
            ) ||
            signInError.toString().contains("type 'List<Object?>'")) {
          print(
            "Type casting error after successful authentication - treating as success",
          );
          // Firebase has already authenticated the user (we can see this in logs)
          // This is a known issue with Firebase Auth plugin
          // Try to sign out the current user if any
          try {
            await FirebaseAuth.instance.signOut();
            print("Signed out after type error");
          } catch (signOutError) {
            print("Sign out error (can be ignored): $signOutError");
          }
        } else {
          // This is a real authentication error, rethrow it
          print("Real authentication error: $signInError");
          rethrow;
        }
      }

      _timer?.cancel(); // Stop the timer
      setState(() {
        isOtpVerified = true;
      });

      loadingProvider.hideLoading();
      UIHelper.showBottomFlash(
        context,
        title: "",
        message: "Phone number verified successfully".tr,
        isError: false,
      );
    } catch (e) {
      LoadingProvider loadingProvider = context.read<LoadingProvider>();
      loadingProvider.hideLoading();

      print("=== OTP VERIFICATION ERROR ===");
      print("Error Type: ${e.runtimeType}");
      print("Error Message: ${e.toString()}");
      if (e is FirebaseAuthException) {
        print("Firebase Error Code: ${e.code}");
        print("Firebase Error Message: ${e.message}");
      }
      print("==============================");

      String errorMessage = "Invalid OTP. Please try again".tr;
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-verification-code':
            errorMessage = "Invalid verification code".tr;
            break;
          case 'invalid-verification-id':
            errorMessage = "Invalid verification ID".tr;
            break;
          case 'session-expired':
            errorMessage =
                "Verification session expired. Please request a new code".tr;
            break;
          default:
            errorMessage = e.message ?? "Verification failed".tr;
        }
      }

      UIHelper.showBottomFlash(
        context,
        title: "",
        message: errorMessage,
        isError: true,
      );
    }
  }

  // Register user method
  Future<void> _registerUser() async {
    try {
      LoadingProvider loadingProvider = context.read<LoadingProvider>();
      UserViewModel userViewModel = context.read<UserViewModel>();

      loadingProvider.showLoading();

      // Prepare specialties for counselors
      List<int> specialties = [];
      if (!isRegularUser) {
        // Add fortune telling specialties
        for (var fortune in selectedFortunes) {
          specialties.add(fortune.id);
        }
        // Add counseling specialties
        for (var counseling in selectedCounslings) {
          specialties.add(counseling.id);
        }
      }

      // Format phone number (only if phone registration is enabled)
      String? phoneNumber;
      final settingProvider = context.read<SettingProvider>();
      if (settingProvider.isPhoneRegistrationEnabled) {
        phoneNumber = '${selectedCountry ?? ''}${phone.text}';
        if (phoneNumber.startsWith('++')) {
          phoneNumber = phoneNumber.substring(1);
        }
        if (!phoneNumber.startsWith('+')) {
          phoneNumber = '+$phoneNumber';
        }
        print("Phone Number: $phoneNumber");
      }

      // Call registration API
      // userDataHandling will handle success/error messages and navigation
      await userViewModel.registerUserWithAPI(
        context: context,
        name: nameController.text.trim(),
        nickName: nameController.text.trim(), // Using name as nickName for now
        role: enumUserTypes.user.name, // Only regular users use this method
        email:
            settingProvider.isEmailRegistrationEnabled ? email.text.trim() : '',
        phone: phoneNumber ?? '',
        password: password.text,
        passwordConfirmation: cpassword.text,
        documentPath: null, // No document for regular users
        category_id: null, // No specialties for regular users
      );

      // userDataHandling handles loading state, so we don't need to hide it here
    } catch (e) {
      LoadingProvider loadingProvider = context.read<LoadingProvider>();
      loadingProvider.hideLoading();

      print("Registration error: $e");
      UIHelper.showBottomFlash(
        context,
        title: "",
        message: "Registration failed: ${e.toString()}",
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        UIHelper.hideKeyboard(context);
      },
      child: Scaffold(
        appBar: customAppBar(
          title: "Sign Up".tr,
          leading: Container(width: 0.0),
          action: [Container()],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 21),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  //   SizedBox(height: topPadding),
                  LogoView(height: 80.0, width: 80.0),
                  UIHelper.verticalSpaceSm,
                  CustomText(
                    text: AppName,
                    fontSize: FontConstants.font_13,
                    weight: FontWeightConstants.medium,
                  ),
                  // SizedBox(height: 10),
                  UIHelper.verticalSpaceL,
                  CustomTabBar(
                    tabs: ['Regular User'.tr, 'Counselor'.tr],
                    initialIndex: isRegularUser ? 0 : 1,
                    onTabChanged: (index) {
                      setState(() {
                        isRegularUser = (index == 0);
                      });
                    },
                  ),

                  SizedBox(height: 25),
                  Consumer<SettingProvider>(
                    builder: (context, settingProvider, child) {
                      // Get validation settings for better error messages
                      final minLength = settingProvider.minNicknameLength;
                      final maxLength = settingProvider.maxNicknameLength;
                      final allowSpecialChars =
                          settingProvider.allowSpecialCharactersInNickname;

                      return Customtextfield(
                        controller: nameController,
                        required: true,
                        hint: "Enter your name".tr,
                        text: "Name".tr,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        // prefix: Icon(Icons.email),
                        keyboard: TextInputType.emailAddress,
                        suffix: Icon(
                          Icons.email,
                          size: 20,
                          color: suffixIconColor,
                        ),
                        validator: (value) {
                          // First check if empty
                          if (value == null || value.trim().isEmpty) {
                            return "Please insert name".tr;
                          }

                          final trimmedValue = value.trim();

                          // Apply all nickname validation rules from settings
                          // Check minimum length
                          if (minLength > 0 &&
                              trimmedValue.length < minLength) {
                            return "${"Name must be at least".tr} $minLength ${"characters".tr}${"or more required".tr}";
                          }

                          // Check maximum length
                          if (maxLength > 0 &&
                              trimmedValue.length > maxLength) {
                            return "${"Name must not exceed".tr} $maxLength ${"characters maximum".tr}";
                          }

                          // Check for prohibited words
                          final prohibitedWords =
                              settingProvider.prohibitedWords;
                          if (prohibitedWords.isNotEmpty) {
                            final prohibitedList =
                                prohibitedWords
                                    .split(',')
                                    .map((w) => w.trim().toLowerCase())
                                    .where((w) => w.isNotEmpty)
                                    .toList();
                            final lowerValue = trimmedValue.toLowerCase();
                            for (String word in prohibitedList) {
                              if (lowerValue.contains(word)) {
                                return "Name contains prohibited word".tr;
                              }
                            }
                          }

                          // Check special characters restriction
                          if (!allowSpecialChars) {
                            final specialCharRegex = RegExp(
                              r'[!@#$%^&*(),.?":{}|<>\[\]\\/;+=_-]',
                            );
                            if (specialCharRegex.hasMatch(trimmedValue)) {
                              return "Name cannot contain special characters"
                                  .tr;
                            }
                          }

                          // All validations passed
                          return null;
                        },
                      );
                    },
                  ),
                  SizedBox(height: 5),

                  // Email field - only show if email registration is enabled
                  Consumer<SettingProvider>(
                    builder: (context, settingProvider, child) {
                      if (!settingProvider.isEmailRegistrationEnabled) {
                        return SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          Customtextfield(
                            controller: email,
                            required: true,
                            hint: "example@gmail.com".tr,
                            text: "Email".tr,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            keyboard: TextInputType.emailAddress,
                            showPasswordToggle: false,
                            suffix: _buildEmailSuffixIcon(),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Please insert email".tr;
                              } else if (!UIHelper.isEmailValid(value)) {
                                return "Insert valid email".tr;
                              } else if (_emailExists == true) {
                                return "Email already exists".tr;
                              } else {
                                return null;
                              }
                            },
                          ),
                          SizedBox(height: 5),
                        ],
                      );
                    },
                  ),

                  Customtextfield(
                    controller: password,
                    required: true,
                    hint: "Please enter your password".tr,
                    text: "Password".tr,
                    egText:
                        "Minimum 8 characters with letters, numbers, and special characters"
                            .tr,
                    isObscure: !isPasswordVisible,
                    showPasswordToggle: true,
                    //  prefix: Icon(Icons.lock),
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
                  SizedBox(height: 5),
                  Customtextfield(
                    controller: cpassword,
                    required: true,
                    hint: "Please re-enter your password".tr,
                    text: "Confirm password".tr,
                    isObscure: !iscPasswordVisible,
                    showPasswordToggle: true,
                    //  prefix: Icon(Icons.lock),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Insert confirm password".tr;
                      } else if (value.length < 6) {
                        return "Confirm password must grather than 6".tr;
                      } else {
                        return null;
                      }
                    },

                    suffix: GestureDetector(
                      onTap: () {
                        setState(() {
                          iscPasswordVisible = !iscPasswordVisible;
                        });
                      },
                      child: Icon(
                        iscPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  SizedBox(height: 5),
                  // Phone field - only show if phone registration is enabled
                  Consumer<SettingProvider>(
                    builder: (context, settingProvider, child) {
                      if (!settingProvider.isPhoneRegistrationEnabled) {
                        return SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: CustomTextFieldPhone(
                                  required: true,
                                  text: "Phone Number".tr,
                                  hint: "Enter your phone number".tr,

                                  validator: (value) {
                                    if (value!.number.isEmpty) {
                                      return "Insert phone".tr;
                                    }
                                    return null;
                                  },
                                  controller: phone,

                                  onChanged: (data) {
                                    print(data.number);
                                    setState(() {
                                      selectedCountry = data.countryCode;
                                      phone.text = data.number;
                                    });
                                  },
                                  // controller: phone,
                                ),
                              ),
                              UIHelper.horizontalSpaceSm,
                              Container(
                                width: 115.w,
                                height: 50,
                                margin: EdgeInsets.only(top: 15),
                                child: CustomButton(
                                  () async {
                                    await _sendOTP();
                                  },
                                  text:
                                      isOtpSent ? "Resend".tr : "Send Code".tr,
                                  fsize: FontConstants.font_12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                        ],
                      );
                    },
                  ),

                  // OTP Field
                  if (isOtpSent) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,

                      children: [
                        Expanded(
                          child: Customtextfield(
                            required: true,
                            controller: otpController,
                            keyboard: TextInputType.number,
                            text: "Verification Code".tr,
                            hint: "Enter Verification Code".tr,
                            formate: FilteringTextInputFormatter.digitsOnly,
                            onChanged: (data) {},
                          ),
                        ),
                        UIHelper.horizontalSpaceSm,
                        Container(
                          width: 115.w,
                          height: 50,
                          margin: EdgeInsets.only(top: 15),
                          child: CustomButton(
                            () async {
                              String otp = _getOTP();
                              if (otp.length == 6) {
                                await _verifyOTP(otp);
                              } else {
                                UIHelper.showBottomFlash(
                                  context,
                                  title: "",
                                  message: "Please enter 6-digit OTP".tr,
                                  isError: true,
                                );
                              }
                            },
                            text: "Verify".tr,
                            fsize: FontConstants.font_12,
                          ),
                        ),
                      ],
                    ),

                    // Individual OTP Input Boxes
                    SizedBox(height: 5),

                    // Timer
                    Align(
                      alignment: Alignment.centerLeft,
                      child:
                          isOtpVerified
                              ? Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    CustomText(
                                      text: "Phone Verified".tr,
                                      color: Colors.white,
                                      fontSize: FontConstants.font_12,
                                      weight: FontWeightConstants.medium,
                                    ),
                                  ],
                                ),
                              )
                              : CustomText(
                                text:
                                    "Time remaining:".tr +
                                    " ${_formatTime(_countdown)}",
                                fontSize: FontConstants.font_12,
                                color:
                                    _countdown < 60
                                        ? Colors.red
                                        : Colors.grey[600],
                              ),
                    ),
                  ],

                  !isRegularUser
                      ? Container(
                        child: Consumer<UserViewModel>(
                          builder: (context, provider, child) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                UIHelper.verticalSpaceMd,
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: "Specialties".tr,
                                      fontSize: FontConstants.font_14,
                                      weight: FontWeightConstants.medium,
                                      // color: greyColor,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 3.0.sp),
                                      child: CustomText(
                                        text: '*',
                                        fontSize: FontConstants.font_14,
                                        weight: FontWeightConstants.medium,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                UIHelper.verticalSpaceSm5,
                                CustomText(
                                  text:
                                      "Select your areas of expertise. (Multiple selections allowed)"
                                          .tr,
                                  fontSize: FontConstants.font_12,
                                  height: 1.33,
                                  color: Color(0xFF6A7280),
                                ),
                                UIHelper.verticalSpaceMd,
                                CustomText(
                                  text: "Fortune Telling".tr,
                                  fontSize: FontConstants.font_14,
                                  weight: FontWeightConstants.medium,
                                  // color: greyColor,
                                ),
                                UIHelper.verticalSpaceSm,
                                // Replace your existing Wrap(...) with this GridView builder
                                provider.texnomyData == null
                                    ? Container()
                                    : CategoryGrid(
                                      categories:
                                          provider
                                              .texnomyData!
                                              .fortune
                                              .categories,
                                      selected: selectedFortunes,
                                      labelBuilder:
                                          (c) =>
                                              c.name, // how to get display text
                                      primaryColor: primaryColor,
                                      onSelected: (c) {
                                        setState(() {
                                          if (selectedFortunes.contains(c)) {
                                            selectedFortunes.remove(c);
                                          } else {
                                            selectedFortunes.add(c);
                                          }
                                        });
                                      },
                                    ),

                                UIHelper.verticalSpaceMd,
                                UIHelper.verticalSpaceSm,

                                CustomText(
                                  text: "psychological counseling".tr,
                                  fontSize: FontConstants.font_14,
                                  weight: FontWeightConstants.medium,
                                  // color: greyColor,
                                ),
                                UIHelper.verticalSpaceSm,

                                // Replace your existing Wrap(...) with this GridView builder
                                provider.texnomyData == null
                                    ? Container()
                                    : CategoryGrid(
                                      categories:
                                          provider
                                              .texnomyData!
                                              .counseling
                                              .categories,
                                      selected: selectedCounslings,
                                      labelBuilder:
                                          (c) =>
                                              c.name, // how to get display text
                                      primaryColor: primaryColor,
                                      onSelected: (c) {
                                        setState(() {
                                          if (selectedCounslings.contains(c)) {
                                            selectedCounslings.remove(c);
                                          } else {
                                            selectedCounslings.add(c);
                                          }
                                        });
                                      },
                                    ),

                                UIHelper.verticalSpaceMd,
                                CheckboxListTile(
                                  value: _isChecked,

                                  contentPadding: EdgeInsets.all(0),
                                  title: CustomText(
                                    text:
                                        "I agree to the Terms of Service and Privacy Policy"
                                            .tr,
                                    fontSize: FontConstants.font_12,
                                  ),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,

                                  checkboxScaleFactor: 1.2,

                                  subtitle: InkWell(
                                    onTap: () {
                                      String link =
                                          context
                                              .read<SettingProvider>()
                                              .settingsModel!
                                              .data
                                              .termsOfUseLink;
                                      UIHelper.launchInBrowser1(
                                        Uri.parse(link),
                                      );
                                    },
                                    child: CustomText(
                                      text: "View Terms".tr,
                                      fontSize: 12.0.sp,
                                      weight: FontWeightConstants.medium,
                                      color: primaryColor,
                                    ),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      _isChecked = val!;
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      )
                      : Container(),

                  SizedBox(height: 20),
                  CustomButton(() async {
                    UIHelper.hideKeyboard(context);
                    // Check phone verification if phone registration is enabled
                    final settingProvider = context.read<SettingProvider>();
                    if (settingProvider.isPhoneRegistrationEnabled) {
                      if (isRegularUser && !isOtpVerified) {
                        UIHelper.showBottomFlash(
                          context,
                          title: "",
                          message: "Please verify your phone number first".tr,
                          isError: true,
                        );
                        return;
                      }

                      if (phone.text.isEmpty && isRegularUser) {
                        UIHelper.showBottomFlash(
                          context,
                          title: "",
                          message: "Enter Phone".tr,
                          isError: true,
                        );
                        return;
                      }
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

                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    // Check if passwords match
                    if (password.text != cpassword.text) {
                      UIHelper.showBottomFlash(
                        context,
                        title: "",
                        message: "Passwords do not match".tr,
                        isError: true,
                      );
                      return;
                    }

                    // Check if counselor has selected specialties
                    if (!isRegularUser &&
                        selectedFortunes.isEmpty &&
                        selectedCounslings.isEmpty) {
                      UIHelper.showBottomFlash(
                        context,
                        title: "",
                        message: "Please select at least one specialty".tr,
                        isError: true,
                      );
                      return;
                    }

                    // Check if counselor has agreed to terms
                    if (!isRegularUser && !_isChecked) {
                      UIHelper.showBottomFlash(
                        context,
                        title: "",
                        message: "Please agree to the Terms of Service".tr,
                        isError: true,
                      );
                      return;
                    }

                    // Handle registration based on user type
                    if (isRegularUser) {
                      // Direct registration for regular users
                      await _registerUser();
                    } else {
                      // Navigate to document registration for counselors with registration data
                      Get.to(
                        DocumentRegistrationScreen(),
                        arguments: {
                          'name': nameController.text.trim(),
                          'nickName': nameController.text.trim(),
                          'email': email.text.trim(),
                          'phone': '${selectedCountry ?? ''}${phone.text}',
                          'password': password.text,
                          'passwordConfirmation': cpassword.text,
                          'category_id': [...selectedFortunes.map((f) => f.id)],
                          'taxonomie_id': [
                            ...selectedCounslings.map((c) => c.id),
                          ],

                          // 'specialties': [
                          //   ...selectedFortunes.map((f) => f.id),
                          //   ...selectedCounslings.map((c) => c.id),
                          // ],
                        },
                      );
                    }
                  }, text: "Sign Up".tr),
                  UIHelper.verticalSpaceMd,
                  InkWell(
                    onTap: () {
                      Get.off(SignInScreen());
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomText(text: "Already have an account?".tr),
                        UIHelper.horizontalSpaceSm,
                        CustomText(
                          text: "Login".tr,
                          fontSize: FontConstants.font_14,
                          weight: FontWeightConstants.medium,
                        ),
                      ],
                    ),
                  ),
                  UIHelper.verticalSpaceL,
                  orDivider("Quick Sign Up".tr),
                  UIHelper.verticalSpaceSm,

                  CustomSocialbuttons(isRegularUser: isRegularUser),

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
