import 'package:flutter/material.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:get/get.dart';

class CharginBenifitGuide extends StatelessWidget {
  /// The heading at the top, e.g. "Charging Benefits Guide"
  final String heading;

  /// A short subtitle under the heading, e.g. "Get Additional 10% Coins..."
  final String subtitle;

  /// A list of detail lines (each line will get a bullet icon)
  final List<String> details;
  Color cardColor;

  CharginBenifitGuide({
    Key? key,
    required this.heading,
    required this.subtitle,
    required this.details,
    required this.cardColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width,
      padding: const EdgeInsets.all(17),
      decoration: ShapeDecoration(
        color: cardColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: const Color(0xFFFEF08A)),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading
          CustomText(
            text: heading,
            fontSize: 14,
            weight: FontWeight.w500,
            color: const Color(0xFF1F2937),
          ),
          const SizedBox(height: 8),

          // Subtitle
          const SizedBox(height: 12),

          // Details list
          ...details.map((line) => _buildBullet(line)).toList(),
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // bullet icon (you can replace with your own asset/icon)
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF374050),
            ),
          ),
          const SizedBox(width: 8),

          // the text
          Expanded(
            child: CustomText(
              text: text,
              fontSize: 12,
              weight: FontWeight.w400,
              color: const Color(0xFF374050),
              height: 1.33,
            ),
          ),
        ],
      ),
    );
  }
}
