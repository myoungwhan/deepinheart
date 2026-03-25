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

bool get isMainDark {
  try {
    final themeController = Get.find<ThemeController>();
    return themeController.isDarkMode.value;
  } catch (e) {
    return false;
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  setupFlutterNotifications();
}

Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) return;
  
  channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
    showBadge: true,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true, badge: true, sound: true,
  );
  
  isFlutterLocalNotificationsInitialized = true;
  const initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('app_icon'),
    iOS: DarwinInitializationSettings(),
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: handleDataOnMessage,
  );
}

Future handleDataOnMessage(NotificationResponse message) async {
  try {
    Map<String, dynamic> data = jsonDecode(message.payload.toString());
    if (data['type'] == 'emergency_notice' && data['announcement_id'] != null) {
      if (navigatorKey.currentContext != null) {
        final settingProvider = Provider.of<SettingProvider>(navigatorKey.currentContext!, listen: false);
        final announcements = settingProvider.activeEmergencyAnnouncements;
        final announcementId = int.tryParse(data['announcement_id'].toString());
        if (announcementId != null && announcements.isNotEmpty) {
          final announcement = announcements.firstWhere((a) => a.id == announcementId, orElse: () => announcements.first);
          EmergencyNoticeDialog.show(navigatorKey.currentContext!, announcement: announcement);
        }
      }
    }
  } catch (e) {
    print("Error handling notification: $e");
  }
}

Future showFlutterNotification(RemoteMessage message) async {
  RemoteNotification? notification = message.notification;
  if (notification != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(channel.id, channel.name, channelDescription: channel.description, icon: "app_icon"),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }
}

bool isFlutterLocalNotificationsInitialized = false;
late AndroidNotificationChannel channel;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  Stripe.publishableKey = PaymentConfig.stripePublishableKey;
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  setupFlutterNotifications();

  try {
    await translationService.initialize();
    await translationService.downloadModel();
  } catch (e) {
    debugPrint('Translation init failed: $e');
  }

  initializeDateFormatting().then((_) => runApp(MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _currentLocale = LocalizationService.locale;

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
    FirebaseMessaging.onMessage.listen(showFlutterNotification);
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('saved_language_code');
    if (lang != null) {
      setState(() => _currentLocale = Locale(lang));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.put(ThemeController());
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoadingProvider()),
        ChangeNotifierProvider(create: (_) => UserViewModel()..calStarterApiWihoutToken()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => BookingViewmodel()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => CounselorAppointmentProvider()),
        ChangeNotifierProvider(create: (_) => SettingProvider(context)),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(414, 896),
        child: Obx(() => GetMaterialApp(
          navigatorKey: navigatorKey, // CRITICAL FIX
          title: "DeepInHeart",
          theme: Themes.light,
          darkTheme: Themes.dark,
          themeMode: themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreeen(),
          locale: _currentLocale,
          translations: LocalizationService(),
          builder: EasyLoading.init(builder: (context, child) {
            return Stack(
              children: [
                child!,
                Consumer<LoadingProvider>(builder: (context, lp, _) {
                  return lp.isLoading ? const LoadingDialog() : const SizedBox.shrink();
                }),
              ],
            );
          }),
        )),
      ),
    );
  }
}
