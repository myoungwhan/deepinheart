// import 'dart:convert';
// import 'dart:typed_data';

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
// import 'package:flutter/material.dart' as flutter;
// import 'package:flutter/material.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:get/get.dart';
// import 'package:get/get_connect/http/src/request/request.dart';
// import 'package:photo_view/photo_view.dart';
// import 'package:image/image.dart' as img; // Import for copyResize
// import 'package:provider/provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:http/http.dart' as http;
// import 'package:esys_flutter_share_plus/esys_flutter_share_plus.dart' as easy;
// import 'package:deepinheart/Controller/Model/user_model.dart';
// import 'package:deepinheart/views/ui_helpers.dart';

// class DynamicLinkService {
//   FirebaseDynamicLinks dynamicLinks = FirebaseDynamicLinks.instance;

//   Future handleDynamicLinks() async {
//     // 1. Get the initial dynamic link if the app is opened with a dynamic link
//     PendingDynamicLinkData? data =
//         await FirebaseDynamicLinks.instance.getInitialLink();

//     // 2. handle link that has been retrieved
//     if (data != null) {
//       _handleDeepLink(data);
//     }

//     // 3. Register a link callback to fire if the app is opened up from the background
//     // using a dynamic link.
//     dynamicLinks.onLink.listen((dynamicLinkData) {
//       _handleDeepLink(dynamicLinkData);
//     }).onError((error) {
//       print('onLink error');
//       print(error.message);
//     });
//   }

//   Future<void> _handleDeepLink(PendingDynamicLinkData? data) async {
//     final Uri? deepLink = data?.link;
//     if (deepLink != null) {
//       if (deepLink.path == '/seeprofile') {
//         final String userId = deepLink.queryParameters['id'] ?? '';

//         UserModel? model = await fetchUserProfileById(userId);
//         if (model != null) {
//           await Future.delayed(Duration(seconds: 4)).then((value) {
//             //   Get.to(UserDetailScreen(model: model));
//           });
//         }
//       }
//     }
//   }

//   Future<void> createDynamicLin(UserModel category) async {
//     EasyLoading.show(status: "Generating link");
//     final DynamicLinkParameters parameters = DynamicLinkParameters(
//       uriPrefix: 'https://facecard.page.link',
//       link: Uri.parse(
//           'https://facecard.page.link/seeprofile?id=${category.docId}'),
//       androidParameters: AndroidParameters(
//         packageName: 'com.appeleate.facecard',
//       ),
//       iosParameters: IOSParameters(
//         bundleId: 'com.appeleate.facecard',
//       ),
//       socialMetaTagParameters: SocialMetaTagParameters(
//           description: "",
//           imageUrl: Uri.parse(category.face_1),
//           title: "Lets See ${category.username} on FaceCard"),
//     );

//     final ShortDynamicLink dynamicUrl =
//         await dynamicLinks.buildShortLink(parameters);
//     final Uri shortUrl = dynamicUrl.shortUrl;
//     final Uri longurl = await dynamicLinks.buildLink(parameters);
//     print('Short URL: $shortUrl');
//     print('Long Url: $longurl');
//     await resizeAndShareImage(category.face_1, shortUrl.toString());
//     //await Share.share(shortUrl.toString());
//   }
// }

// Future<void> resizeAndShareImage(String imageUrl, short) async {
//   try {
//     final response = await http.get(Uri.parse(imageUrl));
//     final bytes = await http
//         .get(Uri.parse(imageUrl))
//         .then((response) => response.bodyBytes);

//     // Share the image on WhatsApp
//     EasyLoading.dismiss();
//     await easy.Share.file(short, 'amlog.jpg', bytes, 'image/jpg', text: short);
//     UIHelper.showMySnak(
//         title: "Saved",
//         message: "Link is generated successfully",
//         isError: false);
//   } catch (error) {
//     // Handle any errors during image fetching, resizing, or sharing
//     print("Error: $error");
//   }
// }

// Future<UserModel?> fetchUserProfileById(docId) async {
//   UserModel? model;
//   await FirebaseFirestore.instance
//       .collection("users")
//       .doc(docId)
//       .get()
//       .then((value) async {
//     if (value.exists) {
//       model = UserModel.fromJson(value.data());
//       model!.docId = value.id;
//     }
//   });
//   return model!;
// }
