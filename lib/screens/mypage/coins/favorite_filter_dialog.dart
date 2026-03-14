import 'package:deepinheart/services/translation_service.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Filter Dialog Widget
class FavoriteFilterDialog extends StatefulWidget {
  final List<String> availableCategories;
  final List<String> initialCategories;
  final double? initialRating;
  final String initialSort;
  final Function(List<String>, double?, String) onApply;

  FavoriteFilterDialog({
    required this.availableCategories,
    this.initialCategories = const [],
    this.initialRating,
    this.initialSort = 'Highest Rating',
    required this.onApply,
  });

  @override
  _FavoriteFilterDialogState createState() => _FavoriteFilterDialogState();
}

class _FavoriteFilterDialogState extends State<FavoriteFilterDialog> {
  List<String> selectedCategories = [];
  double? selectedRating;
  String selectedSort = 'Highest Rating';

  @override
  void initState() {
    super.initState();
    selectedCategories = List.from(widget.initialCategories);
    selectedRating = widget.initialRating;
    // Normalize initialSort - convert translated to English if needed
    if (widget.initialSort == 'Highest Rating'.tr) {
      selectedSort = 'Highest Rating';
    } else if (widget.initialSort == 'Most Reviews'.tr) {
      selectedSort = 'Most Reviews';
    } else if (widget.initialSort == 'Recently Favorited'.tr) {
      selectedSort = 'Recently Favorited';
    } else {
      selectedSort = widget.initialSort.isNotEmpty ? widget.initialSort : 'Highest Rating';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: 'Filter'.tr,
                  fontSize: FontConstants.font_18,
                  weight: FontWeightConstants.bold,
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Get.back(),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
            UIHelper.verticalSpaceMd,

            // Categories Section
            CustomText(
              text: 'Categories'.tr,
              fontSize: FontConstants.font_14,
              weight: FontWeightConstants.semiBold,
            ),
            UIHelper.verticalSpaceSm,

            // Categories with Checkboxes in Grid (2 columns)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              childAspectRatio: 4,
              mainAxisSpacing: 0,
              crossAxisSpacing: 0,
              children:
                  widget.availableCategories.map((category) {
                    bool isSelected = selectedCategories.contains(category);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedCategories.remove(category);
                          } else {
                            selectedCategories.add(category);
                          }
                        });
                      },
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedCategories.add(category);
                                } else {
                                  selectedCategories.remove(category);
                                }
                              });
                            },
                            activeColor: primaryColor,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: FutureBuilder<String>(
                              future: translationService.translate(category),
                              builder: (context, snapshot) {
                                return CustomText(
                                  text: snapshot.hasData ? snapshot.data! : category,
                              fontSize: FontConstants.font_13,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),

            UIHelper.verticalSpaceMd,

            // Rating Section
            CustomText(
              text: 'Rating'.tr,
              fontSize: FontConstants.font_14,
              weight: FontWeightConstants.medium,
            ),
            SizedBox(height: 8),
            _buildRatingOption(5.0, '5.0+'),
            _buildRatingOption(4.0, '4.0+'),
            _buildRatingOption(3.0, '3.0+'),

            UIHelper.verticalSpaceMd,

            // Sort by Section
            CustomText(
              text: 'Sort by'.tr,
              fontSize: FontConstants.font_14,
              weight: FontWeightConstants.semiBold,
            ),
            SizedBox(height: 8),
            _buildSortOption('Highest Rating'),
            _buildSortOption('Most Reviews'),
            _buildSortOption('Recently Favorited'),

            UIHelper.verticalSpaceL,

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        selectedCategories.clear();
                        selectedRating = null;
                        selectedSort = 'Highest Rating';
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: CustomText(
                      text: 'Reset'.tr,
                      fontSize: FontConstants.font_14,
                      weight: FontWeightConstants.medium,
                    ),
                  ),
                ),
                UIHelper.horizontalSpaceMd,
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(
                        selectedCategories,
                        selectedRating,
                        selectedSort,
                      );
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: CustomText(
                      text: 'Apply'.tr,
                      fontSize: FontConstants.font_14,
                      weight: FontWeightConstants.semiBold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            UIHelper.verticalSpaceMd,
          ],
        ),
      ),
    );
  }

  Widget _buildRatingOption(double rating, String label) {
    bool isSelected = selectedRating == rating;
    return InkWell(
      onTap: () {
        setState(() {
          selectedRating = isSelected ? null : rating;
        });
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 0),
        child: Row(
          children: [
            Radio<double>(
              value: rating,
              groupValue: selectedRating,
              onChanged: (value) {
                setState(() {
                  selectedRating = value;
                });
              },
              activeColor: primaryColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            SizedBox(width: 8),
            ...List.generate(
              rating.toInt(),
              (index) => Icon(Icons.star, color: Colors.amber, size: 16),
            ),
            ...List.generate(
              5 - rating.toInt(),
              (index) => Icon(Icons.star_border, color: Colors.amber, size: 16),
            ),
            SizedBox(width: 8),
            CustomText(text: label, fontSize: FontConstants.font_13),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String option) {
    // Map English options to their display text
    String displayText = option;
    if (option == 'Highest Rating' || option == 'Highest Rating'.tr) {
      displayText = 'Highest Rating'.tr;
    } else if (option == 'Most Reviews' || option == 'Most Reviews'.tr) {
      displayText = 'Most Reviews'.tr;
    } else if (option == 'Recently Favorited' || option == 'Recently Favorited'.tr) {
      displayText = 'Recently Favorited'.tr;
    }
    
    // Use English for internal comparison
    String internalValue = option;
    if (option == 'Highest Rating'.tr) {
      internalValue = 'Highest Rating';
    } else if (option == 'Most Reviews'.tr) {
      internalValue = 'Most Reviews';
    } else if (option == 'Recently Favorited'.tr) {
      internalValue = 'Recently Favorited';
    }
    
    // Normalize selectedSort for comparison
    String normalizedSelectedSort = selectedSort;
    if (selectedSort == 'Highest Rating'.tr) {
      normalizedSelectedSort = 'Highest Rating';
    } else if (selectedSort == 'Most Reviews'.tr) {
      normalizedSelectedSort = 'Most Reviews';
    } else if (selectedSort == 'Recently Favorited'.tr) {
      normalizedSelectedSort = 'Recently Favorited';
    }
    
    return InkWell(
      onTap: () {
        setState(() {
          selectedSort = internalValue;
        });
      },

      child: Container(
        //  color: Colors.red,
        margin: EdgeInsets.symmetric(vertical: 0),
        child: Row(
          children: [
            Radio<String>(
              value: internalValue,
              groupValue: normalizedSelectedSort,
              onChanged: (value) {
                setState(() {
                  selectedSort = value!;
                });
              },
              activeColor: primaryColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            SizedBox(width: 8),
            CustomText(text: displayText, fontSize: FontConstants.font_13),
          ],
        ),
      ),
    );
  }
}
