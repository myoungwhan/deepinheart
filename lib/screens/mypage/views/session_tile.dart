import 'package:deepinheart/main.dart';
import 'package:flutter/material.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:get/get.dart';

class SessionTile extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String category;
  final String date;
  final String duration;
  final String description;
  final String method;
  const SessionTile({
    Key? key,
    required this.imageUrl,
    required this.name,
    required this.category,
    required this.date,
    required this.duration,
    required this.description,
    required this.method,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 0),
      padding: const EdgeInsets.all(14),
      width: Get.width,
      decoration: ShapeDecoration(
        color: isMainDark ? Color(0xff2C2C2E) : const Color(0xFFF9FAFB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.8),
          side: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Left: Avatar + Name & Category
              Expanded(
                child: Row(
                  children: [
                    // Avatar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        imageUrl,
                        width: 47,
                        height: 47,
                        fit: BoxFit.cover,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Name & Category
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          CustomText(
                            text: name,
                            fontSize: FontConstants.font_16,
                            weight: FontWeightConstants.medium,
                            color: isMainDark ? Colors.white : Colors.black,
                          ),
                          UIHelper.verticalSpaceSm,

                          // Category and Method Chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              // Category Chip
                              if (category.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDAE9FE),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: CustomText(
                                    text: category,
                                    fontSize: FontConstants.font_14,
                                    weight: FontWeightConstants.regular,
                                    color: const Color(0xFF1D4ED8),
                                  ),
                                ),
                              // Method Chip
                              if (method.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0E7FF),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: CustomText(
                                    text: method,
                                    fontSize: FontConstants.font_14,
                                    weight: FontWeightConstants.regular,
                                    color: const Color(0xFF6366F1),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Right: Date & Duration
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomText(
                    text: date,
                    fontSize: FontConstants.font_14,
                    weight: FontWeightConstants.regular,
                    color: const Color(0xFF6A7280),
                  ),
                  UIHelper.verticalSpaceSm5,
                  CustomText(
                    text: duration,
                    fontSize: FontConstants.font_14,
                    weight: FontWeightConstants.medium,
                    color: const Color(0xFF246595),
                  ),
                ],
              ),
            ],
          ),

          description == "" ? Container() : UIHelper.verticalSpaceSm,

          // Description
          description == ""
              ? Container()
              : CustomText(
                text: description,
                fontSize: FontConstants.font_14,
                weight: FontWeightConstants.regular,
                color: const Color(0xFF4A5462),
              ),
        ],
      ),
    );
  }
}
