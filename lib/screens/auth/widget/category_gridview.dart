// category_grid.dart
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:flutter/material.dart';

class CategoryGrid<T> extends StatelessWidget {
  final List<T> categories;
  final List<T> selected;
  final String Function(T) labelBuilder;
  final void Function(T) onSelected;
  final Color primaryColor;

  const CategoryGrid({
    super.key,
    required this.categories,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(child: Text("No data found"));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // like your design
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.5, // pill shape
      ),
      itemBuilder: (context, index) {
        final item = categories[index];
        final isSel = selected.contains(item);

        return InkWell(
          onTap: () => onSelected(item),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: isSel ? primaryColor.withAlpha(30) : Colors.white,
              border: Border.all(width: 1, color: const Color(0xFFD0D5DA)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomText(
                    text: labelBuilder(item),
                    fontSize: FontConstants.font_12,
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  isSel ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSel ? primaryColor : Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
