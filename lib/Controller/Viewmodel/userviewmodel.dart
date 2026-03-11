import 'dart:convert';
import 'dart:io';

import 'package:deepinheart/Controller/Model/counselor_dashboard_model.dart';
import 'package:deepinheart/Controller/Model/coupon_banner_model.dart';
import 'package:deepinheart/Controller/Model/registered_coupon_model.dart';
import 'package:deepinheart/Controller/Model/hashtag_model.dart';
import 'package:deepinheart/Controller/Model/texnomy_model.dart';
import 'package:deepinheart/Controller/Model/time_slots_model.dart';
import 'package:deepinheart/Controller/Model/services_model.dart';
import 'package:deepinheart/Controller/Viewmodel/api_client.dart';
import 'package:deepinheart/Controller/Viewmodel/favorite_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/loading_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/service_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/setting_provider.dart';
import 'package:deepinheart/Controller/locale_controller.dart';
import 'package:deepinheart/services/translation_helper.dart';
import 'package:deepinheart/services/translation_service.dart';
import 'package:deepinheart/widgets/emergency_notice_dialog.dart';
import 'package:deepinheart/main.dart';
import 'package:deepinheart/screens/auth/login_View.dart';
import 'package:deepinheart/screens/home/home_screen.dart';
import 'package:deepinheart/screens_consoler/dashboard_screen.dart';
import 'package:deepinheart/views/custom_text.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deepinheart/config/api_endpoints.dart';

import 'package:deepinheart/views/prefrences.dart';
import 'package:deepinheart/views/ui_helpers.dart';

import '../Model/user_model.dart';

enum listNotificationEnums { service, event }

enum enumUserTypes { counselor, user }

class UserViewModel extends ChangeNotifier {
  //Position? myLocation;
  ApiClient apiClient = ApiClient();
  TexnomyData? texnomyData;
  List<TimeSlotData> timeSlots = [];
  List<HashTagData> hashTags = [];
  CounselorDashboardData? counselorDashboard;
  List<CouponBanner> couponBanners = [];
  List<RegisteredCoupon> registeredCoupons = [];
  List<RegisteredCoupon> usedAndExpiredCoupons = [];

  var fcmToken;
  Future fetchFcmToken() async {
    FirebaseMessaging.instance.getToken().then((value) {
      print(value! + ">>>");
      fcmToken = value;
      notifyListeners();
    });
  }

  UserModel? userModel;

  UserViewModel() {
    fetchFcmToken();
    // determinePosition();
  }

  // Future<Position> determinePosition() async {
  //   bool serviceEnabled;
  //   LocationPermission permission;

  //   // Test if location services are enabled.
  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     // Location services are not enabled don't continue
  //     // accessing the position and request users of the
  //     // App to enable the location services.
  //     return Future.error('Location services are disabled.');
  //   }

  //   permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       // Permissions are denied, next time you could try
  //       // requesting permissions again (this is also where
  //       // Android's shouldShowRequestPermissionRationale
  //       // returned true. According to Android guidelines
  //       // your App should show an explanatory UI now.
  //       return Future.error('Location permissions are denied');
  //     }
  //   }

  //   if (permission == LocationPermission.deniedForever) {
  //     // Permissions are denied forever, handle appropriately.
  //     return Future.error(
  //       'Location permissions are permanently denied, we cannot request permissions.',
  //     );
  //   }

  //   // When we reach here, permissions are granted and we can
  //   // continue accessing the position of the device.

  //   myLocation = await Geolocator.getCurrentPosition();
  //   return myLocation!;
  // }

  clearUserModel() async {
    await logoutApi();

    userModel = null;
    counselorDashboard = null;

    // Clear favorites when user logs out
    try {
      final favoriteProvider = Get.find<FavoriteProvider>();
      favoriteProvider.clearFavorites();
    } catch (e) {
      print('Error clearing favorites: $e');
    }

    // Clear "Remember Me" credentials when user logs out
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('remember_me');
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
    await prefs.remove('saved_is_regular_user');

    notifyListeners();
    Get.offAll(SignInScreen());
  }

  Future logoutApi() async {
    var headers = {'Authorization': 'Bearer ${userModel!.data.token}'};
    var request = http.Request(
      'POST',
      Uri.parse('https://deepinheart.savevidtool.com/api/logout'),
    );

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();
    var data = await response.stream.bytesToString();
    print(data.toString() + "<<<<<");

    if (response.statusCode == 200) {
    } else {
      print(response.reasonPhrase);
    }
  }

  Future loadSharedPrefs() async {
    SharedPref pref = new SharedPref();
    var prefs = await SharedPreferences.getInstance();

    var docId = prefs.getString("docid");

    try {
      notifyListeners();
    } catch (e) {
      print(e.toString() + ":::::");
      // do something
    }
  }

  Future<void> sendPush({var token, var title, body, var payload}) async {
    var params = {
      "to": token,
      "notification": {"title": title, "body": body, "sound": "default"},
      "data": payload,
    };
    var response = await http.post(
      Uri.parse("https://fcm.googleapis.com/fcm/send"),
      headers: {
        "Authorization":
            "key= AAAABKlPjoI:APA91bHgT4disWVDjiYfv3qrGl0VRYFOKgY5eiyOnwCvy-YOLO1wQZB4EMTXgxJ2-xp4-2hbnZofXPg1S95Am21ctqCqJyaXuBnea6aWaBZq2Ylv_GE33EmG2RX0Lhh8SakmH13EJGKW",
        "Content-Type": "application/json",
      },
      body: json.encode(params),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> map = json.decode(response.body);
      print("fcm.google: " + map.toString());
    } else {
      Map<String, dynamic> error = jsonDecode(response.body);
      print("fcm.google: " + error.toString());
    }
  }

  Future<UserModel?> fetchUserProfile({
    context,
    userid,
    token,
    required bool isMyProfile,
  }) async {
    var headers = {'Authorization': 'Bearer $token'};
    var request = http.Request(
      'GET',
      Uri.parse(ApiEndPoints.BASE_URL + 'user/profile/get/$userid'),
    );

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();
    if (isMyProfile) {
      await userDataHandling(response, context, isLogin: false, token: token);
    } else {
      if (response.statusCode == 200) {
        print(request.url.toString() + "+++" + token);
        var data = await response.stream.bytesToString();

        var data1 = jsonDecode(data);
        print("_____" + data.toString());
        UserModel userModel = UserModel.fromJson(data1);

        return userModel;
      } else {
        print(response.reasonPhrase);
      }
    }
  }

  Future updateUserAccount(context) async {
    var headers = {'Authorization': 'Bearer ${userModel!.data.token}'};
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiEndPoints.BASE_URL + 'user/verified/update'),
    );
    request.fields.addAll({'email': userModel!.data.email});

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    await userDataHandling(response, context, isLogin: true, isupdate: true);
  }

  Future socialLogin(context, payload) async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST', Uri.parse(ApiEndPoints.SOCIALLOGIN));
    request.body = json.encode(payload);
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    await userDataHandling(response, context, isLogin: true);
  }

  Future<void> userDataHandling(
    http.StreamedResponse response,
    BuildContext context, {
    required bool isLogin,
    bool isRegister = false,
    isupdate,
    token,
  }) async {
    var data = await response.stream.bytesToString();
    print(data.toString());

    if (response.statusCode == 200) {
      // Parse the JSON response
      print(data);
      var data1 = jsonDecode(data);
      // Update user data model with parsed data
      if (isupdate == null) {
        userModel = UserModel.fromJson(data1);
        if (token != null) {
          userModel!.data.token = token;
        }
        // Save user data in shared preferences
        SharedPref pref =
            new SharedPref(); // Might be a custom class for shared preferences
        var prefs = await SharedPreferences.getInstance();
        prefs.setString("id", userModel!.data.id.toString());
        prefs.setString("token", userModel!.data.token.toString());

        prefs.setBool("islogin", true);
      } else {
        if (token != null) {
          userModel!.data.token = token;
        }
      }
      print(data.toString());
      if (isRegister) {
        UIHelper.showBottomFlash(
          context,
          message: "Registration successful".tr,
          title: "",
          isError: false,
        );
      }
      callCommonApis(context);
      if (userModel!.data.role == enumUserTypes.counselor.name) {
        await callConsulerApis();
        Get.to(DashboardScreen());
      } else {
        await callUserApis();
        // Initialize favorites for regular users
        try {
          final favoriteProvider = Get.find<FavoriteProvider>();
          await favoriteProvider.initializeFavorites();
        } catch (e) {
          print('Error initializing favorites: $e');
        }
        Get.to(HomeScreen());
      }

      // Check and show medium priority emergency announcements after login
      if (isLogin && context.mounted) {
        try {
          final settingProvider = Provider.of<SettingProvider>(
            context,
            listen: false,
          );
          final activeAnnouncements =
              settingProvider.activeEmergencyAnnouncements;
          if (activeAnnouncements.isNotEmpty) {
            // Show medium priority announcements after login
            await Future.delayed(Duration(milliseconds: 500));
            if (context.mounted) {
              EmergencyNoticeDialog.checkAndShowMediumPriority(
                context,
                activeAnnouncements,
              );
            }
          }
        } catch (e) {
          print('Error checking medium priority announcements: $e');
        }
      }

      // if (userModel!.data.user_verified == false) {
      //   //   Get.to(OtpVerificationScreen(email: userModel!.data.email));
      // } else {
      //   // await callApis();
      //   // Get.offAll(HomeScreen());
      // }

      // Potentially update user token in FirebaseFirestore (implementation might be elsewhere)
      // updateTokenFirestore(username, firebasePayload);

      // // Navigate to the Home Screen
      // Get.offAll(HomeScreen());

      // Notify listeners (potentially the UI) about successful login
      notifyListeners();
      context.read<LoadingProvider>().hideLoading();
    } else {
      // Handle unsuccessful login (status code not 200)

      // Parse the error response (assumed to be JSON)
      var data1 = jsonDecode(data);
      var message = parseApiResponse(
        data1['message'],
      ); // Extract the error message

      // Show an alert dialog with the error message (assuming UIHelper is a helper class for UI interactions)
      if (message == "User not verified.") {
        context.read<LoadingProvider>().hideLoading();

        return;
      }
      // TranslationService translationService = translationService;
      // String translatedMessage = await translationService.translate(message);
      String error = await TranslationHelper.translateError(message);
      print("error: $error");
      UIHelper.showBottomFlash(
        context,
        title: isLogin ? "Login Error" : "Register Error",
        message: error,
        isError: true,
      );
      context.read<LoadingProvider>().hideLoading();
    }
  }

  Future callConsulerApis() async {
    print("##########");
    callConsulerDashboardData();
  }

  // load consuler dashboard data
  Future callConsulerDashboardData() async {
    try {
      var headers = {'Authorization': 'Bearer ${userModel!.data.token}'};

      var request = http.Request(
        'GET',
        Uri.parse(ApiEndPoints.COUNSELOR_DASHBOARD),
      );

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        print('Counselor Dashboard Response: $responseBody');

        Map<String, dynamic> jsonResponse = json.decode(responseBody);
        CounselorDashboardModel dashboardModel =
            CounselorDashboardModel.fromJson(jsonResponse);

        if (dashboardModel.success) {
          counselorDashboard = dashboardModel.data;
          notifyListeners();
          print('Dashboard Data Loaded Successfully');
        } else {
          print('Error: ${dashboardModel.message}');
        }
      } else {
        print('Error: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Exception in callConsulerDashboardData: $e');
    }
  }

  Future callUserApis() async {
    print("##########");
    navigatorKey.currentContext!.read<ServiceProvider>().pullRefresh();
    await fetchBannersAndCoupons();
  }

  Future fetchBannersAndCoupons() async {
    try {
      String? token = await getToken();
      if (token == null || token.isEmpty) {
        print('No token available for banners API');
        return;
      }

      var headers = {'Authorization': 'Bearer $token'};
      var request = http.Request(
        'GET',
        Uri.parse('https://deepinheart.savevidtool.com/api/banners'),
      );

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var data = await response.stream.bytesToString();
        var jsonData = jsonDecode(data);
        print('Banners API Response: $data');

        if (jsonData['success'] == true && jsonData['data'] != null) {
          var couponBannerData = CouponBannerData.fromJson(jsonData['data']);
          couponBanners = couponBannerData.couponBanners;
          notifyListeners();
        }
      } else {
        print('Banners API Error: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Exception in fetchBannersAndCoupons: $e');
    }
  }

  String parseApiResponse(dynamic response) {
    if (response is String) {
      // If the response is a simple string message
      return response;
    } else if (response is Map<String, dynamic>) {
      // If the response is a JSON object (likely validation errors)
      List<String> messages = [];
      print(response.toString() + "_____");

      // Iterate through each key (username, email, etc.) and concatenate error messages
      response.entries.forEach((element) {
        messages.add(
          element.value.toString().replaceAll('[', '').replaceAll(']', ''),
        );
      });
      // response.forEach((key, value) {
      //   if (value is List<String>) {
      //     messages.add('${key.capitalize}: ${value.join(", ")}');
      //   }
      // });

      // Return concatenated messages
      return messages.join("\n");
    } else {
      // Handle any other unexpected response types here
      return "Unexpected response format";
    }
  }

  // Future registerUser(context, payload) async {
  //   var headers = {'Content-Type': 'application/json'};
  //   var request = http.Request(
  //     'POST',
  //     Uri.parse(ApiEndPoints.BASE_URL + "user/register"),
  //   );
  //   request.body = json.encode(payload);
  //   request.headers.addAll(headers);

  //   http.StreamedResponse response = await request.send();

  //   await userDataHandling(response, context, isLogin: false);
  // }

  Future sendOtpEmail(context, code) async {
    var headers = {'Authorization': 'Bearer ${userModel!.data.token}'};
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiEndPoints.BASE_URL + 'send/verification/code'),
    );
    request.fields.addAll({'email': userModel!.data.email, 'code': code});

    request.headers.addAll(headers);
    print(request.fields.toString());

    http.StreamedResponse response = await request.send();
    var data = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      var data1 = jsonDecode(data);
      print(data.toString());
    } else {
      var data1 = jsonDecode(data);
      print(data.toString());
      var message = parseApiResponse(data1['message']);
      UIHelper.showBottomFlash(
        context,
        title: "Error",
        message: message,
        isError: true,
      );
    }
  }

  Future fetchTimeSlots() async {
    Map<String, dynamic> response = await apiClient.request(
      url: ApiEndPoints.BASE_URL + "time-slots",
      method: 'GET',
      //  headers: {'Authorization': 'Bearer ${userModel!.data.token}'},
    );
    if (response['success'] == true) {
      print("*****" + response['data'].toString());
      timeSlots = List<TimeSlotData>.from(
        response['data'].map((x) => TimeSlotData.fromJson(x)),
      );
      notifyListeners();
    } else {
      print(response['message']);
    }
  }

  Future calStarterApiWihoutToken() async {
    await fetchtaxonomie();
    await fetchTimeSlots();
    // fetchHashTags();
  }

  // Fetch services data for a specific section
  Future<ServiceModel?> fetchServicesData({
    required int sectionId,
    String? counsler_id,
  }) async {
    ServiceModel? servicesData;
    String url = "";
    if (counsler_id != null) {
      url =
          ApiEndPoints.BASE_URL +
          "services?section_id=$sectionId&counselor_id=$counsler_id&lang=${LocalizationService.getApiLanguageCode()}";
    } else {
      url = ApiEndPoints.BASE_URL + "services?section_id=$sectionId";
    }

    try {
      Map<String, dynamic> response = await apiClient.request(
        url: url,
        method: 'GET',
        headers: {'Authorization': 'Bearer ${userModel!.data.token}'},
      );

      if (response['success'] == true) {
        servicesData = ServiceModel.fromJson(response['data']);

        // Assign translated names to all items in taxonomies
        final List<Future<void>> translationFutures = [];
        final List<Future<void>> translationCategoryFutures = [];

        // for (var taxonomy in servicesData.taxonomies) {
        //   for (var item in taxonomy.items) {
        //     translationFutures.add(
        //       item.getTranslatedName().then((translatedName) {
        //         print("translatedName: $translatedName");
        //         item.nameTranslated = translatedName;
        //       }),
        //     );
        //   }
        // }
        // for (var category in servicesData.categories) {
        // translationCategoryFutures.add(
        //   category.getTranslatedName().then((translatedName) {
        //     print("translatedName: $translatedName");
        //    // category.nameTranslated = translatedName;
        //   }),
        // );
        // }

        // Wait for all translations to complete
        // await Future.wait(translationFutures);
        // await Future.wait(translationCategoryFutures);

        print("Services data fetched successfully");
        return servicesData;
      } else {
        print('API returned success: false');
        print('Error message: ${response['message']}');
      }
    } catch (e) {
      print('Error fetching services data: $e');
      print('Error type: ${e.runtimeType}');
      if (e is Exception) {
        print('Exception details: ${e.toString()}');
      }
      setLoading(false);
    }
    return servicesData;
  }

  // Clear services data
  void clearServicesData() {
    //servicesData = null;
    notifyListeners();
  }

  Future fetchHashTags() async {
    Map<String, dynamic> response = await apiClient.request(
      url: ApiEndPoints.BASE_URL + "hashtags",
      method: 'GET',
      headers: {'Authorization': 'Bearer ${userModel!.data.token}'},
    );
    if (response['success'] == true) {
      hashTags = List<HashTagData>.from(
        response['data'].map((x) => HashTagData.fromJson(x)),
      );
      notifyListeners();
    } else {
      print(response['message']);
    }
  }

  //add hash tage api
  Future addHashTag(payload) async {
    setLoading(true);
    try {
      final response = await apiClient.request(
        url: ApiEndPoints.BASE_URL + 'hashtag-store',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${userModel!.data.token}',
        },
        body: payload,
      );
      setLoading(false);

      return response;
    } catch (e) {
      setLoading(false);

      print('Error adding hashtag: $e');
      return null;
    }
  }

  Future fetchtaxonomie() async {
    Map<String, dynamic> response = await apiClient.request(
      url:
          ApiEndPoints.BASE_URL +
          "taxonomie?lang=${LocalizationService.getApiLanguageCode()}",
      method: 'GET',
      //  headers: {'Authorization': ApiEndPoints.SecretKey},
    );

    if (response['success'] == true) {
      print(response['data']['counseling'].toString());
      texnomyData = TexnomyData.fromJson(response['data']);
      notifyListeners();
      print(
        "Taxonomie fetched successfully" + texnomyData!.toJson().toString(),
      );
    } else {}
  }

  // Register user method using multipart request
  Future<Map<String, dynamic>> registerUserWithAPI({
    required BuildContext context,
    required String name,
    required String nickName,
    required String role, // 'user' or 'counselor'
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    String? documentPath,
    List<int>? category_id,
    List<int>? taxonomie_id,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndPoints.BASE_URL + "register"),
      );

      // Add form fields
      request.fields.addAll({
        'name': name,
        'nick_name': nickName,
        'role': role,
        'email': email,
        'phone': phone,
        'fcm_token': fcmToken ?? "default-token",
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

      // Add specialties if provided (for counselors)
      if (category_id != null && category_id.isNotEmpty) {
        for (int i = 0; i < category_id.length; i++) {
          request.fields['category_id[$i]'] = category_id[i].toString();
        }
      }
      if (taxonomie_id != null && taxonomie_id.isNotEmpty) {
        for (int i = 0; i < taxonomie_id.length; i++) {
          request.fields['taxonomie_id[$i]'] = taxonomie_id[i].toString();
        }
      }

      // Add document file if provided
      if (documentPath != null && documentPath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('document', documentPath),
        );
      }

      print("Registration request fields: ${request.fields}");
      print("Registration request files: ${request.files.length}");

      http.StreamedResponse response = await request.send();

      // Use userDataHandling to process the response, save token, and navigate
      // This is the same flow as login
      await userDataHandling(
        response,
        context,
        isLogin: false,
        isRegister: true,
      );

      // If we reach here, registration was successful
      return {'success': true, 'message': 'Registration successful'};
    } catch (e) {
      print("Registration error: $e");
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}',
      };
    }
  }

  // Login user method
  Future loginUser({
    required BuildContext context,
    required String role, // 'user' or 'counselor'
    required String email,
    required String password,
  }) async {
    // try {
    var request = http.Request(
      'POST',
      Uri.parse(ApiEndPoints.BASE_URL + "login"),
    );

    // Add request body
    request.body = json.encode({
      "role": role,
      "email": email,
      "fcm_token": fcmToken ?? "default-token",
      "password": password,
    });

    // Add headers
    request.headers.addAll({'Content-Type': 'application/json'});

    print("Login request body: ${request.body}");

    http.StreamedResponse response = await request.send();
    await userDataHandling(response, context, isLogin: true);

    // if (response.statusCode == 200) {
    //   // Parse response
    //   Map<String, dynamic> responseData = jsonDecode(responseBody);
    //   userModel = userModelFromJson(responseBody);
    //   notifyListeners();
    //   if (userModel!.data.role == enumUserTypes.counselor.name) {
    //     Get.to(DashboardScreen());
    //   }

    //   // return {
    //   //   'success': true,
    //   //   'message': responseData['message'] ?? 'Login successful',
    //   //   'data': responseData['data'],
    //   //   'token': responseData['token'],
    //   //   'user': responseData['user'],
    //   // };
    // } else {
    //   // Login failed
    //   Map<String, dynamic>? errorData = {};
    //   try {
    //     errorData = jsonDecode(responseBody);
    //     UIHelper.showBottomFlash(
    //       navigator!.context,
    //       title: "",
    //       message: errorData!['message'] ?? "Login failed".tr,
    //       isError: true,
    //     );
    //   } catch (e) {
    //     print("Error parsing response: $e");
    //     UIHelper.showBottomFlash(
    //       navigator!.context,
    //       title: "",
    //       message: e.toString(),
    //       isError: true,
    //     );
    //   }

    //   return {
    //     'success': false,
    //     'message': errorData?['message'] ?? 'Login failed',
    //     'errors': errorData?['errors'],
    //   };
    // }
    // } catch (e) {
    //   print("Login error: $e");
    //   return {'success': false, 'message': 'Login failed: ${e.toString()}'};
    // }
  }

  // Social login method with new API
  Future socialLoginWithAPI({
    required String name,
    required String role, // 'user' or 'counselor'
    required String email,
    required String providerId,
    required String socialType, // 'google', 'apple', 'facebook', etc.
  }) async {
    try {
      var request = http.Request(
        'POST',
        Uri.parse(ApiEndPoints.BASE_URL + "social-login"),
      );

      // Add request body
      request.body = json.encode({
        "name": name,
        "role": role,
        "email": email,
        "fcm_token": fcmToken ?? "default-token",
        "provider_id": providerId,
        "social_type": socialType,
      });

      // Add headers
      request.headers.addAll({'Content-Type': 'application/json'});

      print("Social login request body: ${request.body}");

      http.StreamedResponse response = await request.send();

      userDataHandling(response, navigatorKey.currentContext!, isLogin: true);
    } catch (e) {
      print("Social login error: $e");
      return {
        'success': false,
        'message': 'Social login failed: ${e.toString()}',
      };
    }
  }

  void createServiceAPI(
    BuildContext context,
    Map<String, dynamic> serviceData,
  ) async {
    try {
      // Show loading
      setLoading(true);

      // Make API call
      final response = await apiClient.request(
        url: ApiEndPoints.BASE_URL + 'service',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${userModel!.data.token}',
        },
        body: serviceData,
      );

      // Hide loading
      setLoading(false);

      if (response['success'] == true) {
        String message = await translationService.translate(
          response['message'],
        );
        print("+++++message: $message");
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: CustomText(text: 'Service Updated Successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back or to next screen
      } else {
        // Show error message
        setLoading(false);
        String message = await translationService.translate(
          response['message'],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: CustomText(text: message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hide loading
      setLoading(false);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: CustomText(text: 'Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future setLoading(bool show) async {
    BuildContext context = Get.context!;
    if (show) {
      context.read<LoadingProvider>().showLoading();
    } else {
      context.read<LoadingProvider>().hideLoading();
    }
  }

  // Document upload API method
  Future<Map<String, dynamic>?> uploadDocuments(
    BuildContext context,
    List<Map<String, dynamic>> documents,
  ) async {
    try {
      // Show loading
      setLoading(true);

      // Prepare multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndPoints.BASE_URL + 'document-upload'),
      );

      // Add authorization header
      request.headers.addAll({
        'Authorization': 'Bearer ${userModel!.data.token}',
      });

      // Add documents to the request
      for (int i = 0; i < documents.length; i++) {
        final doc = documents[i];
        final filePath = doc['filePath'] as String;
        final fileName = doc['name'] as String;

        // Add document name field
        request.fields['documents[$i][name]'] = fileName;

        // Add file
        request.files.add(
          await http.MultipartFile.fromPath('documents[$i][file]', filePath),
        );
      }

      // Send request
      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();

      // Hide loading
      setLoading(false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = jsonDecode(responseBody);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: CustomText(text: 'Documents uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        return data;
      } else {
        var data = jsonDecode(responseBody);
        String errorMessage = data['message'] ?? 'Failed to upload documents';

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: CustomText(text: errorMessage),
            backgroundColor: Colors.red,
          ),
        );

        return null;
      }
    } catch (e) {
      // Hide loading
      setLoading(false);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: CustomText(
            text: 'Error uploading documents: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return null;
    }
  }

  // Get uploaded documents API method
  Future<List<Map<String, dynamic>>> getUploadedDocuments() async {
    try {
      Map<String, dynamic> response = await apiClient.request(
        url: ApiEndPoints.BASE_URL + "documents",
        method: 'GET',
        headers: {'Authorization': 'Bearer ${userModel!.data.token}'},
      );

      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['data'] ?? []);
      } else {
        print('Error fetching documents: ${response['message']}');
        return [];
      }
    } catch (e) {
      print('Error fetching documents: $e');
      return [];
    }
  }

  // Delete document API method
  Future<bool> deleteDocument(String documentId) async {
    try {
      // Use direct HTTP request to avoid API client URL concatenation issue
      var headers = {
        'Authorization': 'Bearer ${userModel!.data.token}',
        'Content-Type': 'application/json',
      };

      var request = http.Request(
        'DELETE',
        Uri.parse(ApiEndPoints.BASE_URL + 'document-delete/$documentId'),
      );

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print('Delete response status: ${response.statusCode}');
      print('Delete response body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          var data = jsonDecode(responseBody);
          if (data['success'] == true) {
            return true;
          } else {
            print('Error deleting document: ${data['message']}');
            return false;
          }
        } catch (e) {
          // If response is not JSON, but status is 200, consider it successful
          print(
            'Response is not JSON but status is ${response.statusCode}, considering successful',
          );
          return true;
        }
      } else {
        print('Delete failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error deleting document: $e');
      return false;
    }
  }

  // Fetch user data for personal profile
  Future<UserModel?> fetchUserData() async {
    try {
      String token = userModel!.data.token;
      // Check if userModel exists and has a token
      // if (userModel == null || userModel!.data.token.isEmpty) {
      //   print('No user token available for fetchUserData');
      //   return null;
      // }

      var headers = {'Authorization': 'Bearer ${userModel!.data.token}'};
      var request = http.Request(
        'GET',
        Uri.parse(ApiEndPoints.BASE_URL + 'user'),
      );

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var data = await response.stream.bytesToString();
        var jsonData = jsonDecode(data);
        print("User data fetched: " + data.toString());

        userModel = UserModel.fromJson(jsonData);
        userModel!.data.token = token;
        notifyListeners();

        return userModel;
      } else {
        print('Failed to fetch user data: ${response.statusCode}');
        print('Response: ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // Update personal information
  Future<Map<String, dynamic>> updatePersonalInfo({
    required String gender,
    required String nickName,
    required String phone,
    required String address1,
    required String address2,
    required String introduction,
    required String zip,
    File? image,
  }) async {
    try {
      // Check if userModel exists and has a token
      // if (userModel == null || userModel!.data.token.isEmpty) {
      //   print('No user token available for updatePersonalInfo');
      //   return {
      //     'success': false,
      //     'message': 'No authentication token available. Please login again.',
      //   };
      // }

      //  var headers = {'Authorization': 'Bearer ${userModel!.data.token}'};
      var headers = {'Authorization': 'Bearer ${userModel!.data.token}'};
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndPoints.BASE_URL + 'personal-info'),
      );

      request.headers.addAll(headers);

      // Add form fields
      request.fields['gender'] = gender;
      request.fields['nick_name'] = nickName;
      request.fields['phone'] = phone;
      request.fields['address1'] = address1;
      request.fields['address2'] = address2;
      request.fields['introduction'] = introduction;
      request.fields['zip'] = zip;

      // Add image if provided
      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var data = await response.stream.bytesToString();
        var jsonData = jsonDecode(data);
        print("Personal info updated: " + data.toString());

        return {
          'success': true,
          'data': jsonData,
          'message': 'Profile updated successfully',
        };
      } else {
        var errorData = await response.stream.bytesToString();
        print('Failed to update personal info: ${response.statusCode}');
        print('Error response: $errorData');

        return {
          'success': false,
          'message': 'Failed to update profile',
          'error': errorData,
        };
      }
    } catch (e) {
      print('Error updating personal info: $e');
      return {'success': false, 'message': 'Error updating profile: $e'};
    }
  }

  // Change password method
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      // Get token from current userModel or from SharedPreferences
      String? token;

      if (userModel != null && userModel!.data.token.isNotEmpty) {
        token = userModel!.data.token;
        print(
          'Using token from userModel for change password: ${token.substring(0, 10)}...',
        );
      } else {
        // Try to get token from SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        token = prefs.getString('user_token');
        print(
          'Using token from SharedPreferences for change password: ${token?.substring(0, 10)}...',
        );
      }

      if (token == null || token.isEmpty) {
        print('No token available for changePassword');
        return {
          'success': false,
          'message': 'No authentication token available. Please login again.',
        };
      }

      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      var request = http.Request(
        'POST',
        Uri.parse(ApiEndPoints.BASE_URL + 'change-password'),
      );

      request.headers.addAll(headers);
      request.body = jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      });

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var data = await response.stream.bytesToString();
        var jsonData = jsonDecode(data);
        print("Password changed successfully: " + data.toString());

        return {
          'success': true,
          'data': jsonData,
          'message': 'Password changed successfully',
        };
      } else {
        var errorData = await response.stream.bytesToString();
        print('Failed to change password: ${response.statusCode}');
        print('Error response: $errorData');

        return {
          'success': false,
          'message': 'Failed to change password',
          'error': errorData,
        };
      }
    } catch (e) {
      print('Error changing password: $e');
      return {'success': false, 'message': 'Error changing password: $e'};
    }
  }

  // Update coins directly in the user model (for immediate UI update)
  void updateCoins(int newCoins) {
    if (userModel != null) {
      userModel!.data.coins = newCoins;
      notifyListeners();
      print('Coins updated to: $newCoins');
    }
  }

  // Add coins to current balance (for immediate UI update)
  void addCoins(int coinsToAdd) {
    if (userModel != null) {
      userModel!.data.coins = (userModel!.data.coins ?? 0) + coinsToAdd;
      notifyListeners();
      print('Added $coinsToAdd coins. New balance: ${userModel!.data.coins}');
    }
  }

  // Get token for API calls
  Future<String?> getToken() async {
    if (userModel != null && userModel!.data.token.isNotEmpty) {
      return userModel!.data.token;
    }

    // Fallback to SharedPreferences if userModel is null
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  void callCommonApis(BuildContext context) {
    context.read<SettingProvider>().fetchEmergencyAnnouncements(context);
    //   fetchHashTags();
  }

  // Register coupon
  Future<Map<String, dynamic>> registerCoupon(String couponCode) async {
    try {
      String? token = await getToken();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'No token available for coupon registration',
        };
      }

      var headers = {'Authorization': 'Bearer $token'};
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://deepinheart.savevidtool.com/api/register-coupon'),
      );
      request.fields.addAll({'coupon_code': couponCode});

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var data = await response.stream.bytesToString();
        var jsonData = jsonDecode(data);
        print('Coupon registration response: $data');

        // Refresh coupons after successful registration
        await fetchBannersAndCoupons();

        return {
          'success': true,
          'message': jsonData['message'] ?? 'Coupon registered successfully',
          'data': jsonData,
        };
      } else {
        var errorData = await response.stream.bytesToString();
        var jsonError = jsonDecode(errorData);
        print('Coupon registration error: ${response.reasonPhrase}');
        print('Error response: $errorData');

        return {
          'success': false,
          'message': jsonError['message'] ?? 'Failed to register coupon',
          'data':
              jsonError['data'], // Include parsed data field for validation errors
          'error': errorData,
        };
      }
    } catch (e) {
      print('Exception in registerCoupon: $e');
      return {'success': false, 'message': 'Error registering coupon: $e'};
    }
  }

  // Fetch registered coupons
  Future fetchRegisteredCoupons() async {
    try {
      String? token = await getToken();
      if (token == null || token.isEmpty) {
        print('No token available for registered coupons API');
        return;
      }

      var headers = {'Authorization': 'Bearer $token'};
      var request = http.Request(
        'GET',
        Uri.parse('https://deepinheart.savevidtool.com/api/registered-coupons'),
      );

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var data = await response.stream.bytesToString();
        var jsonData = jsonDecode(data);
        print('Registered coupons API Response: $data');

        if (jsonData['success'] == true && jsonData['data'] != null) {
          var registeredCouponData = RegisteredCouponData.fromJson(
            jsonData['data'],
          );
          registeredCoupons = registeredCouponData.registeredCoupons;
          usedAndExpiredCoupons = registeredCouponData.usedAndExpiredCoupons;
          notifyListeners();
        }
      } else {
        print('Registered coupons API Error: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Exception in fetchRegisteredCoupons: $e');
    }
  }
}
