import 'package:cached_network_image/cached_network_image.dart';
import 'package:deepinheart/Controller/Model/counselor_model.dart';
import 'package:deepinheart/Controller/Model/services_model.dart';
import 'package:deepinheart/Controller/Viewmodel/counselor_appointment_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/favorite_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/Controller/color_service.dart';
import 'package:deepinheart/Views/text_styles.dart';
import 'package:deepinheart/config/agora_config.dart';
import 'package:deepinheart/config/string_constants.dart';
import 'package:deepinheart/main.dart';
import 'package:deepinheart/screens/calls/chat_screen.dart';
import 'package:deepinheart/screens/calls/video_call_screen.dart';
import 'package:deepinheart/screens/calls/voice_call_screen.dart';
import 'package:deepinheart/screens/counselor/tabsview/consulation_tab_view.dart';
import 'package:deepinheart/screens/counselor/tabsview/profile_tab_view.dart';
import 'package:deepinheart/screens/counselor/tabsview/rating_tab_view.dart';
import 'package:deepinheart/screens/counselor/views/dialogs/confirmation_reservation_dialog.dart';
import 'package:deepinheart/screens/counselor/views/dialogs/message_alert_dialog.dart';
import 'package:deepinheart/screens/home/widget/advoisor_card.dart';
import 'package:deepinheart/screens/home/widget/sub_category_chip.dart';
import 'package:deepinheart/screens/mypage/coins/coin_charging_screen.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_button.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/rating_view.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:like_button/like_button.dart';
import 'package:provider/provider.dart';

class CounselorDetailScreen extends StatefulWidget {
  final CounselorData model;
  final int sectionId;
  CounselorDetailScreen({
    Key? key,
    required this.model,
    required this.sectionId,
  }) : super(key: key);

  @override
  _CounselorDetailScreenState createState() => _CounselorDetailScreenState();
}

class _CounselorDetailScreenState extends State<CounselorDetailScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<String> listTags = ["Profile".tr, "Reviews".tr, "Consultation".tr];

  late final GlobalKey<ConsulationTabViewState> consulationkEY;
  late final ScrollController _scrollController;

  ServiceModel? servicesData;
  bool isFavorite = false;
  bool isCheckingFavorite = false;
  bool _isAppBarExpanded = true;
  bool isTroat = false;

  @override
  void initState() {
    super.initState();
    consulationkEY = GlobalKey<ConsulationTabViewState>();
    _scrollController = ScrollController();
    _tabController = TabController(
      length: listTags.length,
      vsync: this,
      initialIndex: 0,
    );
    callApis();
    checkFavoriteStatus();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      final scrollOffset = _scrollController.offset;
      final appBarHeight = getAppBarHeight();
      final threshold = appBarHeight * 0.5; // 50% of app bar height

      // Add some hysteresis to prevent rapid toggling
      const hysteresis = 20.0;

      if (scrollOffset > (threshold + hysteresis) && _isAppBarExpanded) {
        setState(() {
          _isAppBarExpanded = false;
        });
        // Animate to collapsed state
        _animateToCollapsed();
      } else if (scrollOffset < (threshold - hysteresis) &&
          !_isAppBarExpanded) {
        setState(() {
          _isAppBarExpanded = true;
        });
        // Animate to expanded state
        _animateToExpanded();
      }
    });
  }

  void _animateToCollapsed() {
    if (_scrollController.hasClients) {
      final targetOffset = (getAppBarHeight()) - kToolbarHeight - 48;
      _scrollController.animateTo(
        targetOffset,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _animateToExpanded() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> callApis() async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    //  userViewModel.setLoading(true);
    servicesData = await userViewModel.fetchServicesData(
      sectionId: widget.sectionId,
      counsler_id: widget.model.id.toString(),
    );

    // Check if categories contain "Tarot" or "타로"
    if (servicesData != null && servicesData!.categories.isNotEmpty) {
      isTroat = servicesData!.categories.any((category) {
        final name = (category.nameTranslated ?? category.name).toLowerCase();
        return name.contains('tarot') || name.contains('타로');
      });
    }

    //userViewModel.setLoading(false);
    setState(() {});
  }

  Future<void> checkFavoriteStatus() async {
    final favoriteProvider = Provider.of<FavoriteProvider>(
      context,
      listen: false,
    );
    setState(() {
      isCheckingFavorite = true;
    });

    bool favoriteStatus = await favoriteProvider.checkIsFavorite(
      widget.model.id,
    );

    setState(() {
      isFavorite = favoriteStatus;
      isCheckingFavorite = false;
    });
  }

  Future<void> toggleFavorite() async {
    final favoriteProvider = Provider.of<FavoriteProvider>(
      context,
      listen: false,
    );

    setState(() {
      isFavorite = !isFavorite; // Optimistic update for smooth UX
    });

    bool success = await favoriteProvider.toggleFavorite(widget.model.id);

    if (!success) {
      // Revert the optimistic update if the API call failed
      setState(() {
        isFavorite = !isFavorite;
      });
    }
  }

  // Notify counselor of immediate consultation request
  Future<void> _notifyCounselorOfImmediateConsultation({
    required String channelName,
    required int counselorId,
    required String method,
  }) async {
    try {
      // TODO: Implement API call to notify counselor
      // This should:
      // 1. Send request to your backend
      // 2. Backend stores the consultation request with channel name
      // 3. Backend sends push notification to counselor with:
      //    - Channel name (most important!)
      //    - Client information
      //    - Consultation method
      //    - Timestamp

      // Example API call structure:
      /*
      final response = await apiService.createImmediateConsultation({
        'counselor_id': counselorId,
        'channel_name': channelName,
        'method': method,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      if (response.success) {
        print('Counselor notified successfully');
      }
      */

      print('📤 Notification sent to counselor:');
      print('   Channel: $channelName');
      print('   Counselor ID: $counselorId');
      print('   Method: $method');

      // For now, just log - implement actual API call later
    } catch (e) {
      print('❌ Error notifying counselor: $e');
      // Handle error - maybe show message to user
    }
  }

  // Show Personal Information Third-Party Provision dialog
  void _showPersonalInformationAgreement(
    BuildContext context,
    ConsulationTabViewState state,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    "Personal Information Third-Party Provision".tr,
                    style: textStyleRobotoRegular(
                      fontSize: FontConstants.font_16,
                      color: Colors.black,
                      weight: FontWeightConstants.bold,
                    ),
                  ),
                  UIHelper.verticalSpaceMd,

                  // Content
                  _buildInfoRow(
                    "Recipient".tr,
                    widget.model.nickName.isNotEmpty
                        ? widget.model.nickName
                        : widget.model.name,
                  ),
                  UIHelper.verticalSpaceSm,

                  _buildInfoRow(
                    "Purpose of Personal Information Use by Recipient".tr,
                    "E-commerce contract fulfillment and service provision, client management"
                        .tr,
                  ),
                  UIHelper.verticalSpaceSm,

                  _buildInfoRow(
                    "Personal Information Items Provided".tr,
                    "KI4968435490", // This should be dynamically generated
                  ),
                  UIHelper.verticalSpaceSm,

                  _buildInfoRow(
                    "Retention Period by Recipient".tr,
                    "Destroyed after the purpose of providing goods or services"
                        .tr,
                  ),
                  UIHelper.verticalSpaceMd,

                  // Notice text
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      "Members have the right to refuse consent to third-party provision of personal information, but service use may be restricted in this case. Other details follow the Terms of Service and Privacy Policy."
                          .tr,
                      style: textStyleRobotoRegular(
                        fontSize: FontConstants.font_12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  UIHelper.verticalSpaceMd,

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          () {
                            Get.back(); // Close agreement dialog
                          },
                          text: "Cancel".tr,
                          textcolor: Colors.white,
                          buttonBorderColor: Colors.transparent,
                          fsize: FontConstants.font_12,
                          weight: FontWeightConstants.medium,
                          color: grey600,
                        ),
                      ),
                      UIHelper.horizontalSpaceSm,
                      Expanded(
                        child: CustomButton(
                          () {
                            Get.back(); // Close agreement dialog
                            // Now show the consultation confirmation dialog
                            _showConsultationConfirmation(context, state);
                          },
                          text: "Agree".tr,
                          fsize: FontConstants.font_12,
                          weight: FontWeightConstants.medium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to build info rows
  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textStyleRobotoRegular(
            fontSize: FontConstants.font_13,
            color: Colors.grey.shade700,
            weight: FontWeightConstants.medium,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: textStyleRobotoRegular(
            fontSize: FontConstants.font_13,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // Show consultation confirmation dialog after agreement
  Future<void> _showConsultationConfirmation(
    BuildContext context,
    ConsulationTabViewState state,
  ) async {
    // Save the parent context and provider reference BEFORE showing dialog
    final parentContext = this.context;
    final appointmentProvider = Provider.of<CounselorAppointmentProvider>(
      parentContext,
      listen: false,
    );
    final userViewModel = Provider.of<UserViewModel>(
      parentContext,
      listen: false,
    );
    final user = userViewModel.userModel;

    await UIHelper.showDialogOk(
      context,
      title: 'Start Consultation'.tr,
      message:
          'Would you like to start an immediate consultation with Counselor'.tr
              .replaceAll(
                '%name%',
                widget.model.nickName.isNotEmpty
                    ? widget.model.nickName
                    : widget.model.name,
              ),
      onConfirm: () async {
        //to check if the user has enough coins

        if (user!.data.coins != null && user.data.coins! < 50) {
          //show alert dialog
          Get.back();
          await UIHelper.showDialogOk(
            parentContext,
            title: 'Insufficient Coins'.tr,
            message: 'You do not have enough coins to start a consultation'.tr,
            confirmText: 'Recharge Coins'.tr,
            onConfirm: () {
              Get.back();
              Get.to(() => CoinChargingScreen());
            },
          );

          return;
        }
        String counselorId = widget.model.id.toString();
        String serviceId = servicesData!.id.toString();
        String selectedMethod = state.getSelectedMethod() ?? '';
        print('counselorId: $counselorId');
        print('serviceId: $serviceId');
        print('selectedMethod: $selectedMethod');

        Get.back(); // Close confirmation dialog
        print('isTroat: $isTroat');
        print(
          "dob=>" + state.dobController.text + " " + state.timeController.text,
        );

        // Call consult-now API before starting the consultation
        final response = await appointmentProvider.startConsultNow(
          context: parentContext,
          counselorId: int.parse(counselorId),
          serviceId: int.parse(serviceId),
          selectedMethod: selectedMethod,
          isTroat: isTroat,
          dob: state.dobController.text + "," + state.timeController.text,
        );

        if (response != null && response['chanel_id'] != null) {
          // API call succeeded, proceed with consultation using the returned channel_id
          final appointmentId =
              response['id'] as int?; // Extract appointment ID
          _startImmediateConsultation(
            state,
            response['chanel_id'],
            appointmentId,
          );
        }
        // If failed, error message is already shown by the provider
      },
    );
  }

  // Start immediate consultation
  void _startImmediateConsultation(
    ConsulationTabViewState state,
    String channelName,
    int? appointmentId, // Add appointment ID parameter
  ) {
    // Get the selected consultation method
    if (state.selectedMethodIndex < 0 ||
        state.selectedMethodIndex >= state.options.length) {
      Get.snackbar(
        'Error'.tr,
        'Please select a consultation method'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final selectedMethodData = state.options[state.selectedMethodIndex];
    final selectedMethod = selectedMethodData['label'] as String;

    // Get counselor rate (coins can be int or double from backend)
    final coinsValue = selectedMethodData['coins'];
    final counselorRate = double.tryParse(coinsValue) ?? 50.0; // fallback

    // Use the channel name from API response
    // final timestamp = DateTime.now().millisecondsSinceEpoch;
    // final channelName = "immediate_${widget.model.id}_$timestamp";
    // Channel name is now passed from API response

    // Generate unique user ID for this client
    final userId = AgoraConfig.generateUserId();

    print('=== Immediate Consultation Details ===');
    print('Channel Name: $channelName');
    print('User ID: $userId');
    print('Counselor: ${widget.model.name}');
    print('Counselor ID: ${widget.model.id}');
    print('Method: $selectedMethod');
    print('Counselor Rate: $counselorRate coins/min');
    print('====================================');

    // CRITICAL: Send this channel name to the counselor
    // The counselor MUST receive and use this EXACT channel name
    // Options:
    // 1. API call to backend → backend sends push notification with channel name
    // 2. Real-time database (Firebase) → counselor listens for new requests
    // 3. WebSocket → instant notification with channel name

    // Example API call (you need to implement this):
    _notifyCounselorOfImmediateConsultation(
      channelName: channelName,
      counselorId: widget.model.id,
      method: selectedMethod,
    );

    // Navigate to appropriate call screen based on method
    if (selectedMethod.contains('Video') || selectedMethod.contains('비디오')) {
      Get.to(
        () => VideoCallScreen(
          counslername:
              widget.model.nickName.isNotEmpty
                  ? widget.model.nickName
                  : widget.model.name,
          channelName: channelName,
          userId: userId,
          counselorRate: counselorRate, // Pass the rate!
          appointmentId: appointmentId, // Pass appointment ID for coin updates
          counselorId:
              widget.model.id, // Pass counselor ID for complete-appointment API
          counselorImage:
              widget
                  .model
                  .profileImage, // Pass counselor image for rating dialog
          isCounsler: false,
          isTroat: isTroat,
        ),
      );
    } else if (selectedMethod.contains('Phone') ||
        selectedMethod.contains('Voice') ||
        selectedMethod.contains('음성') ||
        selectedMethod.contains('전화')) {
      Get.to(
        () => VoiceCallScreen(
          isCounselor: false,
          counslername:
              widget.model.nickName.isNotEmpty
                  ? widget.model.nickName
                  : widget.model.name,
          channelName: channelName,
          userId: userId,
          counselorRate: counselorRate, // Pass the rate!
          appointmentId: appointmentId, // Pass appointment ID for coin updates
          counselorId:
              widget.model.id, // Pass counselor ID for complete-appointment API
          counselorImage:
              widget
                  .model
                  .profileImage, // Pass counselor image for rating dialog
          isTroat: isTroat,
        ),
      );
    } else if (selectedMethod.contains('Chat') ||
        selectedMethod.contains('채팅') ||
        selectedMethod.contains('Text')) {
      // Navigate to Chat Screen
      Get.to(
        () => ChatScreen(
          counselorName:
              widget.model.nickName.isNotEmpty
                  ? widget.model.nickName
                  : widget.model.name,
          channelName: channelName,
          userId: userId,
          counselorRate: counselorRate,
          appointmentId: appointmentId,
          counselorId: widget.model.id,
          isCounselor: false,
          isTroat: isTroat,
        ),
      );
    } else {
      // Default to video call if method is unclear
      Get.to(
        () => VideoCallScreen(
          counslername:
              widget.model.nickName.isNotEmpty
                  ? widget.model.nickName
                  : widget.model.name,
          channelName: channelName,
          userId: userId,
          counselorRate: counselorRate, // Pass the rate!
          appointmentId: appointmentId, // Pass appointment ID for coin updates
          counselorId:
              widget.model.id, // Pass counselor ID for complete-appointment API
          counselorImage:
              widget
                  .model
                  .profileImage, // Pass counselor image for rating dialog
          isCounsler: false,
          isTroat: isTroat,
        ),
      );
    }
  }

  double getAppBarHeight() {
    return Get.height * 0.5; //0.6;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: "Counselor Profile".tr,
          isSemibold: true,
          weight: FontWeightConstants.bold,
          fontSize: FontConstants.font_21,
        ),
        centerTitle: true,
        //   backgroundColor: ,
        iconTheme: IconThemeData(color: Colors.black),
        //  actions: [IconButton(onPressed: () {}, icon: Icon(Icons.share))],
      ),
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: getAppBarHeight(),

              collapsedHeight: 0, // TabBar height
              toolbarHeight: 0.0,
              leadingWidth: 0,
              backgroundColor: isMainDark ? Color(0xff2C2C2E) : Colors.white,
              surfaceTintColor: isMainDark ? Color(0xff2C2C2E) : Colors.white,
              automaticallyImplyLeading: false,
              pinned: true,
              floating: false,
              snap: false,
              elevation: 0,
              shadowColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: headerWidget(context),
                collapseMode: CollapseMode.parallax,
                stretchModes: [
                  StretchMode.zoomBackground,
                  StretchMode.blurBackground,
                ],
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(48),
                child: Container(
                  color: isMainDark ? Color(0xff2C2C2E) : Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    automaticIndicatorColorAdjustment: false,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: primaryColor,
                    unselectedLabelColor:
                        isMainDark ? Colors.white : Color(0xff6B7280),
                    indicatorColor: primaryColor,
                    indicatorWeight: 2,
                    labelStyle: textStyleRobotoRegular(
                      weight: FontWeightConstants.medium,
                      fontSize: FontConstants.font_14,
                    ),
                    unselectedLabelStyle: textStyleRobotoRegular(
                      weight: FontWeightConstants.medium,
                      fontSize: FontConstants.font_14,
                    ),
                    tabs: [for (var tag in listTags) Tab(text: tag.tr)],
                  ),
                ),
              ),
            ),
         
          ];
        },
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: TabBarView(
            key: ValueKey('tab_bar_view_${widget.model.id}'),
            physics: NeverScrollableScrollPhysics(),
            children: [
              ProfileTabView(serviceModel: servicesData),
              RatingTabView(counselorId: widget.model.id),
              ConsulationTabView(
                key: consulationkEY,
                servicesData: servicesData,
                sectionId: widget.sectionId,
                counselorId: widget.model.id,
                counsler: widget.model,
              ),
            ],
            controller: _tabController,
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    () {
                      final state = consulationkEY.currentState;

                      if (state != null && state.selectedMethodIndex >= 0) {
                        // First show the personal information agreement dialog
                        _showPersonalInformationAgreement(context, state);
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return MessageAlertDialog(
                              title: 'Notice'.tr,
                              message: 'Please select a consultation method'.tr,
                            );
                          },
                        );
                      }
                    },
                    text: "Consult now".tr,
                    color: whiteColor,
                    textcolor: primaryColor,
                    fsize: FontConstants.font_14,
                    weight: FontWeightConstants.medium,
                    buttonBorderColor: primaryColor,
                  ),
                ),
                UIHelper.horizontalSpaceSm,
                Expanded(
                  child: CustomButton(
                    () {
                      final state = consulationkEY.currentState;

                      if (state == null || !state.canBook()) {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return MessageAlertDialog(
                              title: 'Notice'.tr,
                              message:
                                  '${'Please fill in all required fields:'.tr}\n'
                                  '- ${'Select a date'.tr}\n'
                                  '- ${'Select a time slot'.tr}\n'
                                  '- ${'Select a consultation method'.tr}',
                            );
                          },
                        );
                      } else {
                        // Get booking details
                        final selectedDay = state.selectedDay ?? DateTime.now();
                        final selectedSlot = state.selectedSlot ?? '';
                        final selectedMethod =
                            state.selectedMethodIndex >= 0
                                ? state.options[state
                                    .selectedMethodIndex]['label']
                                : '';
                        final selectedPackage =
                            state.selectedPackageId != null &&
                                    servicesData != null
                                ? servicesData!.packages
                                    .firstWhere(
                                      (pkg) =>
                                          pkg.id == state.selectedPackageId,
                                      orElse:
                                          () => servicesData!.packages.first,
                                    )
                                    .name
                                : null;

                        showDialog(
                          context: context,
                          builder: (context) {
                            return ConfirmationReservationDialog(
                              counselorName:
                                  widget.model.nickName.isNotEmpty
                                      ? widget.model.nickName
                                      : widget.model.name,
                              date:
                                  "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}",
                              time: selectedSlot,
                              method: selectedMethod,
                              packageName: selectedPackage,
                              onConfirm: () async {
                                return await state.storeAppointment(isTroat);
                              },
                            );
                          },
                        );
                      }
                    },
                    fsize: FontConstants.font_14,
                    weight: FontWeightConstants.medium,
                    text: "Book appointment".tr,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget headerWidget(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: Get.width,
          height: constraints.maxHeight,
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: _isAppBarExpanded ? 3 : 1,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      _isAppBarExpanded ? 12 : 6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          _isAppBarExpanded ? 0.1 : 0.05,
                        ),
                        blurRadius: _isAppBarExpanded ? 8 : 4,
                        offset: Offset(0, _isAppBarExpanded ? 4 : 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      _isAppBarExpanded ? 12 : 6,
                    ),
                    child: CachedNetworkImage(
                      imageUrl: widget.model.profileImage,
                      fit: BoxFit.cover,
                      width: Get.width,
                      errorWidget:
                          (context, url, error) => CachedNetworkImage(
                            imageUrl: testuserprofile,
                            fit: BoxFit.cover,
                            width: Get.width,
                          ),
                    ),
                  ),
                ),
              ),
              if (_isAppBarExpanded) UIHelper.verticalSpaceSm,
              AnimatedOpacity(
                duration: Duration(milliseconds: 300),
                opacity: _isAppBarExpanded ? 1.0 : 0.0,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: _isAppBarExpanded ? null : 0,
                  child: Row(
                    children: [
                      SizedBox(width: 30),
                      Expanded(
                        child: CustomText(
                          text:
                              widget.model.nickName.isNotEmpty
                                  ? widget.model.nickName
                                  : widget.model.name,
                          align: TextAlign.center,
                          fontSize: FontConstants.font_21,
                          weight: FontWeightConstants.bold,
                        ),
                      ),
                      Consumer<FavoriteProvider>(
                        builder: (context, favoriteProvider, child) {
                          return AnimatedSwitcher(
                            duration: Duration(milliseconds: 300),
                            child:
                                isCheckingFavorite
                                    ? SizedBox(
                                      key: ValueKey('loading'),
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              primaryColor,
                                            ),
                                      ),
                                    )
                                    : LikeButton(
                                      key: ValueKey('like_button'),
                                      isLiked: isFavorite,
                                      onTap: (isLiked) async {
                                        await toggleFavorite();
                                        return !isLiked; // Return the new state
                                      },
                                      likeBuilder:
                                          (isLiked) => AnimatedContainer(
                                            duration: Duration(
                                              milliseconds: 200,
                                            ),
                                            child: Icon(
                                              isLiked
                                                  ? FontAwesomeIcons.solidHeart
                                                  : FontAwesomeIcons.heart,
                                              color:
                                                  isLiked
                                                      ? Colors.red
                                                      : primaryColor,
                                              size: isLiked ? 24.h : 24.h,
                                            ),
                                          ),
                                      animationDuration: Duration(
                                        milliseconds: 600,
                                      ),
                                      size: 30,
                                      circleColor: CircleColor(
                                        start: Color(0xff00ddff),
                                        end: Color(0xff0099cc),
                                      ),
                                      bubblesColor: BubblesColor(
                                        dotPrimaryColor: Color(0xff33b5e5),
                                        dotSecondaryColor: Color(0xff0099cc),
                                      ),
                                      likeCount: null,
                                      countBuilder: (
                                        int? count,
                                        bool isLiked,
                                        String text,
                                      ) {
                                        return null;
                                      },
                                    ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              UIHelper.verticalSpaceSm,
              Visibility(
                visible: false,
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 300),
                  opacity: _isAppBarExpanded ? 1.0 : 0.0,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: _isAppBarExpanded ? null : 0,
                    child:
                        servicesData != null
                            ? Builder(
                              builder: (context) {
                                // Collect all items first
                                final List<Widget> allItems = [
                                  // Add categories first
                                  ...servicesData!.categories
                                      .map(
                                        (category) => SubCategoryChip(
                                          text:
                                              category.nameTranslated ??
                                              category.name,
                                          color: ColorService.getColor(
                                            servicesData!.categories.indexOf(
                                              category,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),

                                  // Add taxonomies items
                                  ...servicesData!.taxonomies
                                      .expand(
                                        (e) =>
                                            e.items
                                                .map(
                                                  (e1) => SubCategoryChip(
                                                    text:
                                                        e1.nameTranslated ??
                                                        e1.name,
                                                    //index vise fetch color from ColorService by index of e
                                                    color:
                                                        ColorService.getColor(
                                                          e.items.indexOf(e1),
                                                        ),
                                                  ),
                                                )
                                                .toList(),
                                      )
                                      .toList(),
                                ];

                                // Split items into 2 rows
                                final int totalItems = allItems.length;
                                final int itemsPerRow = (totalItems / 2).ceil();
                                final List<Widget> row1 =
                                    allItems.take(itemsPerRow).toList();
                                final List<Widget> row2 =
                                    allItems.skip(itemsPerRow).toList();

                                return ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: 70.h, // 2 lines height
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        // First row
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children:
                                              row1
                                                  .map(
                                                    (item) => Padding(
                                                      padding: EdgeInsets.only(
                                                        right: 5.r,
                                                        bottom: 5.r,
                                                      ),
                                                      child: item,
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                        // Second row
                                        if (row2.isNotEmpty)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children:
                                                row2
                                                    .map(
                                                      (item) => Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              right: 5.r,
                                                            ),
                                                        child: item,
                                                      ),
                                                    )
                                                    .toList(),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                            : Container(),
                  ),
                ),
              ),

              if (_isAppBarExpanded) UIHelper.verticalSpaceSm,
              AnimatedOpacity(
                duration: Duration(milliseconds: 300),
                opacity: _isAppBarExpanded ? 1.0 : 0.0,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: _isAppBarExpanded ? null : 0,
                  child: SizedBox(
                    width: Get.width * 0.7,
                    child: CustomText(
                      text: widget.model.introduction,
                      align: TextAlign.center,
                      fontSize: FontConstants.font_13,
                      color: isMainDark ? Colors.white : Color(0xff4B5563),
                    ),
                  ),
                ),
              ),
              if (_isAppBarExpanded) UIHelper.verticalSpaceSm,
              AnimatedOpacity(
                duration: Duration(milliseconds: 300),
                opacity: _isAppBarExpanded ? 1.0 : 0.0,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: _isAppBarExpanded ? null : 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MyRatingView(
                        text:
                            widget.model.rating.toString() +
                            " (${widget.model.ratingCount ?? 0})",
                        initialRating: 4.9,
                        fsize: FontConstants.font_14,
                        itemSize: 20.0,
                        startQuantity: 1,

                        isAllowRating: false,
                        onRatingUpdate: (value) {},
                      ),
                      //  Spacer(),
                      UIHelper.horizontalSpaceSm,
                      SubCategoryChip(
                        height: 30.0.h,
                        text: getAvailabilityText(widget.model),
                        color: getAvailabilityColor(
                          widget.model,
                        ), // Gray for Offline
                        isHaveCircle: true,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isAppBarExpanded) UIHelper.verticalSpaceL,
            ],
          ),
        );
      },
    );
  }
}
