import 'dart:convert';
import 'dart:io';

import 'package:deepinheart/Controller/Viewmodel/booking_viewmodel.dart';
import 'package:deepinheart/Controller/Viewmodel/counselor_appointment_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/favorite_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/payment_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/service_provider.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:deepinheart/Controller/Viewmodel/setting_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/notification_provider.dart';
import 'package:deepinheart/Controller/theme_controller.dart';
import 'package:deepinheart/screens_consoler/chat/providers/chat_provider.dart';
import 'package:deepinheart/config/paypal_config.dart';
import 'package:deepinheart/screens/auth/splashscreen.dart';
import 'package:deepinheart/screens_consoler/dashboard_screen.dart';
import 'package:deepinheart/services/translation_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' as getx;
import 'package:flutter/services.dart';
import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deepinheart/Controller/Viewmodel/loading_provider.dart';
import 'package:deepinheart/Controller/locale_controller.dart';
import 'package:deepinheart/firebase_options.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/loader/loading_dialog.dart';
import 'package:deepinheart/widgets/emergency_notice_dialog.dart';

import 'Controller/Viewmodel/userviewmodel.dart';
import 'config/size_config.dart';
import 'config/theme_data.dart';
import 'views/prefrences.dart';
import 'views/ui_helpers.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/date_symbol_data_local.dart';

bool isArabic = false;

// isMainDark getter - accesses ThemeController for dark mode state
// Use this throughout the app instead of a static variable
bool get isMainDark {
  try {
    final themeController = Get.find<ThemeController>();
    return themeController.isDarkMode.value;
  } catch (e) {
    // If ThemeController is not initialized yet, return false (light mode)
    return false;
  }
}

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message ${message.messageId}');
  setupFlutterNotifications();
  // showFlutterNotification(message);
}

Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.high,
    showBadge: true,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Create an Android Notification Channel.
  ///
  /// We use this channel in the `AndroidManifest.xml` file to override the
  /// default FCM channel to enable heads up notifications.
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  isFlutterLocalNotificationsInitialized = true;
  const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings('app_icon');
  const DarwinInitializationSettings darwinInitializationSettings =
      DarwinInitializationSettings();

  final InitializationSettings initializationSettings = InitializationSettings(
    android: androidInitializationSettings,
    iOS: darwinInitializationSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      handleDataOnMessage(response);
    },
  );

  // Create emergency notice notification channel
  const emergencyChannel = AndroidNotificationChannel(
    'emergency_notices_channel',
    'Emergency Notices',
    description: 'Notifications for emergency announcements',
    importance: Importance.high,
    showBadge: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(emergencyChannel);
}

/// Show local push notification for emergency notice
Future<void> showEmergencyNoticeNotification({
  required int announcementId,
  required String title,
  required String content,
}) async {
  try {
    print('📱 showEmergencyNoticeNotification called');
    print('   - Initialized: $isFlutterLocalNotificationsInitialized');

    if (!isFlutterLocalNotificationsInitialized) {
      print('   - Initializing notifications...');
      await setupFlutterNotifications();
      print('   - Notifications initialized');
    }

    // Ensure emergency channel is created
    const emergencyChannel = AndroidNotificationChannel(
      'emergency_notices_channel',
      'Emergency Notices',
      description: 'Notifications for emergency announcements',
      importance: Importance.high,
      showBadge: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(emergencyChannel);

    print('   - Emergency channel created/verified');

    const AndroidNotificationDetails
    androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'emergency_notices_channel',
      'Emergency Notices',
      channelDescription: 'Notifications for emergency announcements',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher', // Try default icon if app_icon doesn't work
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Truncate content if too long
    final notificationBody =
        content.length > 150 ? '${content.substring(0, 150)}...' : content;

    print('   - Showing notification with ID: $announcementId');
    print('   - Title: $title');
    print('   - Body: $notificationBody');

    await flutterLocalNotificationsPlugin.show(
      announcementId, // Use announcement ID as notification ID
      title,
      notificationBody,
      platformChannelSpecifics,
      payload: jsonEncode({
        'type': 'emergency_notice',
        'announcement_id': announcementId.toString(),
      }),
    );

    print('✅ Notification displayed successfully');
  } catch (e, stackTrace) {
    print('❌ Error in showEmergencyNoticeNotification: $e');
    print('   Stack trace: $stackTrace');
    rethrow;
  }
}

String? _getImageUrl(RemoteNotification notification) {
  if (Platform.isIOS && notification.apple != null)
    return notification.apple?.imageUrl;
  if (Platform.isAndroid && notification.android != null)
    return notification.android?.imageUrl;
  return null;
}

//Future<String?> _downloadAndSavePicture(String? url, String fileName) async {
//   if (url == null) return null;
//   final Directory directory = await getApplicationDocumentsDirectory();
//   final String filePath = '${directory.path}/$fileName';
//   final http.Response response = await http.get(Uri.parse(url));
//   final File file = File(filePath);
//   await file.writeAsBytes(response.bodyBytes);
//   return filePath;
// }
Future handleDataOnMessage(NotificationResponse message) async {
  print("6");
  try {
    Map<String, dynamic> data = jsonDecode(message.payload.toString());

    // Handle emergency notice notification tap
    if (data['type'] == 'emergency_notice' && data['announcement_id'] != null) {
      // Show emergency notice dialog when notification is tapped
      if (navigatorKey.currentContext != null) {
        final settingProvider = Provider.of<SettingProvider>(
          navigatorKey.currentContext!,
          listen: false,
        );
        final announcements = settingProvider.activeEmergencyAnnouncements;
        final announcementId = int.tryParse(data['announcement_id'].toString());
        if (announcementId != null && announcements.isNotEmpty) {
          final announcement = announcements.firstWhere(
            (a) => a.id == announcementId,
            orElse: () => announcements.first,
          );
          EmergencyNoticeDialog.show(
            navigatorKey.currentContext!,
            announcement: announcement,
          );
        }
      }
    }
  } catch (e) {
    print("Error handling notification: $e");
  }
}

BigPictureStyleInformation? _buildBigPictureStyleInformation(
  String title,
  String body,
  String? picturePath,
  bool showBigPicture,
) {
  if (picturePath == null) return null;
  final FilePathAndroidBitmap filePath = FilePathAndroidBitmap(picturePath);
  return BigPictureStyleInformation(
    showBigPicture ? filePath : const FilePathAndroidBitmap("empty"),
    largeIcon: filePath,
    contentTitle: title,
    htmlFormatContentTitle: true,
    summaryText: body,
    htmlFormatSummaryText: true,
  );
}

NotificationDetails _buildDetails(
  String title,
  String body,
  String? picturePath,
  bool showBigPicture,
) {
  final AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        // styleInformation: _buildBigPictureStyleInformation(
        //     title, body, picturePath, showBigPicture),
        importance: channel.importance,
        icon: "app_icon",
      );
  final DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(
        attachments: [
          // if (picturePath != null) IOSNotificationAttachment(picturePath)
        ],
      );
  final NotificationDetails details = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );
  return details;
}

Future showFlutterNotification(RemoteMessage message) async {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  AppleNotification? apple = message.notification?.apple;
  // var downloadPath = await _downloadAndSavePicture(
  //     await _getImageUrl(notification!), "icon.png");
  var downloadPath = "";
  print(
    "here is push body......." +
        message.data.toString() +
        "mmm" +
        notification.toString(),
  );

  if (notification != null && android != null) {
    // fetchPropertyWithId(id: message.data["property_id"]);
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      _buildDetails(
        notification.title ?? "",
        notification.body ?? "",
        downloadPath,
        true,
      ),
      payload: jsonEncode(message.data),
    );
  } else if (notification != null && apple != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(iOS: DarwinNotificationDetails()),
      payload: jsonEncode(message.data),
    );
  } else {}
}

bool isFlutterLocalNotificationsInitialized = false;

loadSharedPrefs() async {
  SharedPref pref = new SharedPref();
  var prefs = await SharedPreferences.getInstance();

  var docId = prefs.getString("docid");

  try {} catch (Excepetion) {
    // do something
  }
}

/// Create a [AndroidNotificationChannel] for heads up notifications
late AndroidNotificationChannel channel;

/// Initialize the [FlutterLocalNotificationsPlugin] package.
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
GoogleSignIn googleSignIn = GoogleSignIn(
  // Optional clientId
  // clientId: '479882132969-9i9aqik3jfjd7qhci1nqf0bm2g71rm1u.apps.googleusercontent.com',
  scopes: <String>['email', 'https://www.googleapis.com/auth/userinfo.profile'],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Stripe
  Stripe.publishableKey = PaymentConfig.stripePublishableKey;
  Stripe.merchantIdentifier = 'merchant.com.deepinheart';
  Stripe.urlScheme = 'deepinheart';

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  setupFlutterNotifications();

  // Initialize Kakao SDK
  KakaoSdk.init(
    nativeAppKey: 'YOUR_NATIVE_APP_KEY_HERE',
    javaScriptAppKey: 'YOUR_JAVASCRIPT_APP_KEY_HERE',
  );

  // Initialize Translation Service for API response translation
  try {
    await translationService.initialize();
    debugPrint('✅ Translation Service initialized in main');
    // Download translation model if not already downloaded - wait for completion
    final modelDownloaded = await translationService.downloadModel();
    if (modelDownloaded) {
      debugPrint('✅ Translation model ready - proceeding to app');
    } else {
      debugPrint('⚠️ Translation model download failed, but proceeding anyway');
    }
  } catch (e) {
    debugPrint('⚠️ Translation Service initialization failed: $e');
  }

  // runApp(MyApp());
  initializeDateFormatting().then((_) => runApp(MyApp()));
}

class MyApp extends StatefulWidget {
  MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _currentLocale = LocalizationService.locale;

  // This widget is the root of your application.
  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
    FirebaseMessaging.instance.getToken().then((value) {
      print(value);
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print(">>>" + message.data.toString());

      Map<String, dynamic> data = message.data;

      showFlutterNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(
        'A new onMessageOpenedApp event was published!' +
            message.data.toString(),
      );

      //  showFlutterNotification(message);
    });

    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        print('App opened with a notification!');
        print('Message data: ${message.data}');

        // Handle navigation to a specific screen here
      }
    });
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString('saved_language_code');
      final savedCountryCode = prefs.getString('saved_country_code');

      if (savedLanguageCode != null && savedLanguageCode.isNotEmpty) {
        // Find the exact matching locale from supported locales
        Locale? matchedLocale;
        for (final locale in LocalizationService.locales) {
          if (locale.languageCode == savedLanguageCode) {
            // If country code matches or is empty/null, use this locale
            if (savedCountryCode == null ||
                savedCountryCode.isEmpty ||
                locale.countryCode == savedCountryCode) {
              matchedLocale = locale;

              break;
            }
          }
        }

        if (matchedLocale != null) {
          setState(() {
            _currentLocale = matchedLocale!;
          });
          Get.updateLocale(matchedLocale);

          // Find the corresponding language string for changeLocale
          final localeIndex = LocalizationService.locales.indexOf(
            matchedLocale,
          );
          if (localeIndex >= 0 &&
              localeIndex < LocalizationService.langs.length) {
            final languageString = LocalizationService.langs[localeIndex];
            LocalizationService().changeLocale(languageString);
          } else {
            // Fallback: update translation service directly
            translationService.onLocaleChange();
          }
          context.read<UserViewModel>().fetchtaxonomie();

          debugPrint('✅ Loaded saved language: $savedLanguageCode');
        } else {
          debugPrint(
            '⚠️ Saved language $savedLanguageCode not in supported locales',
          );
        }
      } else {
        debugPrint('ℹ️ No saved language found, using default');
      }
    } catch (e) {
      debugPrint('❌ Error loading saved language: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.put(ThemeController());
    return getx.SimpleBuilder(
      builder: (_) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<LoadingProvider>(
              create: (_) => LoadingProvider(),
            ),
            ChangeNotifierProvider<UserViewModel>(
              create: (_) => UserViewModel()..calStarterApiWihoutToken(),
            ),
            ChangeNotifierProvider<ServiceProvider>(
              create: (_) => ServiceProvider(),
            ),
            ChangeNotifierProvider<BookingViewmodel>(
              create: (_) => BookingViewmodel(),
            ),
            ChangeNotifierProvider<PaymentProvider>(
              create: (_) => PaymentProvider(),
            ),
            ChangeNotifierProvider<FavoriteProvider>(
              create: (_) => FavoriteProvider(),
            ),
            ChangeNotifierProvider<CounselorAppointmentProvider>(
              create: (_) => CounselorAppointmentProvider(),
            ),
            ChangeNotifierProvider<SettingProvider>(
              create: (_) => SettingProvider(context),
            ),
            ChangeNotifierProvider<ChatProvider>(create: (_) => ChatProvider()),
            ChangeNotifierProvider<NotificationProvider>(
              create: (_) => NotificationProvider(),
            ),
          ],
          child: ConnectivityAppWrapper(
            app: Builder(
              builder: (context) {
                return ScreenUtilInit(
                  designSize: Size(
                    // UIConstants.kDesignWidth,
                    // UIConstants.kDesignHeight,
                    // MediaQuery.of(context).size.width,
                    // MediaQuery.of(context).size.height,
                    414,
                    896,
                    // For 1080x2400px screen:
                    // 1080,
                    // 2400,
                  ),
                  minTextAdapt: true,
                  splitScreenMode: true,
                  ensureScreenSize: true,
                  enableScaleWH: () => true,
                  child: Builder(
                    builder: (context) {
                      return Obx(
                        () => 
                        GetMaterialApp(
                          title: AppName,
                          key: navigatorKey,
                          theme: Themes.light,
                          darkTheme: Themes.dark,
                          themeMode:
                              themeController.isDarkMode.value
                                  ? ThemeMode.dark
                                  : ThemeMode.light,
                          // locale: LocalizationService.locale,
                          // fallbackLocale: LocalizationService.fallbackLocale,
                          // translations: LocalizationService(),
                          home: SplashScreeen(),
                          //  home: DashboardScreen(),
                          //  home: FaceAuthenticationScreen(),
                          locale: _currentLocale,
                          fallbackLocale: LocalizationService.fallbackLocale,
                          translations: LocalizationService(),

                          //  home: UserHomeScreen(),
                          debugShowCheckedModeBanner: false,
                          //  home: CreateQuestionScreen(),
                          //  builder: Builde,
                          builder: EasyLoading.init(
                            builder: (context, child) {
                              return Stack(
                                children: [
                                  child!,

                                  // Custom LoadingDialog that appears over EasyLoading
                                  Consumer<LoadingProvider>(
                                    builder: (context, loadingProvider, child) {
                                      if (loadingProvider.isLoading) {
                                        return LoadingDialog(); // Show custom loader on top
                                      }
                                      return Container(); // Show nothing when not loading
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                     
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  ThemeData themeData(ThemeData theme) {
    return theme.copyWith();
  }
}
