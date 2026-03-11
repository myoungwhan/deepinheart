import 'package:deepinheart/views/custom_button.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FavoriteFilterDialog extends StatelessWidget {
  // Define a controller to manage state
  final FavoriteFilterController _controller = Get.put(
    FavoriteFilterController(),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            text: 'Filter',
            fontSize: 18,
            weight: FontWeight.w500,
            color: Colors.black,
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      content: Container(
        width: Get.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categories Section
            _buildFilterSection('Categories', [
              _buildCheckbox('Tarot', _controller.selectedCategories, 'Tarot'),
              _buildCheckbox(
                'Psychology',
                _controller.selectedCategories,
                'Psychology',
              ),
              _buildCheckbox(
                'Destiny',
                _controller.selectedCategories,
                'Destiny',
              ),
              _buildCheckbox(
                'Fortune',
                _controller.selectedCategories,
                'Fortune',
              ),
              _buildCheckbox('Life', _controller.selectedCategories, 'Life'),
            ]),

            // Rating Section
            _buildFilterSection('Rating', [
              _buildRadioButton('5.0+', 5, _controller.selectedRating),
              _buildRadioButton('4.0+', 4, _controller.selectedRating),
              _buildRadioButton('3.0+', 3, _controller.selectedRating),
            ]),

            // Sort By Section
            _buildFilterSection('Sort by', [
              _buildRadioButton('Highest Rating', 1, _controller.selectedSort),
              _buildRadioButton('Most Reviews', 2, _controller.selectedSort),
              _buildRadioButton(
                'Recently Favorited',
                3,
                _controller.selectedSort,
              ),
            ]),

            SizedBox(height: 20),

            // Apply and Reset Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomButton(
                  text: 'Reset',
                  _controller.resetFilters,
                  color: Color(0xFFD0D5DA),
                ),
                CustomButton(text: 'Apply', () {
                  // Apply logic here
                  Navigator.pop(context);
                }, color: Color(0xFF246595)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build sections
  Widget _buildFilterSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: title,
          fontSize: 14,
          weight: FontWeight.w500,
          color: Colors.black,
        ),
        SizedBox(height: 8),
        Column(children: children),
        SizedBox(height: 16),
      ],
    );
  }

  // Helper method to create checkbox for categories
  Widget _buildCheckbox(
    String label,
    RxList<String> selectedValues,
    String value,
  ) {
    return Obx(() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Checkbox(
            value: selectedValues.contains(value),
            onChanged: (isChecked) {
              if (isChecked!) {
                selectedValues.add(value);
              } else {
                selectedValues.remove(value);
              }
            },
          ),
          CustomText(
            text: label,
            fontSize: 14,
            weight: FontWeight.w400,
            color: Colors.black,
          ),
        ],
      );
    });
  }

  // Helper method to create radio button for rating and sort by sections
  Widget _buildRadioButton(String label, int value, RxInt selectedValue) {
    return Obx(() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<int>(
            value: value,
            groupValue: selectedValue.value,
            onChanged: (newValue) {
              selectedValue.value = newValue!;
            },
          ),
          CustomText(
            text: label,
            fontSize: 14,
            weight: FontWeight.w400,
            color: Colors.black,
          ),
        ],
      );
    });
  }
}

class FavoriteFilterController extends GetxController {
  // Reactive variables for filter states
  RxList<String> selectedCategories = <String>[].obs;
  RxInt selectedRating = 0.obs;
  RxInt selectedSort = 0.obs;

  // Reset the filters to default state
  void resetFilters() {
    selectedCategories.clear();
    selectedRating.value = 0;
    selectedSort.value = 0;
  }
}
