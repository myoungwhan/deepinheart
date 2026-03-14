import 'package:deepinheart/Controller/Model/counselor_model.dart';
import 'package:deepinheart/Controller/Viewmodel/favorite_provider.dart';
import 'package:deepinheart/Views/colors.dart';
import 'package:deepinheart/config/string_constants.dart';
import 'package:deepinheart/screens/counselor/counselor_detail_screen.dart';
import 'package:deepinheart/screens/home/widget/sub_category_chip.dart';
import 'package:deepinheart/screens/mypage/coins/favorite_filter_dialog.dart';
import 'package:deepinheart/services/translation_service.dart';
import 'package:deepinheart/views/custom_appbar.dart';
import 'package:deepinheart/views/custom_button.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/rating_view.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FavoriteCounselorsScreen extends StatefulWidget {
  @override
  State<FavoriteCounselorsScreen> createState() =>
      _FavoriteCounselorsScreenState();
}

class _FavoriteCounselorsScreenState extends State<FavoriteCounselorsScreen> {
  List<String> availableFilters = [];

  // Filter state
  List<String> selectedCategories = [];
  double? selectedRating;
  String selectedSort = 'Highest Rating'.tr;

  @override
  void initState() {
    super.initState();
    // Fetch favorite counselors when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFavoriteCounselors();
    });
  }

  Future<void> _fetchFavoriteCounselors() async {
    final favoriteProvider = Provider.of<FavoriteProvider>(
      context,
      listen: false,
    );
    await favoriteProvider.fetchFavoriteCounselors();
    _updateAvailableFilters();
  }

  void _onCounselorRemoved() {
    _updateAvailableFilters();
  }

  void _updateAvailableFilters() {
    final favoriteProvider = Provider.of<FavoriteProvider>(
      context,
      listen: false,
    );

    Set<String> filterSet = {};

    // Get categories and taxonomies only from favorite counselors
    for (var counselor in favoriteProvider.favoriteCounselors) {
      for (var specialty in counselor.specialties) {
        // Add categories from this counselor
        for (var category in specialty.categories) {
          filterSet.add(category.name);
        }
        // Add taxonomies from this counselor
        for (var taxonomy in specialty.taxonomies) {
          filterSet.add(taxonomy.name);
        }
      }
    }

    setState(() {
      availableFilters = filterSet.toList();
    });
  }

  List<dynamic> get filteredCounselors {
    final favoriteProvider = Provider.of<FavoriteProvider>(
      context,
      listen: false,
    );

    List<dynamic> counselors = List.from(favoriteProvider.favoriteCounselors);

    // Apply category filters
    if (selectedCategories.isNotEmpty) {
      counselors =
          counselors.where((counselor) {
            for (var specialty in counselor.specialties) {
              for (var category in specialty.categories) {
                if (selectedCategories.contains(category.name)) return true;
              }
              for (var taxonomy in specialty.taxonomies) {
                if (selectedCategories.contains(taxonomy.name)) return true;
              }
            }
            return false;
          }).toList();
    }

    // Apply rating filter
    if (selectedRating != null) {
      counselors =
          counselors.where((counselor) {
            return counselor.rating >= selectedRating!;
          }).toList();
    }

    // Apply sorting
    if (selectedSort == 'Highest Rating'.tr ||
        selectedSort == 'Highest Rating') {
      counselors.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (selectedSort == 'Most Reviews'.tr ||
        selectedSort == 'Most Reviews') {
      // Assuming there's a reviews count field, otherwise keep as is
      // counselors.sort((a, b) => b.reviewsCount.compareTo(a.reviewsCount));
    } else if (selectedSort == 'Recently Favorited'.tr ||
        selectedSort == 'Recently Favorited') {
      // Keep original order (recently added first)
    }

    return counselors;
  }

  @override
  Widget build(BuildContext context) {
    // Check if any filter is applied
    bool isFilterApplied =
        selectedCategories.isNotEmpty ||
        selectedRating != null ||
        (selectedSort != 'Highest Rating'.tr &&
            selectedSort != 'Highest Rating');

    return Scaffold(
      appBar: customAppBar(
        title: "Favorite Counselors".tr,
        isLogo: false,
        centerTitle: false,
        action: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.filter_list),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (context) {
                      return FavoriteFilterDialog(
                        availableCategories:
                            availableFilters.where((f) => f != "All").toList(),
                        initialCategories: selectedCategories,
                        initialRating: selectedRating,
                        initialSort: selectedSort,
                        onApply: (categories, rating, sort) {
                          setState(() {
                            selectedCategories = categories;
                            selectedRating = rating;
                            selectedSort = sort;
                          });
                        },
                      );
                    },
                  );
                },
              ),
              // Filter indicator dot
              if (isFilterApplied)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Consumer<FavoriteProvider>(
        builder: (context, favoriteProvider, child) {
          if (favoriteProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            );
          }

          if (favoriteProvider.favoriteCounselors.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  UIHelper.verticalSpaceMd,
                  CustomText(
                    text: "No Favorite Counselors".tr,
                    fontSize: FontConstants.font_16,
                    weight: FontWeightConstants.medium,
                    color: Colors.grey[600],
                  ),
                  UIHelper.verticalSpaceSm,
                  CustomText(
                    text: "Your favorite counselors will appear here".tr,
                    fontSize: FontConstants.font_14,
                    weight: FontWeightConstants.regular,
                    color: Colors.grey[500],
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Filter Chips Section
              if (availableFilters.isNotEmpty) ...[
                UIHelper.verticalSpaceMd,
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // "All" chip
                      Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: CustomText(
                            text: 'All'.tr,
                            fontSize: FontConstants.font_12,
                            weight: FontWeightConstants.medium,
                            color:
                                selectedCategories.isEmpty
                                    ? Colors.white
                                    : Colors.black87,
                          ),
                          selected: selectedCategories.isEmpty,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                selectedCategories.clear();
                              });
                            }
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: primaryColor,
                          checkmarkColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color:
                                  selectedCategories.isEmpty
                                      ? primaryColor
                                      : Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      // Category chips
                      ...availableFilters.map((filter) {
                        final isSelected = selectedCategories.contains(filter);
                        return Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: FutureBuilder<String>(
                              future: translationService.translate(filter),
                              builder: (context, snapshot) {
                                return CustomText(
                                  text:
                                      snapshot.hasData
                                          ? snapshot.data!
                                          : filter,
                                  fontSize: FontConstants.font_12,
                                  weight: FontWeightConstants.medium,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                );
                              },
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedCategories.add(filter);
                                } else {
                                  selectedCategories.remove(filter);
                                }
                              });
                            },
                            backgroundColor: Colors.grey[200],
                            selectedColor: primaryColor,
                            checkmarkColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color:
                                    isSelected
                                        ? primaryColor
                                        : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                UIHelper.verticalSpaceMd,
              ],

              // Expanded list of Counselors
              Expanded(
                child:
                    filteredCounselors.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_alt_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              UIHelper.verticalSpaceMd,
                              CustomText(
                                text: "No counselors match your filters".tr,
                                fontSize: FontConstants.font_16,
                                weight: FontWeightConstants.medium,
                                color: Colors.grey[600],
                              ),
                              UIHelper.verticalSpaceSm,
                              CustomText(
                                text: "Try adjusting your filter criteria".tr,
                                fontSize: FontConstants.font_14,
                                weight: FontWeightConstants.regular,
                                color: Colors.grey[500],
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          itemCount: filteredCounselors.length,
                          itemBuilder: (context, index) {
                            return CounselorCard(
                              counselor: filteredCounselors[index],
                              onCounselorRemoved: _onCounselorRemoved,
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CounselorCard extends StatelessWidget {
  final CounselorData counselor;
  final VoidCallback? onCounselorRemoved;

  CounselorCard({required this.counselor, this.onCounselorRemoved});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: CachedNetworkImageProvider(
                    counselor.profileImage.isNotEmpty
                        ? counselor.profileImage
                        : testuserprofile,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomText(
                            text: counselor.name,
                            fontSize: FontConstants.font_14,
                            weight: FontWeightConstants.medium,
                          ),
                          UIHelper.horizontalSpaceSm,
                          MyRatingView(
                            initialRating: counselor.rating.toDouble(),
                            itemSize: FontConstants.font_16,
                            onRatingUpdate: (va) {},
                            isAllowRating: false,
                            startQuantity: 1,
                            text: counselor.rating.toString(),
                          ),
                        ],
                      ),
                      UIHelper.verticalSpaceSm5,
                      // Display specialties as chips (max 2 lines)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Get all chips first
                          List<Widget> allChips =
                              counselor.specialties.expand<Widget>((specialty) {
                                List<Widget> chips = <Widget>[];
                                // Add category chips with distinct colors
                                for (var category in specialty.categories) {
                                  chips.add(
                                    FutureBuilder<String>(
                                      future: translationService.translate(
                                        category.name,
                                      ),
                                      builder: (context, snapshot) {
                                        return SubCategoryChip(
                                          text:
                                              snapshot.hasData
                                                  ? snapshot.data!
                                                  : category.name,
                                          height: 35.h,
                                          color: Color(
                                            0xFF1976D2,
                                          ), // Blue for categories
                                          fontSize: FontConstants.font_10,
                                        );
                                      },
                                    ),
                                  );
                                }
                                // Add taxonomy chips with distinct colors
                                for (var taxonomy in specialty.taxonomies) {
                                  chips.add(
                                    FutureBuilder<String>(
                                      future: translationService.translate(
                                        taxonomy.name,
                                      ),
                                      builder: (context, snapshot) {
                                        return SubCategoryChip(
                                          height: 35.h,
                                          text:
                                              snapshot.hasData
                                                  ? snapshot.data!
                                                  : taxonomy.name,
                                          color: Color(
                                            0xFF7B1FA2,
                                          ), // Purple for taxonomies
                                          fontSize: FontConstants.font_10,
                                        );
                                      },
                                    ),
                                  );
                                }
                                return chips;
                              }).toList();

                          return Container(
                            height:
                                35.h, // Fixed height for approximately 2 lines
                            margin: EdgeInsets.only(top: 10.h),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                direction: Axis.vertical,
                                children: allChips,
                              ),
                            ),
                          );
                        },
                      ),
                      UIHelper.verticalSpaceSm,
                      CustomText(
                        text: counselor.introduction,
                        fontSize: 12,
                        weight: FontWeight.w300,
                        color: Colors.grey[600]!,
                      ),
                      UIHelper.verticalSpaceSm,
                    ],
                  ),
                ),
                // Heart icon for removing from favorites
                Consumer<FavoriteProvider>(
                  builder: (context, favoriteProvider, child) {
                    return GestureDetector(
                      child: Icon(Icons.favorite, color: Colors.red, size: 24),
                      onTap: () {
                        UIHelper.showDialogOk(
                          context,
                          title: "Remove Favorite".tr,
                          message:
                              'Are you sure you want to remove this counselor from favorites?'
                                  .tr,
                          onConfirm: () async {
                            Get.back(); // Close dialog
                            await favoriteProvider.removeFromFavorites(
                              counselor.id,
                            );
                            onCounselorRemoved?.call();
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 40.h,
              child: CustomButton(text: 'Book Consultation'.tr, () {
                Get.to(
                  CounselorDetailScreen(
                    sectionId: counselor.specialties.first.id ?? 1,
                    model: counselor,
                  ),
                );
              }, fsize: FontConstants.font_14),
            ),
          ],
        ),
      ),
    );
  }
}
