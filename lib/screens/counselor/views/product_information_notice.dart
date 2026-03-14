import 'package:deepinheart/screens/home/widget/sub_category_chip.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class InfoItem {
  final String label;
  final String value;
  final VoidCallback? onViewDetails;
  InfoItem({required this.label, required this.value, this.onViewDetails});
}

class InfoTable extends StatelessWidget {
  final List<InfoItem> items;
  const InfoTable({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children:
            items.map((item) {
              final isLast = items.indexOf(item) == items.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // Left column (label)
                    Expanded(
                      flex: 4,
                      child: CustomText(
                        text: item.label,
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),

                    // Right column (value + optional View Details)
                    Expanded(
                      flex: 6,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomText(
                              text: item.value,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          UIHelper.horizontalSpaceSm5,
                          if (item.onViewDetails != null)
                            GestureDetector(
                              onTap: item.onViewDetails,
                              child: SubCategoryChip(
                                text: 'View Details'.tr,
                                color: primaryColorConsulor,
                                fontSize: FontConstants.font_13,
                                height: 25.0.h,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}
