import 'package:deepinheart/Controller/Model/counselor_model.dart';
import 'package:deepinheart/Controller/Viewmodel/service_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/Controller/theme_controller.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:deepinheart/screens/counselor/counselor_detail_screen.dart';
import 'package:deepinheart/screens/home/widget/advoisor_card.dart';
import 'package:deepinheart/screens/home/widget/advoisor_tile.dart';
import 'package:deepinheart/screens/home/widget/sub_category_chip.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ThemeController themeController = Get.find<ThemeController>();

  List<String> _popularSearches = [];
  List<String> _recentSearches = [];
  List<CounselorData> _filteredCounselors = [];
  List<CounselorData> _allCounselors = [];

  String _selectedTab = 'Recommended'; // Recommended, Popular, Rating
  bool _isSearching = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadPopularSearches();
    _loadCounselors();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);

    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }

    await prefs.setStringList('recent_searches', _recentSearches);
    setState(() {});
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() {
      _recentSearches = [];
    });
  }

  Future<void> _removeRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(query);
    await prefs.setStringList('recent_searches', _recentSearches);
    setState(() {});
  }

  void _loadPopularSearches() {
    // Load popular searches from categories/taxonomies
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);

    if (userViewModel.texnomyData != null) {
      Set<String> popular = {};

      // Add fortune categories
      for (var category in userViewModel.texnomyData!.fortune.categories) {
        popular.add(category.name);
      }

      // Add counseling categories
      for (var category in userViewModel.texnomyData!.counseling.categories) {
        popular.add(category.name);
      }

      setState(() {
        _popularSearches = popular.take(5).toList();
      });
    }
  }

  Future<void> _loadCounselors() async {
    setState(() {
      _isLoading = true;
    });

    final serviceProvider = Provider.of<ServiceProvider>(
      context,
      listen: false,
    );

    // Combine all counselors
    _allCounselors = [
      ...serviceProvider.counselorsFortune,
      ...serviceProvider.counselorsCounseling,
    ];

    _filteredCounselors = List.from(_allCounselors);
    _sortCounselors();

    setState(() {
      _isLoading = false;
    });
  }

  void _sortCounselors() {
    switch (_selectedTab) {
      case 'Popular':
        _filteredCounselors.sort(
          (a, b) => b.ratingCount.compareTo(a.ratingCount),
        );
        break;
      case 'Rating':
        _filteredCounselors.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Recommended':
      default:
        // Keep default order or implement recommendation logic
        break;
    }
  }

  void _performSearch(String query, {bool onChange = false}) async {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredCounselors = List.from(_allCounselors);
        _isSearching = false;
      });
      _sortCounselors();
      return;
    }

    if (!onChange) {
      _saveRecentSearch(query);
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    // Call API for search
    await _searchFromApi(query);
  }

  // Search counselors from API
  Future<void> _searchFromApi(String query) async {
    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        debugPrint('❌ Search API: No token available');
        // Fallback to local search
        _performLocalSearch(query);
        return;
      }

      debugPrint('🔍 Searching counselors: $query');

      final response = await http.get(
        Uri.parse('${ApiEndPoints.SEARCH}?query=${Uri.encodeComponent(query)}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Search API success');

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> counselorsJson = data['data'];

          setState(() {
            _filteredCounselors =
                counselorsJson
                    .map((json) => CounselorData.fromJson(json))
                    .toList();
            _isLoading = false;
          });

          _sortCounselors();
        } else {
          setState(() {
            _filteredCounselors = [];
            _isLoading = false;
          });
        }
      } else {
        debugPrint('❌ Search API failed: ${response.statusCode}');
        // Fallback to local search
        _performLocalSearch(query);
      }
    } catch (e) {
      debugPrint('❌ Error calling search API: $e');
      // Fallback to local search
      _performLocalSearch(query);
    }
  }

  // Fallback local search (original logic)
  void _performLocalSearch(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _isSearching = true;
      _filteredCounselors =
          _allCounselors.where((counselor) {
            // Search by name
            if (counselor.name.toLowerCase().contains(lowerQuery) ||
                counselor.nickName.toLowerCase().contains(lowerQuery)) {
              return true;
            }

            // Search by specialties
            for (var specialty in counselor.specialties) {
              if (specialty.name.toLowerCase().contains(lowerQuery)) {
                return true;
              }

              // Search by categories
              for (var category in specialty.categories) {
                if (category.name.toLowerCase().contains(lowerQuery)) {
                  return true;
                }
              }

              // Search by taxonomies
              for (var taxonomy in specialty.taxonomies) {
                if (taxonomy.name.toLowerCase().contains(lowerQuery)) {
                  return true;
                }
              }
            }

            // Search by service specialties
            for (var serviceSpecialty in counselor.serviceSpecialties) {
              if (serviceSpecialty.toLowerCase().contains(lowerQuery)) {
                return true;
              }
            }

            return false;
          }).toList();
      _isLoading = false;
    });

    _sortCounselors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),

        title: Padding(
          padding: EdgeInsets.only(bottom: 5.h),
          child: searchField(),
        ),
      ),
      backgroundColor:
          themeController.isDarkMode.value ? Colors.grey[900] : Colors.white,
      body: Container(
        height: Get.height,
        child: Column(
          children: [
            //   _buildSearchBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [_buildSearchSuggestions(), _buildSearchResults()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          UIHelper.horizontalSpaceSm,
          Expanded(child: searchField()),
        ],
      ),
    );
  }

  Container searchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: Colors.white),
        textInputAction: TextInputAction.search,
        cursorColor: Colors.white,
        cursorWidth: 2.5.sp,
        decoration: InputDecoration(
          hintText: 'Search counselor or content'.tr,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: FontConstants.font_14,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  )
                  : Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
        ),
        onChanged: (data) {
          _performSearch(data, onChange: true);
        },
        onSubmitted: _performSearch,
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_popularSearches.isNotEmpty) ...[
            UIHelper.verticalSpaceMd,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: CustomText(
                text: 'Popular Searches'.tr,
                fontSize: FontConstants.font_16,
                weight: FontWeightConstants.bold,
                color:
                    themeController.isDarkMode.value
                        ? Colors.white
                        : Colors.black,
              ),
            ),
            UIHelper.verticalSpaceSm,
            SizedBox(
              height: 40.h,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  // Calculate padding to center first item (assuming average chip width ~100)
                  final estimatedChipWidth = 100.w;
                  final centerPadding =
                      (screenWidth / 2) - (estimatedChipWidth / 2);

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.only(
                      left: centerPadding,
                      right: centerPadding,
                    ),
                    itemCount: _popularSearches.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index < _popularSearches.length - 1 ? 8.w : 0,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            _searchController.text = _popularSearches[index];
                            _performSearch(_popularSearches[index]);
                          },
                          child: SubCategoryChip(
                            text: "#" + _popularSearches[index].tr,
                            color: primaryColor,
                            fontSize: FontConstants.font_14,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
          if (_recentSearches.isNotEmpty) ...[
            UIHelper.verticalSpaceMd,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    text: 'Recent Searches'.tr,
                    fontSize: FontConstants.font_16,
                    weight: FontWeightConstants.bold,
                    color:
                        themeController.isDarkMode.value
                            ? Colors.white
                            : Colors.black,
                  ),
                  TextButton(
                    onPressed: _clearRecentSearches,
                    child: CustomText(
                      text: 'Clear All'.tr,
                      fontSize: FontConstants.font_14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            UIHelper.verticalSpaceSm,
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _recentSearches.length,
              itemBuilder: (context, index) {
                return _buildRecentSearchItem(_recentSearches[index]);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentSearchItem(String search) {
    return ListTile(
      leading: Icon(
        Icons.history,
        color: themeController.isDarkMode.value ? Colors.white54 : Colors.grey,
      ),
      title: CustomText(
        text: search.tr,
        fontSize: FontConstants.font_14,
        color: themeController.isDarkMode.value ? Colors.white : Colors.black,
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.close,
          color:
              themeController.isDarkMode.value ? Colors.white54 : Colors.grey,
        ),
        onPressed: () => _removeRecentSearch(search),
      ),
      onTap: () {
        _searchController.text = search;
        _performSearch(search);
      },
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        _buildFilterTabs(),
        _isLoading
            ? Center(child: CircularProgressIndicator())
            : _filteredCounselors.isEmpty
            ? _buildEmptyState()
            : _buildCounselorList(),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      decoration: BoxDecoration(
        color:
            themeController.isDarkMode.value ? Colors.grey[850] : Colors.white,
        border: Border(
          bottom: BorderSide(
            color:
                themeController.isDarkMode.value
                    ? Colors.grey[700]!
                    : Color(0xFFE0E0E0),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildTabButton('Recommended'),
                _buildTabButton('Popular'),
                _buildTabButton('Rating'),
              ],
            ),
          ),

          // IconButton(
          //   icon: Icon(
          //     Icons.filter_list,
          //     color:
          //         themeController.isDarkMode.value
          //             ? Colors.white
          //             : Colors.black,
          //   ),
          //   onPressed: () {
          //     // Show filter options
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab) {
    final isSelected = _selectedTab == tab;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = tab;
          });
          _sortCounselors();
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: CustomText(
              text: tab.tr,
              fontSize: FontConstants.font_14,
              weight:
                  isSelected
                      ? FontWeightConstants.semiBold
                      : FontWeightConstants.regular,
              color:
                  isSelected
                      ? primaryColor
                      : (themeController.isDarkMode.value
                          ? Colors.white70
                          : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80.sp, color: Colors.grey),
          UIHelper.verticalSpaceMd,
          CustomText(
            text: 'No counselors found'.tr,
            fontSize: FontConstants.font_16,
            color: Colors.grey,
          ),
          UIHelper.verticalSpaceSm,
          CustomText(
            text: 'Try a different search term'.tr,
            fontSize: FontConstants.font_14,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildCounselorList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: _filteredCounselors.length,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return _buildCounselorCard(_filteredCounselors[index]);
      },
    );
  }

  Widget _buildCounselorCard(CounselorData counselor) {
    // Determine section ID based on counselor's specialties
    int sectionId = 1; // Default to fortune
    if (counselor.specialties.isNotEmpty) {
      sectionId = counselor.specialties.first.id;
    }

    return InkWell(
      onTap: () {
        Get.to(
          () => CounselorDetailScreen(model: counselor, sectionId: sectionId),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color:
              themeController.isDarkMode.value
                  ? Colors.grey[850]
                  : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                themeController.isDarkMode.value
                    ? Colors.grey[700]!
                    : Color(0xFFE0E0E0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image
            Stack(
              children: [
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(counselor.profileImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Status indicator
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16.w,
                    height: 16.w,
                    decoration: BoxDecoration(
                      color:
                          counselor.isOnline
                              ? Colors.green
                              : (counselor.isAvailable
                                  ? Colors.orange
                                  : Colors.grey),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            themeController.isDarkMode.value
                                ? Colors.grey[850]!
                                : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            UIHelper.horizontalSpaceMd,
            // Counselor Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          text: counselor.name,
                          fontSize: FontConstants.font_16,
                          weight: FontWeightConstants.semiBold,
                          color:
                              themeController.isDarkMode.value
                                  ? Colors.white
                                  : Colors.black,
                        ),
                      ),
                      SvgPicture.asset(
                        AppIcons.coinsvg,
                        width: 28,
                        fit: BoxFit.cover,
                        color: const Color(0xffFACC15),
                      ),
                      const SizedBox(width: 4),
                      CustomText(
                        text:
                            getPrimaryConsultationPrice(
                              counselor.consultationMethod,
                            ) +
                            "/" +
                            "min".tr,
                        fontSize: FontConstants.font_12,
                        weight: FontWeightConstants.regular,
                      ),
                    ],
                  ),
                  UIHelper.verticalSpaceSm5,
                  // Specialties tags
                  if (counselor.specialties.isNotEmpty)
                    Wrap(
                      spacing: 4.w,
                      runSpacing: 4.h,
                      children:
                          counselor.specialties
                              .take(2)
                              .expand(
                                (specialty) => specialty.taxonomies.take(2),
                              )
                              .map(
                                (taxonomy) => Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFE3F2FD),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: CustomText(
                                    text: taxonomy.name,
                                    fontSize: FontConstants.font_11,
                                    color: Color(0xFF1976D2),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  UIHelper.verticalSpaceSm5,
                  // Rating
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < counselor.rating.floor()
                              ? Icons.star
                              : (index < counselor.rating
                                  ? Icons.star_half
                                  : Icons.star_border),
                          color: Color(0xFFFFA000),
                          size: 16.sp,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      CustomText(
                        text:
                            '${counselor.rating.toStringAsFixed(1)} (${counselor.ratingCount})',
                        fontSize: FontConstants.font_12,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  UIHelper.verticalSpaceSm5,
                  // Status
                  SubCategoryChip(
                    text: getAvailabilityText(counselor),
                    color: getAvailabilityColor(counselor),
                    isHaveCircle: true,
                  ),
                  if (counselor.introduction.isNotEmpty) ...[
                    UIHelper.verticalSpaceSm5,
                    CustomText(
                      text: counselor.introduction,
                      fontSize: FontConstants.font_12,
                      color: Colors.grey,
                      maxlines: 2,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
