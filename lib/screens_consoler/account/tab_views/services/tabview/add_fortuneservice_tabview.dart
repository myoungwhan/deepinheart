import 'package:auto_size_text/auto_size_text.dart';
import 'package:deepinheart/Controller/Model/hashtag_model.dart';
import 'package:deepinheart/Controller/Model/services_model.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_button.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/custom_textfiled.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/text_styles.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/Controller/Viewmodel/setting_provider.dart';
import 'package:deepinheart/Controller/Model/time_slots_model.dart';
import 'package:deepinheart/Controller/sharedpref.dart';
import 'package:quill_html_editor_v3/quill_html_editor_v3.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:deepinheart/config/api_endpoints.dart';

class AddFortuneserviceTabview extends StatefulWidget {
  final bool isFrotune;
  const AddFortuneserviceTabview({Key? key, this.isFrotune = true})
    : super(key: key);

  @override
  _AddFortuneserviceTabviewState createState() =>
      _AddFortuneserviceTabviewState();
}

class _AddFortuneserviceTabviewState extends State<AddFortuneserviceTabview> {
  final _formKey = GlobalKey<FormState>();
  final _specialtiesController = TextEditingController();
  final _experienceController = TextEditingController();
  final _certificateController = TextEditingController();
  final _educationController = TextEditingController();
  final _trainingController = TextEditingController();
  final _hashtagController = TextEditingController();
  final _packageNameController = TextEditingController();
  final _packageDurationController = TextEditingController();
  final _packageSessionController = TextEditingController();
  final _packageCoinsController = TextEditingController();
  final _packageDiscountController = TextEditingController();
  final _voiceCallCoinController = TextEditingController();
  final _videoCallCoinController = TextEditingController();
  final _chatCoinController = TextEditingController();
  final _temporaryHolidayController = TextEditingController();

  // Form state variables
  int? selectedSectionId = 1; // Default to Fortune
  List<int> selectedCategoryIds = [];
  List<int> selectedTaxonomieItemIds = [];
  List<int> selectedHashtagIds = [];
  List<HashTagData> selectedHashtags = [];
  List<int> removedPreloadedHashtagIds = [];
  List<HashTagData> fetchedHashtags =
      []; // Hashtags fetched from API based on selected categories
  Set<int> selectedHashtagIdsSet = {}; // Track which hashtags are selected
  List<String> selectedTopics = [];
  bool timeInputEnabled = false;
  bool voiceCallAvailable = false;
  bool videoCallAvailable = false;
  bool chatAvailable = false;
  int voiceCallCoin = 0;
  int videoCallCoin = 0;
  int chatCoin = 0;
  bool taxInvoiceAvailable = false;
  int minBookingTime = 30;
  int maxBookingPeriod = 7;
  String bookingConfirmation = 'auto';
  List<String> selectedDays = [];
  Map<String, List<int>> selectedTimeSlotsByDay = {};
  String? activeDay;
  List<String> regularHolidays = [];
  List<String> temporaryHolidays = [];
  List<Map<String, dynamic>> packages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _specialtiesController.dispose();
    _experienceController.dispose();
    _certificateController.dispose();
    _educationController.dispose();
    _trainingController.dispose();
    _hashtagController.dispose();
    _packageNameController.dispose();
    _packageDurationController.dispose();
    _packageSessionController.dispose();
    _packageCoinsController.dispose();
    _packageDiscountController.dispose();
    _voiceCallCoinController.dispose();
    _videoCallCoinController.dispose();
    _chatCoinController.dispose();
    _temporaryHolidayController.dispose();
    super.dispose();
  }

  // Save draft to SharedPreferences
  Future<void> _saveDraft() async {
    try {
      final SharedPref sharedPref = SharedPref();
      final draftData = {
        // Text controllers
        'specialties': _specialtiesController.text,
        'experience': _experienceController.text,
        'certificate': _certificateController.text,
        'education': _educationController.text,
        'training': _trainingController.text,
        'hashtag': _hashtagController.text,
        'packageName': _packageNameController.text,
        'packageDuration': _packageDurationController.text,
        'packageSession': _packageSessionController.text,
        'packageCoins': _packageCoinsController.text,
        'packageDiscount': _packageDiscountController.text,
        'voiceCallCoin': _voiceCallCoinController.text,
        'videoCallCoin': _videoCallCoinController.text,
        'chatCoin': _chatCoinController.text,
        'temporaryHoliday': _temporaryHolidayController.text,

        // Form state variables
        'selectedSectionId': selectedSectionId,
        'selectedCategoryIds': selectedCategoryIds,
        'selectedTaxonomieItemIds': selectedTaxonomieItemIds,
        'selectedHashtagIds': selectedHashtagIdsSet.toList(),
        'removedPreloadedHashtagIds': removedPreloadedHashtagIds,
        'selectedTopics': selectedTopics,
        'timeInputEnabled': timeInputEnabled,
        'voiceCallAvailable': voiceCallAvailable,
        'videoCallAvailable': videoCallAvailable,
        'chatAvailable': chatAvailable,
        'voiceCallCoinValue': voiceCallCoin,
        'videoCallCoinValue': videoCallCoin,
        'chatCoinValue': chatCoin,
        'taxInvoiceAvailable': taxInvoiceAvailable,
        'minBookingTime': minBookingTime,
        'maxBookingPeriod': maxBookingPeriod,
        'bookingConfirmation': bookingConfirmation,
        'selectedDays': selectedDays,
        'selectedTimeSlotsByDay': selectedTimeSlotsByDay.map(
          (key, value) => MapEntry(key, value),
        ),
        'activeDay': activeDay,
        'regularHolidays': regularHolidays,
        'temporaryHolidays': temporaryHolidays,
        'packages': packages,
        'isFrotune': widget.isFrotune,
      };

      await sharedPref.saveObject(
        'service_draft_${widget.isFrotune ? 'fortune' : 'counseling'}',
        draftData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Draft saved successfully'.tr),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving draft: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving draft'.tr),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Load draft from SharedPreferences
  Future<void> _loadDraft() async {
    try {
      final SharedPref sharedPref = SharedPref();
      final draftData = await sharedPref.readObject(
        'service_draft_${widget.isFrotune ? 'fortune' : 'counseling'}',
      );

      if (draftData != null) {
        // Load text controllers
        _specialtiesController.text = draftData['specialties'] ?? '';
        _experienceController.text = draftData['experience'] ?? '';
        _certificateController.text = draftData['certificate'] ?? '';
        _educationController.text = draftData['education'] ?? '';
        _trainingController.text = draftData['training'] ?? '';
        _hashtagController.text = draftData['hashtag'] ?? '';
        _packageNameController.text = draftData['packageName'] ?? '';
        _packageDurationController.text = draftData['packageDuration'] ?? '';
        _packageSessionController.text = draftData['packageSession'] ?? '';
        _packageCoinsController.text = draftData['packageCoins'] ?? '';
        _packageDiscountController.text = draftData['packageDiscount'] ?? '';
        _voiceCallCoinController.text = draftData['voiceCallCoin'] ?? '';
        _videoCallCoinController.text = draftData['videoCallCoin'] ?? '';
        _chatCoinController.text = draftData['chatCoin'] ?? '';
        _temporaryHolidayController.text = draftData['temporaryHoliday'] ?? '';

        // Load form state variables
        selectedSectionId = draftData['selectedSectionId'];
        selectedCategoryIds = List<int>.from(
          draftData['selectedCategoryIds'] ?? [],
        );
        selectedTaxonomieItemIds = List<int>.from(
          draftData['selectedTaxonomieItemIds'] ?? [],
        );
        selectedHashtagIds = List<int>.from(
          draftData['selectedHashtagIds'] ?? [],
        );
        selectedHashtagIdsSet = Set<int>.from(
          draftData['selectedHashtagIds'] ?? [],
        );
        removedPreloadedHashtagIds = List<int>.from(
          draftData['removedPreloadedHashtagIds'] ?? [],
        );
        selectedTopics = List<String>.from(draftData['selectedTopics'] ?? []);
        timeInputEnabled = draftData['timeInputEnabled'] ?? false;
        voiceCallAvailable = draftData['voiceCallAvailable'] ?? false;
        videoCallAvailable = draftData['videoCallAvailable'] ?? false;
        chatAvailable = draftData['chatAvailable'] ?? false;
        voiceCallCoin = draftData['voiceCallCoinValue'] ?? 0;
        videoCallCoin = draftData['videoCallCoinValue'] ?? 0;
        chatCoin = draftData['chatCoinValue'] ?? 0;
        taxInvoiceAvailable = draftData['taxInvoiceAvailable'] ?? false;
        minBookingTime = draftData['minBookingTime'] ?? 30;
        maxBookingPeriod = draftData['maxBookingPeriod'] ?? 7;
        bookingConfirmation = draftData['bookingConfirmation'] ?? 'auto';
        selectedDays = List<String>.from(draftData['selectedDays'] ?? []);
        activeDay = draftData['activeDay'];
        regularHolidays = List<String>.from(draftData['regularHolidays'] ?? []);
        temporaryHolidays = List<String>.from(
          draftData['temporaryHolidays'] ?? [],
        );
        packages = List<Map<String, dynamic>>.from(draftData['packages'] ?? []);

        // Load selectedTimeSlotsByDay
        if (draftData['selectedTimeSlotsByDay'] != null) {
          selectedTimeSlotsByDay = Map<String, List<int>>.from(
            (draftData['selectedTimeSlotsByDay'] as Map).map(
              (key, value) =>
                  MapEntry(key.toString(), List<int>.from(value ?? [])),
            ),
          );
        }

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Error loading draft: $e');
    }
  }

  Future<void> _clearDraft() async {
    try {
      final SharedPref sharedPref = SharedPref();
      await sharedPref.removeObject(
        'service_draft_${widget.isFrotune ? 'fortune' : 'counseling'}',
      );
      debugPrint('Draft cleared successfully');
    } catch (e) {
      debugPrint('Error clearing draft: $e');
    }
  }

  void _loadData() async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    userViewModel.setLoading(true);
    // await userViewModel.fetchTimeSlots();

    // Load draft data first if available
    await _loadDraft();

    // await userViewModel.calStarterApiWihoutToken();
    if (widget.isFrotune) {
      selectedSectionId =
          userViewModel.texnomyData != null
              ? userViewModel.texnomyData!.fortune.id
              : selectedSectionId;
    } else {
      selectedSectionId =
          userViewModel.texnomyData != null
              ? userViewModel.texnomyData!.counseling.id
              : selectedSectionId;
    }
    ServiceModel? servicesData = await userViewModel.fetchServicesData(
      sectionId: selectedSectionId!,
    );
    await initializeData(servicesData);
    setState(() {});
    userViewModel.setLoading(false);
  }

  Future<void> initializeData(ServiceModel? servicesData) async {
    if (servicesData != null) {
      // Populate categories
      selectedCategoryIds =
          servicesData.categories.map((cat) => cat.id).toList();
      print('****sselectedCategoryIds: $selectedCategoryIds');

      // Populate taxonomies
      selectedTaxonomieItemIds = [];
      for (var taxonomy in servicesData.taxonomies) {
        for (var item in taxonomy.items) {
          selectedTaxonomieItemIds.add(item.id);
        }
      }
      print(
        "selectedTaxonomieItemIds" + selectedTaxonomieItemIds.length.toString(),
      );

      // Mark hashtags from counselor service as selected
      selectedHashtagIdsSet.clear();
      for (var hashtag in servicesData.hashTags) {
        selectedHashtagIdsSet.add(hashtag.id);
        if (hashtag.explanation == "User added hashtag") {
          selectedHashtags.add(hashtag);
        }
      }
      print('****selectedHashtagIdsSet: $selectedHashtagIdsSet');

      // Fetch hashtags from API based on selected categories
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      if (selectedCategoryIds.isNotEmpty) {
        await _fetchHashtagsFromApi(userViewModel);
      } else {
        fetchedHashtags.clear();
      }

      // Populate specialties
      _specialtiesController.text = servicesData.specialities
          .map((s) => s.name)
          .join(', ');

      // Populate profile information
      _experienceController.text = servicesData.profileInformation.experience;
      _certificateController.text =
          servicesData.profileInformation.certificate ?? '';
      _educationController.text =
          servicesData.profileInformation.education ?? '';
      _trainingController.text = servicesData.profileInformation.training ?? '';

      // Populate time input
      timeInputEnabled = servicesData.timeInput == 1;

      // Populate consultation method
      final consultationMethod = servicesData.counsultationMethod;
      voiceCallAvailable = consultationMethod.voiceCallAvailable == 1;
      videoCallAvailable = consultationMethod.videoCallAvailable == 1;
      chatAvailable = consultationMethod.chatAvailable == 1;
      taxInvoiceAvailable = consultationMethod.taxInvoiceAvailable == 1;

      // Populate coin values
      voiceCallCoin =
          (double.tryParse(consultationMethod.voiceCallCoin.toString()) ?? 0.0)
              .toInt();
      videoCallCoin =
          (double.tryParse(consultationMethod.videoCallCoin.toString()) ?? 0.0)
              .toInt();
      chatCoin =
          (double.tryParse(consultationMethod.chatCoin.toString()) ?? 0.0)
              .toInt();
      print(
        "voiceCallCoin=>" +
            voiceCallCoin.toString() +
            "****" +
            consultationMethod.voiceCallCoin.toString(),
      );

      // Update controllers
      _voiceCallCoinController.text =
          voiceCallCoin > 0 ? voiceCallCoin.toString() : '';
      _videoCallCoinController.text =
          videoCallCoin > 0 ? videoCallCoin.toString() : '';
      _chatCoinController.text = chatCoin > 0 ? chatCoin.toString() : '';

      // Populate availability - convert lowercase day names to proper format
      selectedDays =
          servicesData.avialability
              .map((avail) => _convertDayName(avail.day))
              .toList();

      if (selectedDays.isNotEmpty) {
        activeDay = selectedDays.first;
      }

      selectedTimeSlotsByDay = {};
      for (var availability in servicesData.avialability) {
        String dayName = _convertDayName(availability.day);
        List<int> daySlots = [];
        for (var slot in availability.slots) {
          if (slot.isAvailable) {
            daySlots.add(slot.slot.id);
          }
        }
        selectedTimeSlotsByDay[dayName] = daySlots;
      }
      //holidays
      temporaryHolidays = servicesData.holidays.holidayTemporary;
      regularHolidays = servicesData.holidays.holidayRegular;

      // Populate reservation settings
      final reservation = servicesData.reservation;
      minBookingTime = reservation.minBookingTime;
      maxBookingPeriod = reservation.maxBookingPeriod;
      bookingConfirmation = reservation.bookingConfirmation;

      // Populate packages
      packages =
          servicesData.packages
              .map(
                (package) => {
                  'id': package.id,
                  'name': package.name,
                  'discount_rate': package.discountRate,
                  'duration': package.duration,
                  'session': package.session,
                  'coins': package.coins,
                  'original_price': package.coins,
                  'new_price':
                      (package.coins *
                              (100 - double.parse(package.discountRate)) /
                              100)
                          .round(),
                  'description':
                      '${package.duration}${'-minute consultation x'.tr}${package.session} ${'session'.tr}',
                },
              )
              .toList();
    } else {
      print('Services data is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<UserViewModel>(
        builder: (context, userViewModel, child) {
          // Show loading indicator if data is not ready
          if (userViewModel.texnomyData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategorySection(userViewModel),
                  const SizedBox(height: 20),

                  // Use ListView.builder for better performance with many taxonomies
                  ...(widget.isFrotune
                          ? userViewModel.texnomyData!.fortune.taxonomies
                          : userViewModel.texnomyData!.counseling.taxonomies)
                      .expand(
                        (taxonomy) => [
                          _buildTaxonomySection(taxonomy),
                          const SizedBox(height: 20),
                        ],
                      )
                      .toList(),

                  const SizedBox(height: 20),

                  _buildHashtagsSection(userViewModel),
                  const SizedBox(height: 20),

                  _buildSpecialtiesSection(),
                  const SizedBox(height: 20),

                  _buildProfileInformationSection(),
                  const SizedBox(height: 20),

                  _buildBirthDateTimeSection(),
                  const SizedBox(height: 20),

                  _buildConsultationSettingsSection(),
                  const SizedBox(height: 20),

                  _buildAvailableDaysTimesSection(userViewModel),
                  const SizedBox(height: 20),

                  _buildReservationSettingsSection(),
                  const SizedBox(height: 20),

                  _buildHolidaySettingsSection(),
                  const SizedBox(height: 20),

                  _buildConsultationPackagesSection(),
                  const SizedBox(height: 40),

                  _buildActionButtons(),
                ],
              ),
            ),
          );
        },
        // Add child parameter to prevent unnecessary rebuilds
        child: const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    bool isRequired = false,
    bool isOptional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            text: title,
            fontSize: FontConstants.font_18,
            weight: FontWeightConstants.semiBold,
          ),
          if (isRequired)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: CustomText(
                text: 'Required'.tr,
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          if (isOptional)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(4),
              ),
              child: CustomText(
                text: 'Optional'.tr,
                color: Colors.white,
                fontSize: 10,
                weight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(UserViewModel userViewModel) {
    if (userViewModel.texnomyData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final fortuneCategories =
        widget.isFrotune
            ? userViewModel.texnomyData!.fortune.categories
            : userViewModel.texnomyData!.counseling.categories;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor),
        ),

        shadows: [boxShadow()],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Category'.tr, isRequired: true),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.isFrotune ? 3 : 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: widget.isFrotune ? 2.5 : 2.8,
            ),
            itemCount: fortuneCategories.length,
            // Add cacheExtent for better performance
            cacheExtent: 200,
            itemBuilder: (context, index) {
              final category = fortuneCategories[index];
              final isSelected = selectedCategoryIds.contains(category.id);
              return _CategoryItem(
                category: category,
                isSelected: isSelected,
                onTap: () async {
                  setState(() {
                    if (isSelected) {
                      selectedCategoryIds.remove(category.id);
                    } else {
                      selectedCategoryIds.add(category.id);
                    }
                  });
                  // Fetch hashtags when categories change
                  final userViewModel = Provider.of<UserViewModel>(
                    context,
                    listen: false,
                  );
                  await _fetchHashtagsFromApi(userViewModel);
                  setState(() {}); // Refresh UI
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaxonomySection(dynamic taxonomy) {
    final taxonomyItems = taxonomy.taxonomieItems;
    final allItemsSelected = taxonomyItems.every(
      (item) => selectedTaxonomieItemIds.contains(item.id),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: taxonomy.name,
            fontSize: FontConstants.font_18,
            weight: FontWeightConstants.semiBold,
          ),
          const SizedBox(height: 16),

          // Select All option
          Container(
            height: 45.h,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (allItemsSelected) {
                    // Deselect all items in this taxonomy
                    for (final item in taxonomyItems) {
                      selectedTaxonomieItemIds.remove(item.id);
                    }
                  } else {
                    // Select all items in this taxonomy
                    for (final item in taxonomyItems) {
                      if (!selectedTaxonomieItemIds.contains(item.id)) {
                        selectedTaxonomieItemIds.add(item.id);
                      }
                    }
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                child: Row(
                  children: [
                    Checkbox(
                      value: allItemsSelected,
                      activeColor: primaryColorConsulor,
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            // Select all items in this taxonomy
                            for (final item in taxonomyItems) {
                              if (!selectedTaxonomieItemIds.contains(item.id)) {
                                selectedTaxonomieItemIds.add(item.id);
                              }
                            }
                          } else {
                            // Deselect all items in this taxonomy
                            for (final item in taxonomyItems) {
                              selectedTaxonomieItemIds.remove(item.id);
                            }
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: CustomText(
                        text: 'Select All'.tr,
                        fontSize: 14,
                        color: Colors.black,
                        weight: FontWeightConstants.regular,
                        maxlines: 1,
                        align: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Grid of taxonomy items
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.isFrotune ? 2 : 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: widget.isFrotune ? 4.0 : 8,
            ),
            itemCount: taxonomyItems.length,
            cacheExtent: 200,
            itemBuilder: (context, index) {
              final item = taxonomyItems[index];
              final isSelected = selectedTaxonomieItemIds.contains(item.id);
              return _TaxonomyItem(
                item: item,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedTaxonomieItemIds.remove(item.id);
                    } else {
                      selectedTaxonomieItemIds.add(item.id);
                    }
                  });
                },
                onCheckboxChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedTaxonomieItemIds.add(item.id);
                    } else {
                      selectedTaxonomieItemIds.remove(item.id);
                    }
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // Fetch hashtags from API based on selected category IDs
  Future<void> _fetchHashtagsFromApi(UserViewModel userViewModel) async {
    print('selectedCategoryIds: $selectedCategoryIds');
    if (selectedCategoryIds.isEmpty) {
      fetchedHashtags.clear();
      return;
    }

    try {
      final token = userViewModel.userModel?.data.token;
      if (token == null || token.isEmpty) {
        print('No token available for fetching hashtags');
        return;
      }

      var headers = {'Authorization': 'Bearer $token'};

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiEndPoints.BASE_URL}hashtags'),
      );

      // Add category_ids as array fields
      for (int i = 0; i < selectedCategoryIds.length; i++) {
        request.fields['category_ids[$i]'] = selectedCategoryIds[i].toString();
      }

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var jsonData = jsonDecode(responseBody);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          setState(() {
            fetchedHashtags =
                (jsonData['data'] as List)
                    .map((item) => HashTagData.fromJson(item))
                    .toList();
          });
          print('Fetched ${fetchedHashtags.length} hashtags from API');
        } else {
          setState(() {
            fetchedHashtags.clear();
          });
        }
      } else {
        print('Failed to fetch hashtags: ${response.statusCode}');
        print('Response: ${response.reasonPhrase}');
        setState(() {
          fetchedHashtags.clear();
        });
      }
    } catch (e) {
      print('Error fetching hashtags: $e');
      setState(() {
        fetchedHashtags.clear();
      });
    }
  }

  // Delete package from API in background
  Future<void> _deletePackageFromApi(int packageId) async {
    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;
      if (token == null || token.isEmpty) {
        print('No token available for deleting package');
        return;
      }

      var headers = {'Authorization': 'Bearer $token'};
      var request = http.Request(
        'DELETE',
        Uri.parse('${ApiEndPoints.BASE_URL}packages/$packageId'),
      );
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        print('Package deleted successfully: $responseBody');
      } else {
        print('Failed to delete package: ${response.statusCode}');
        print('Response: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error deleting package: $e');
    }
  }

  Widget _buildHashtagsSection(UserViewModel userViewModel) {
    if (userViewModel.texnomyData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Use fetched hashtags from API based on selected categories, plus user-added hashtags
    final allHashtags = [...fetchedHashtags, ...selectedHashtags];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor),
        ),
        shadows: [boxShadow()],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Popular Keywords (Hashtags)'.tr),

          // Display hashtags as selectable/deselectable chips
          if (allHashtags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  allHashtags.map((hashtag) {
                    final isSelected = selectedHashtagIdsSet.contains(
                      hashtag.id,
                    );

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedHashtagIdsSet.remove(hashtag.id);
                          } else {
                            selectedHashtagIdsSet.add(hashtag.id);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? (widget.isFrotune
                                      ? primaryColorConsulor
                                      : Color(0xff7E22CE))
                                  : whiteColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                isSelected
                                    ? (widget.isFrotune
                                        ? primaryColorConsulor
                                        : Color(0xff7E22CE))
                                    : Colors.grey[400]!,
                            width: 1,
                          ),
                        ),
                        child: CustomText(
                          text: hashtag.name,
                          color: isSelected ? Colors.white : Colors.black,
                          fontSize: FontConstants.font_12,
                          weight: FontWeightConstants.medium,
                        ),
                      ),
                    );
                  }).toList(),
            ),

            const SizedBox(height: 16),
          ],

          // Add custom hashtag section
          Builder(
            builder: (context) {
              // form key
              final formKey = GlobalKey<FormState>();
              return Form(
                key: formKey,
                child: Row(
                  children: [
                    Expanded(
                      child: Customtextfield(
                        required: true,
                        controller: _hashtagController,
                        hint: 'Enter hashtag'.tr,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Hashtag is required".tr;
                          }
                          if (selectedCategoryIds.isEmpty) {
                            // show message

                            return "Select at least 1 category".tr;
                          }
                          //
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        print('add hashtag button pressed');
                        if (!formKey.currentState!.validate()) {
                          // show message

                          return;
                        }
                        if (_hashtagController.text.isNotEmpty) {
                          final hashtagName = _hashtagController.text.trim();

                          // Call API to add hashtag
                          try {
                            final response = await userViewModel.addHashTag({
                              "name":
                                  hashtagName.contains('#')
                                      ? hashtagName
                                      : "#$hashtagName",
                              "category_id":
                                  selectedCategoryIds.isNotEmpty
                                      ? selectedCategoryIds.first
                                      : null,
                              "explanation": "User added hashtag",
                              "priority":
                                  userViewModel.hashTags.isNotEmpty
                                      ? userViewModel.hashTags.last.priority + 1
                                      : 1,
                            });

                            if (response != null &&
                                response['success'] == true) {
                              // Add to selected hashtags
                              setState(() {
                                final newHashtag = HashTagData(
                                  id: response['data']['id'] ?? 0,
                                  name: hashtagName,
                                  explanation: "User added hashtag",
                                  priority: 1,
                                  isUse: 1,
                                );
                                selectedHashtags.add(newHashtag);
                                // Automatically select the newly added hashtag
                                selectedHashtagIdsSet.add(newHashtag.id);
                              // Keep UserViewModel hashtag list in sync so it shows up everywhere
                              userViewModel.hashTags.add(newHashtag);
                              });
                              _hashtagController.clear();
                            }
                          } catch (e) {
                            // Handle error
                            print('Error adding hashtag: $e');
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            widget.isFrotune
                                ? primaryColorConsulor
                                : Color(0xff7E22CE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: CustomText(
                        text: 'Add'.tr,
                        color: Colors.white,
                        weight: FontWeightConstants.medium,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtiesSection() {
    return Consumer<SettingProvider>(
      builder: (context, settingProvider, child) {
        if (!settingProvider.isSpecializationEnabled) {
          return SizedBox.shrink();
        }
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: borderColor),
            ),
            color: Colors.white,

            shadows: [boxShadow()],
          ),
          child: Column(
            children: [
              _buildSectionHeader('Specialties'.tr),
              Customtextfield(
                required: false,
                maxLines: 3,
                keyboard: TextInputType.multiline,
                hint:
                    'e.g., Tarot Reading, Astrology, Numerology, Palm Reading, Crystal Ball',
                controller: _specialtiesController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Specialties is required".tr;
                  }
                  return null;
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileInformationSection() {
    return Consumer<SettingProvider>(
      builder: (context, settingProvider, child) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: ShapeDecoration(
            shadows: [boxShadow()],
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: borderColor),
            ),
          ),
          child: Column(
            children: [
              _buildSectionHeader('Profile Information'.tr),

              // Experience - only show if enabled
              if (settingProvider.isExperienceEnabled)
                _buildProfileItem('Experience'.tr, _experienceController),

              // Certifications - only show if enabled
              // if (settingProvider.isCertificatesEnabled)
              _buildProfileItem('Certifications'.tr, _certificateController),

              _buildProfileItem('Education'.tr, _educationController),
              _buildProfileItem('Training'.tr, _trainingController),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileItem(String title, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15.0),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              text: title,
              fontSize: 14,
              weight: FontWeight.w500,
            ),
          ),
          InkWell(
            onTap: () {
              _showPreviewDialog(title, controller);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  FontAwesomeIcons.eye,
                  color: Color(0xff6B7280),
                  size: 14.0,
                ),
                UIHelper.horizontalSpaceSm5,
                CustomText(text: 'Preview'.tr, color: Color(0xff6B7280)),
              ],
            ),
          ),
          SizedBox(width: 15),
          InkWell(
            onTap: () {
              _showEditDialog(title, controller);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, color: primaryColorConsulor, size: 14.0),
                UIHelper.horizontalSpaceSm5,
                CustomText(text: 'Edit'.tr, color: primaryColorConsulor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthDateTimeSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor),
        ),
        shadows: [boxShadow()],
        color: whiteColor,
      ),
      child: Row(
        children: [
          CustomText(
            text: 'Birth Date and Time Input'.tr,
            weight: FontWeightConstants.medium,
          ),
          const Spacer(),
          Switch(
            value: timeInputEnabled,
            activeColor: primaryColorConsulor,
            inactiveTrackColor: Colors.grey.shade300,
            inactiveThumbColor: Colors.white,
            trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            splashRadius: 0,

            onChanged: (value) {
              setState(() {
                timeInputEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor),
        ),
        shadows: [boxShadow()],
        color: whiteColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Consultation Settings'.tr, isRequired: true),
          CustomText(
            text: 'Consultation Methods'.tr,
            fontSize: 14,
            weight: FontWeight.w500,
          ),
          const SizedBox(height: 12),
          _buildConsultationMethod(
            'Video Call'.tr,
            videoCallAvailable,
            (value) {
              setState(() {
                videoCallAvailable = value;
              });
            },
            videoCallCoin,
            (value) {
              setState(() {
                videoCallCoin = int.tryParse(value) ?? 0;
              });
            },
            _videoCallCoinController,
          ),
          _buildConsultationMethod(
            'Voice Call'.tr,
            voiceCallAvailable,
            (value) {
              setState(() {
                voiceCallAvailable = value;
              });
            },
            voiceCallCoin,
            (value) {
              setState(() {
                voiceCallCoin = int.tryParse(value) ?? 0;
              });
            },
            _voiceCallCoinController,
          ),
          _buildConsultationMethod(
            'Chat'.tr,
            chatAvailable,
            (value) {
              setState(() {
                chatAvailable = value;
              });
            },
            chatCoin,
            (value) {
              setState(() {
                chatCoin = int.tryParse(value) ?? 0;
              });
            },
            _chatCoinController,
          ),

          const SizedBox(height: 16),
          CustomText(
            text: 'Tax Invoice'.tr,
            fontSize: 14,
            weight: FontWeight.w500,
          ),
          const SizedBox(height: 8),
          Container(
            width: Get.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: taxInvoiceAvailable,
                  activeColor: primaryColorConsulor,
                  onChanged: (value) {
                    setState(() {
                      taxInvoiceAvailable = value ?? false;
                    });
                  },
                ),
                CustomText(text: 'Available'.tr),
                const SizedBox(width: 20),
                Radio<bool>(
                  value: false,
                  activeColor: primaryColorConsulor,

                  groupValue: taxInvoiceAvailable,
                  onChanged: (value) {
                    setState(() {
                      taxInvoiceAvailable = value ?? false;
                    });
                  },
                ),
                CustomText(text: 'Not Available'.tr),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationMethod(
    String title,
    bool isSelected,
    Function(bool) onChanged,
    int coinValue,
    Function(String) onCoinChanged,
    TextEditingController controller,
  ) {
    // Update controller text when coinValue changes
    if (controller.text != (coinValue > 0 ? coinValue.toString() : '')) {
      controller.text = coinValue > 0 ? coinValue.toString() : '';
    }

    return Container(
      height: 45.0,
      margin: EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 0),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor),
        ),
        shadows: [boxShadow()],
        color: whiteColor,
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Radio<bool>(
                  value: true,
                  activeColor: primaryColorConsulor,
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  splashRadius: 0,
                  groupValue: isSelected,
                  onChanged: (value) => onChanged(value ?? false),
                ),
                CustomText(text: title),
              ],
            ),
          ),
          const SizedBox(width: 20),

          Expanded(
            child: SizedBox(
              height: 30.0,
              child: TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                controller: controller,
                style: textStyleRobotoRegular(
                  fontSize: 12,
                  color: Colors.black,
                  weight: FontWeightConstants.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter coins'.tr,
                  hintStyle: textStyleRobotoRegular(
                    fontSize: 12,
                    color: Colors.grey,
                    weight: FontWeightConstants.regular,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                ),
                onChanged: (value) {
                  // Update coin value
                  onCoinChanged(value);

                  // Auto check/uncheck radio based on text field content
                  if (value.trim().isNotEmpty &&
                      int.tryParse(value.trim()) != null) {
                    // If text field has a valid number, check the radio
                    if (!isSelected) {
                      onChanged(true);
                    }
                  } else {
                    // If text field is empty or invalid, uncheck the radio
                    if (isSelected) {
                      onChanged(false);
                    }
                  }
                },
              ),
            ),
          ),

          const SizedBox(width: 8),
          CustomText(text: 'coins/min'.tr),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildAvailableDaysTimesSection(UserViewModel userViewModel) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor),
        ),
        shadows: [boxShadow()],
        color: whiteColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Available Days & Times'.tr, isRequired: true),
          UIHelper.verticalSpaceSm5,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                days.map((day) {
                  final isActive = activeDay == day;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        // Set the active day (only one can be active at a time)
                        activeDay = day;
                        // Add to selectedDays if not already there
                        if (!selectedDays.contains(day)) {
                          selectedDays.add(day);
                        }
                        // Initialize slots if not exists
                        if (!selectedTimeSlotsByDay.containsKey(day)) {
                          selectedTimeSlotsByDay[day] = [];
                        }
                      });
                    },
                    child: dayContainer(
                      isActive, // Use isActive instead of isSelected for border
                      day,
                      isActive: isActive,
                      hasSlots: (selectedTimeSlotsByDay[day]?.length ?? 0) > 0,
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 20),
          if (activeDay != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CustomText(
                text:
                    '${_getLocalizedDayName(activeDay!)} ${'consultation available time'.tr}',
                fontSize: 14,
                color: primaryColorConsulor,
                weight: FontWeight.bold,
              ),
            ),
          if (activeDay != null &&
              selectedDays.contains(activeDay) &&
              userViewModel.timeSlots.isNotEmpty) ...[
            CustomText(
              text:
                  '${'Morning Hours (06:00 - 12:30)'.tr} (${_getLocalizedDayName(activeDay!)})',
              fontSize: 14,
              weight: FontWeightConstants.medium,
            ),
            const SizedBox(height: 12),
            _buildTimeSlotsGrid(
              userViewModel.timeSlots.first.slots,
              activeDay!,
            ),

            const SizedBox(height: 16),
            CustomText(
              text:
                  '${'Afternoon Hours (13:00 - 24:00)'.tr} (${_getLocalizedDayName(activeDay!)})',
              fontSize: 14,
              weight: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            if (userViewModel.timeSlots.length > 1)
              _buildTimeSlotsGrid(userViewModel.timeSlots[1].slots, activeDay!),
          ] else if (selectedDays.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CustomText(
                  text:
                      'Please select a day to set its available time slots'.tr,
                  color: Colors.grey,
                ),
              ),
            ),
          ],

          // Show availability summary if any day has slots
          if (selectedTimeSlotsByDay.values.any(
            (slots) => slots.isNotEmpty,
          )) ...[
            const Divider(height: 40),
            _buildAvailabilitySummary(userViewModel),
          ],
        ],
      ),
    );
  }

  Widget dayContainer(
    bool isSelected, // This now represents isActive (the day being edited)
    String day, {
    bool isActive = false,
    bool hasSlots = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            color:
                (isActive || isSelected)
                    ? primaryColorConsulor.withOpacity(0.05)
                    : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border:
                isSelected
                    ? Border.all(color: primaryColorConsulor, width: 1.5)
                    : Border.all(color: Colors.grey.shade300, width: 1.5),
          ),
          child: Center(
            child: CustomText(
              text: _getLocalizedDayName(day).substring(0, 1),
              color:
                  (isActive || isSelected)
                      ? primaryColorConsulor
                      : Colors.black87,
              weight:
                  (isActive || isSelected)
                      ? FontWeight.bold
                      : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
        if (hasSlots)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: primaryColorConsulor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimeSlotsGrid(List<Slot> slots, String day) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final daySlots = selectedTimeSlotsByDay[day] ?? [];
        final isSelected = daySlots.contains(slot.id);
        return _TimeSlotItem(
          slot: slot,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedTimeSlotsByDay[day]!.remove(slot.id);
              } else {
                if (selectedTimeSlotsByDay[day] == null) {
                  selectedTimeSlotsByDay[day] = [];
                }
                selectedTimeSlotsByDay[day]!.add(slot.id);
              }
              print(
                selectedTimeSlotsByDay.toString() + "...." + slot.id.toString(),
              );
            });
          },
        );
      },
    );
  }

  Widget _buildAvailabilitySummary(UserViewModel userViewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show all days that have slots, not just selectedDays
        ...selectedTimeSlotsByDay.entries.map((entry) {
          final day = entry.key;
          final slotsIds = entry.value;
          if (slotsIds.isEmpty) return const SizedBox.shrink();

          // Get slot labels
          List<String> slotLabels = [];
          for (var id in slotsIds) {
            // Find slot in userViewModel.timeSlots
            for (var group in userViewModel.timeSlots) {
              for (var slot in group.slots) {
                if (slot.id == id) {
                  slotLabels.add(slot.displayTime);
                }
              }
            }
          }

          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.0.h),
            decoration: BoxDecoration(
              color: primaryColorConsulor.withAlpha(10),
              borderRadius: BorderRadius.circular(8),
              //   border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      text: _getFullDayName(day).tr,
                      weight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    InkWell(
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onTap: () {
                        setState(() {
                          selectedDays.remove(day);
                          selectedTimeSlotsByDay.remove(day);
                          if (activeDay == day) {
                            // Set activeDay to first day with slots, or null
                            final dayWithSlots =
                                selectedTimeSlotsByDay.entries
                                    .where((entry) => entry.value.isNotEmpty)
                                    .firstOrNull;
                            activeDay = dayWithSlots?.key;
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  runAlignment: WrapAlignment.start,
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children:
                      slotLabels
                          .map(
                            (label) => CustomText(
                              text: label,
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildReservationSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor),
        ),
        shadows: [boxShadow()],
        color: whiteColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Reservation Settings'.tr),
          UIHelper.verticalSpaceSm,
          Row(
            children: [
              Expanded(
                child: _buildDropdownSetting(
                  'Minimum Booking Time'.tr,
                  _getMinBookingTimeDisplay(),
                  ['30 minutes before', '1 hour before', '2 hours before'],
                  (value) {
                    setState(() {
                      if (value == '30 minutes before') {
                        minBookingTime = 30;
                      } else if (value == '1 hour before') {
                        minBookingTime = 60;
                      } else if (value == '2 hours before') {
                        minBookingTime = 120;
                      } else {
                        minBookingTime = 30;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdownSetting(
                  'Maximum Booking Period'.tr,
                  _getMaxBookingPeriodDisplay(),
                  ['7 days', '14 days', '30 days', '90 days'],
                  (value) {
                    setState(() {
                      if (value == '7 days') {
                        maxBookingPeriod = 7;
                      } else if (value == '14 days') {
                        maxBookingPeriod = 14;
                      } else if (value == '30 days') {
                        maxBookingPeriod = 30;
                      } else if (value == '90 days') {
                        maxBookingPeriod = 90;
                      } else {
                        maxBookingPeriod = 7;
                      }
                    });
                  },
                ),
              ),
            ],
          ),

          UIHelper.verticalSpaceMd,
          CustomText(
            text: 'Booking Confirmation'.tr,
            fontSize: 14,
            weight: FontWeightConstants.medium,
          ),
          //  const SizedBox(height: 8),
          Container(
            transform: Matrix4.translationValues(-15, 0, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Radio<String>(
                  value: 'auto',
                  groupValue: bookingConfirmation,
                  activeColor: primaryColorConsulor,
                  onChanged: (value) {
                    setState(() {
                      bookingConfirmation = value ?? 'auto';
                    });
                  },
                ),
                CustomText(text: 'Auto Accept'.tr),
                // const SizedBox(width: 20),
                Radio<String>(
                  value: 'manual',
                  groupValue: bookingConfirmation,
                  activeColor: primaryColorConsulor,

                  onChanged: (value) {
                    setState(() {
                      bookingConfirmation = value ?? 'manual';
                    });
                  },
                ),
                CustomText(text: 'Manual Review'.tr),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMinBookingTimeDisplay() {
    switch (minBookingTime) {
      case 30:
        return '30 minutes before';
      case 60:
        return '1 hour before';
      case 120:
        return '2 hours before';
      default:
        return '30 minutes before';
    }
  }

  String _getMaxBookingPeriodDisplay() {
    switch (maxBookingPeriod) {
      case 7:
        return '7 days';
      case 14:
        return '14 days';
      case 30:
        return '30 days';
      case 90:
        return '90 days';
      default:
        return '7 days';
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColorConsulor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate =
          '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
      _temporaryHolidayController.text = formattedDate;
    }
  }

  Widget _buildDropdownSetting(
    String title,
    String value,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: title,
          fontSize: FontConstants.font_13,
          weight: FontWeightConstants.medium,
        ),
        UIHelper.verticalSpaceSm5,
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          ),
          items:
              options.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: AutoSizeText(
                    option.tr,
                    maxLines: 2,
                    minFontSize: 10,
                    maxFontSize: option.length > 15 ? 11 : 13,
                  ),
                );
              }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }

  Widget _buildHolidaySettingsSection() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor),
        ),
        shadows: [boxShadow()],
        color: whiteColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Holiday Settings'.tr),

          CustomText(
            text: 'Regular Holidays'.tr,
            fontSize: 14,
            weight: FontWeightConstants.medium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children:
                days.map((day) {
                  final isSelected = regularHolidays.contains(day);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          regularHolidays.remove(day);
                        } else {
                          regularHolidays.add(day);
                        }
                      });
                    },
                    child: dayContainer(isSelected, day),
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),
          CustomText(
            text: 'Temporary Holidays'.tr,
            fontSize: 14,
            weight: FontWeight.w500,
          ),
          const SizedBox(height: 8),
          if (temporaryHolidays.isNotEmpty) ...[
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children:
                  temporaryHolidays.map((holiday) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColorConsulor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            text: holiday,
                            color: Colors.white,
                            fontSize: 12,
                            weight: FontWeight.w500,
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                temporaryHolidays.remove(holiday);
                              });
                            },
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _selectDate,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _temporaryHolidayController,
                      decoration: const InputDecoration(
                        hintText: '--/--/--',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          setState(() {
                            temporaryHolidays.add(value);
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 45.0,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_temporaryHolidayController.text.isNotEmpty) {
                      setState(() {
                        temporaryHolidays.add(_temporaryHolidayController.text);
                        _temporaryHolidayController.clear();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColorConsulor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: CustomText(
                    text: 'Add'.tr,
                    color: Colors.white,
                    weight: FontWeightConstants.medium,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationPackagesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor),
        ),
        shadows: [boxShadow()],

        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Consultation Packages'.tr, isOptional: true),
          if (packages.isNotEmpty) ...[
            ...packages.asMap().entries.map((entry) {
              final index = entry.key;
              final package = entry.value;
              return _buildPackageCard(package, index);
            }).toList(),
            const SizedBox(height: 16),
          ],
          GestureDetector(
            onTap: () {
              _showAddPackageDialog();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: borderColor,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Icon(Icons.add, size: 24, color: Colors.grey),
                  const SizedBox(height: 8),
                  CustomText(text: 'Add Package'.tr),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> package, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Package name and type
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      text: package['name'] ?? 'Package Name'.tr,
                      fontSize: 16,
                      weight: FontWeightConstants.semiBold,
                      color: Colors.black,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColorConsulor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CustomText(
                      text: '${package['discount_rate'] ?? 0}%',
                      fontSize: 12,
                      weight: FontWeightConstants.bold,
                      color: Colors.white,
                    ),
                  ),
                  //  UIHelper.horizontalSpaceSm,
                  GestureDetector(
                    onTap: () {
                      // show confiramtion dialog
                      UIHelper.showDialogOk(
                        context,
                        title: 'Remove Package'.tr,
                        message:
                            'Are you sure you want to remove this package?'.tr,
                        onConfirm: () {
                          Get.back();
                          // Get package ID before removing
                          final packageId = package['id'];
                          setState(() {
                            packages.removeAt(index);
                          });
                          // Delete package from API in background
                          if (packageId != null) {
                            _deletePackageFromApi(packageId);
                          }
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              CustomText(
                text: 'Package'.tr,
                fontSize: 14,
                weight: FontWeightConstants.regular,
                color: Colors.black,
              ),
              const SizedBox(height: 4),
              CustomText(
                text: package['description'] ?? 'Package description'.tr,
                fontSize: 12,
                weight: FontWeightConstants.regular,
                color: Colors.black,
              ),
              const SizedBox(height: 12),

              // Price section
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Coin icon
                  SvgPicture.asset(AppIcons.coinsvg, color: Color(0xffEAB308)),

                  // const SizedBox(width: 6),

                  // Original price (strikethrough)
                  CustomText(
                    text: '${package['original_price'] ?? 0}',
                    fontSize: 14,
                    weight: FontWeightConstants.regular,
                    color: Colors.black,
                    decoration: TextDecoration.lineThrough,
                  ),
                  const SizedBox(width: 8),

                  // New price
                  CustomText(
                    text: '${package['new_price'] ?? 0}',
                    fontSize: 16,
                    weight: FontWeightConstants.semiBold,
                    color: Colors.black,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            () {
              _saveDraft();
            },
            text: "Save Draft".tr,
            isCancelButton: true,
            buttonBorderColor: primaryColorConsulor,
            textcolor: primaryColorConsulor,
          ),
        ),
        UIHelper.horizontalSpaceSm,
        Expanded(
          child: CustomButton(
            () {
              _createService();
            },
            text: "Save".tr,
            color: primaryColorConsulor,
            buttonBorderColor: primaryColorConsulor,
          ),
        ),
      ],
    );
  }

  void _showEditDialog(String title, TextEditingController controller) {
    final QuillEditorController quillController = QuillEditorController();
    String currentContent = controller.text;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 460.h,

                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            text: 'Edit Profile Information'.tr,
                            fontSize: 18,
                            weight: FontWeightConstants.semiBold,
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Rich Text Editor
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            ToolBar(
                              controller: quillController,
                              toolBarColor: Colors.white,
                              iconSize: 20,
                              iconColor: Colors.grey.shade700,
                              activeIconColor: primaryColorConsulor,
                              toolBarConfig: [
                                ToolBarStyle.bold,
                                ToolBarStyle.italic,
                                ToolBarStyle.underline,
                                ToolBarStyle.listOrdered,
                                ToolBarStyle.listBullet,
                                ToolBarStyle.clean,

                                ToolBarStyle.blockQuote,

                                ToolBarStyle.color,
                                ToolBarStyle.align,
                              ],
                              customButtons: [],
                            ),

                            QuillHtmlEditor(
                              text: currentContent,

                              hintText: 'Enter ${title.tr}...',
                              controller: quillController,
                              isEnabled: true,
                              minHeight: 200.h,
                              textStyle: const TextStyle(fontSize: 14),
                              hintTextStyle: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              hintTextAlign: TextAlign.start,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              hintTextPadding: const EdgeInsets.only(left: 20),
                              backgroundColor: Colors.white,
                              onFocusChanged: (hasFocus) {
                                debugPrint('has focus $hasFocus');
                              },
                              onTextChanged: (text) {
                                debugPrint('widget text change $text');
                              },
                              onEditorCreated: () {
                                debugPrint('Editor has been loaded');
                              },
                              onEditorResized: (height) {
                                debugPrint('Editor resized $height');
                              },
                              onSelectionChanged: (selection) {
                                debugPrint(
                                  '${selection.index}, ${selection.length}',
                                );
                              },
                              loadingBuilder: (context) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: CustomText(
                                text: 'Cancel'.tr,
                                color: Colors.black,
                                weight: FontWeightConstants.medium,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final text = await quillController.getText();
                                controller.text = text;
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColorConsulor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: CustomText(
                                text: 'Save'.tr,
                                color: Colors.white,
                                weight: FontWeightConstants.medium,
                              ),
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
      },
    );
  }

  void _showPreviewDialog(String title, TextEditingController controller) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      text: 'Information Preview',
                      fontSize: 18,
                      weight: FontWeightConstants.semiBold,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Content
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: title,
                        fontSize: 16,
                        weight: FontWeightConstants.semiBold,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 12),
                      if (controller.text.isNotEmpty)
                        Html(data: controller.text)
                      else
                        CustomText(
                          text: 'No content available'.tr,
                          fontSize: 14,
                          weight: FontWeightConstants.regular,
                          color: Colors.grey[600],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColorConsulor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: CustomText(
                      text: 'Close'.tr,
                      color: Colors.white,
                      weight: FontWeightConstants.medium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddPackageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: CustomText(
            text: 'Add Package'.tr,
            fontSize: 18,
            weight: FontWeightConstants.semiBold,
            color: Colors.grey[800],
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Package Name
                  CustomText(
                    text: 'Package Name'.tr,
                    fontSize: 14,
                    weight: FontWeightConstants.medium,
                    color: Colors.grey[800],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _packageNameController,
                    decoration: InputDecoration(
                      hintText: 'Enter package name'.tr,
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColorConsulor),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Discount Rate
                  CustomText(
                    text: 'Discount Rate (%)'.tr,
                    fontSize: 14,
                    weight: FontWeightConstants.medium,
                    color: Colors.grey[800],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _packageDiscountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter discount rate'.tr,
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColorConsulor),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Duration and Sessions Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: 'Duration (minutes)'.tr,
                              fontSize: 14,
                              weight: FontWeightConstants.medium,
                              color: Colors.grey[800],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _packageDurationController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '60',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: primaryColorConsulor,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: 'Sessions'.tr,
                              fontSize: 14,
                              weight: FontWeightConstants.medium,
                              color: Colors.grey[800],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _packageSessionController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '2',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: primaryColorConsulor,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Original Price
                  CustomText(
                    text: 'Original Price (coins)'.tr,
                    fontSize: 14,
                    weight: FontWeightConstants.medium,
                    color: Colors.grey[800],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _packageCoinsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '2000',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColorConsulor),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: CustomText(
                    text: 'Cancel'.tr,
                    color: Colors.grey[700],
                    weight: FontWeightConstants.medium,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    if (_packageNameController.text.isNotEmpty) {
                      final discountRate =
                          int.tryParse(_packageDiscountController.text) ?? 0;
                      final coins =
                          int.tryParse(_packageCoinsController.text) ?? 0;
                      final originalPrice = coins;
                      final newPrice =
                          (coins * (100 - discountRate) / 100).round();
                      var packageData = {
                        'name': _packageNameController.text,
                        'discount_rate': discountRate,
                        'duration':
                            int.tryParse(_packageDurationController.text) ?? 0,
                        'session':
                            int.tryParse(_packageSessionController.text) ?? 0,
                        'coins': coins,
                        'original_price': originalPrice,
                        'new_price': newPrice,
                        'description':
                            '${_packageDurationController.text}${'-minute consultation x'.tr}${_packageSessionController.text}${'sessions'.tr}',
                      };
                      print(packageData.toString());
                      setState(() {
                        packages.add(packageData);
                      });

                      // Call API in background (non-blocking)
                      _addPackageToApi(packageData);

                      _packageNameController.clear();
                      _packageDiscountController.clear();
                      _packageDurationController.clear();
                      _packageSessionController.clear();
                      _packageCoinsController.clear();

                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColorConsulor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: CustomText(
                    text: 'Save'.tr,
                    color: Colors.white,
                    weight: FontWeightConstants.medium,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  List<int> _getSelectedHashtagIds() {
    // Return only the IDs of hashtags that are selected
    return selectedHashtagIdsSet.toList();
  }

  // Call package/add API in background
  Future<void> _addPackageToApi(Map<String, dynamic> packageData) async {
    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        debugPrint('❌ Package API: No token available');
        return;
      }

      final requestBody = {
        "name": packageData['name'],
        "discount_rate": packageData['discount_rate'],
        "duration": packageData['duration'],
        "session": packageData['session'],
        "coins": packageData['coins'],
        "section_id": selectedSectionId ?? 1,
      };

      debugPrint('📤 Calling package/add API...');
      debugPrint('   Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(ApiEndPoints.PACKAGE_ADD),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Package API success: ${response.body}');
      } else {
        debugPrint(
          '❌ Package API failed: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error calling package/add API: $e');
    }
  }

  void _createService() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // if (_getSelectedHashtagIds().isEmpty) {
    //   // show message
    //   UIHelper.showBottomFlash(
    //     context,
    //     title: '',
    //     message: 'Select at least 1 hashtag'.tr,
    //     isError: true,
    //   );

    //   return;
    // }

    // Prepare the service data
    final serviceData = {
      "section_id": selectedSectionId,
      "category_id": selectedCategoryIds,
      "taxonomie_item_id": selectedTaxonomieItemIds,
      "hash_tag_id": _getSelectedHashtagIds(),

      "specialites": _specialtiesController.text,
      "experience": _experienceController.text,
      "certificate": _certificateController.text,
      "education": _educationController.text,
      "training": _trainingController.text,
      "time_input": timeInputEnabled,
      "voice_call_available": voiceCallAvailable,
      "voice_call_coin": voiceCallCoin,
      "video_call_available": videoCallAvailable,
      "video_call_coin": videoCallCoin,
      "chat_available": chatAvailable,
      "chat_coin": chatCoin,
      "tax_invoice_available": taxInvoiceAvailable,
      "min_booking_time": minBookingTime,
      "max_booking_period": maxBookingPeriod,
      "booking_confirmation": bookingConfirmation,
      "counselor_availability": _buildCounselorAvailability(),
      "holidays": _buildHolidays(),
      "packages": _buildPackagesForApi(),
    };
    _buildHolidays().map((e) {
      print(e.toString());
    }).toList();

    // Call the API to create the service
    context.read<UserViewModel>().createServiceAPI(context, serviceData);
    _clearDraft();
  }

  List<Map<String, dynamic>> _buildCounselorAvailability() {
    List<Map<String, dynamic>> availability = [];

    for (String day in selectedDays) {
      availability.add({
        "day": day.toLowerCase(),
        "slots": selectedTimeSlotsByDay[day] ?? [],
      });
    }

    return availability;
  }

  List<Map<String, dynamic>> _buildPackagesForApi() {
    return packages.map((package) {
      return {
        'name': package['name'],
        'discount_rate':
            double.tryParse(package['discount_rate'].toString()) ?? 0,
        'duration': package['duration'],
        'session': package['session'],
        'coins': package['coins'],
      };
    }).toList();
  }

  List<Map<String, dynamic>> _buildHolidays() {
    List<Map<String, dynamic>> holidays = [];

    // Add regular holidays
    for (String day in regularHolidays) {
      holidays.add({"type": "regular", "day_of_week": day});
    }

    // Add temporary holidays
    for (String date in temporaryHolidays) {
      holidays.add({"type": "temporary", "holiday_date": date});
    }

    return holidays;
  }

  /// Converts lowercase day names from API to proper capitalized format
  String _convertDayName(String dayName) {
    switch (dayName.toLowerCase()) {
      case 'mon':
        return 'Mon';
      case 'tue':
        return 'Tue';
      case 'wed':
        return 'Wed';
      case 'thu':
        return 'Thu';
      case 'fri':
        return 'Fri';
      case 'sat':
        return 'Sat';
      case 'sun':
        return 'Sun';
      default:
        return dayName; // Return as-is if not recognized
    }
  }

  /// Get localized day name for display
  String _getLocalizedDayName(String day) {
    switch (day) {
      case 'Mon':
        return 'Mon'.tr;
      case 'Tue':
        return 'Tue'.tr;
      case 'Wed':
        return 'Wed'.tr;
      case 'Thu':
        return 'Thu'.tr;
      case 'Fri':
        return 'Fri'.tr;
      case 'Sat':
        return 'Sat'.tr;
      case 'Sun':
        return 'Sun'.tr;
      default:
        return day;
    }
  }

  //full day name
  String _getFullDayName(String day) {
    switch (day.toLowerCase()) {
      case 'mon':
        return 'Monday';
      case 'tue':
        return 'Tuesday';
      case 'wed':
        return 'Wednesday';
      case 'thu':
        return 'Thursday';
      case 'fri':
        return 'Friday';
      case 'sat':
        return 'Saturday';
      case 'sun':
        return 'Sunday';
      default:
        return day;
    }
  }
}

BoxShadow boxShadow() {
  return BoxShadow(
    color: Color(0x0C000000),
    blurRadius: 2,
    offset: Offset(0, 1),
    spreadRadius: 0,
  );
}

// Optimized Category Item Widget
class _CategoryItem extends StatelessWidget {
  final dynamic category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryItem({
    Key? key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColorConsulor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primaryColorConsulor : borderColor,
            width: 1,
          ),
        ),
        child: Center(
          child: CustomText(
            text: category.name,
            color: isSelected ? Colors.white : Colors.black,
            weight:
                isSelected
                    ? FontWeightConstants.medium
                    : FontWeightConstants.regular,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// Optimized Taxonomy Item Widget
class _TaxonomyItem extends StatelessWidget {
  final dynamic item;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(bool?) onCheckboxChanged;

  const _TaxonomyItem({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onCheckboxChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                activeColor: primaryColorConsulor,
                side: BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onChanged: onCheckboxChanged,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: CustomText(
                  text: item.name,
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.regular,
                  maxlines: 1,
                  align: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Optimized Time Slot Item Widget
class _TimeSlotItem extends StatelessWidget {
  final Slot slot;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeSlotItem({
    Key? key,
    required this.slot,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? primaryColorConsulor.withOpacity(0.05)
                  : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryColorConsulor : borderColor,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Center(
          child: CustomText(
            text: slot.displayTime,
            color: isSelected ? primaryColorConsulor : Colors.black87,
            fontSize: 12,
            weight: isSelected ? FontWeight.bold : FontWeight.normal,
            maxlines: 1,
          ),
        ),
      ),
    );
  }
}
