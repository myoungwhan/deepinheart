import 'package:deepinheart/views/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomSelectionChip extends StatelessWidget {
  final List<String> chips;
  final String selectedChip;
  final ValueChanged<String> onSelected;

  const CustomSelectionChip({
    Key? key,
    required this.chips,
    required this.selectedChip,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (_, i) {
          String chip = chips[i];
          bool isSelected = chip == selectedChip;
          return ChoiceChip(
            label: Text(
              chip.tr,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (selected) {
              onSelected(selected ? chip : 'All');
            },
            selectedColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: BorderSide(width: 0.0, color: Colors.transparent),
            ),
            backgroundColor: Color(0xffF3F4F6),
          );
        },
        separatorBuilder: (_, __) => SizedBox(width: 8),
        itemCount: chips.length,
      ),
    );
  }
}
