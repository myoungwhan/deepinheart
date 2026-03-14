import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PopularLaberView extends StatelessWidget {
  String text;
  PopularLaberView({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        child: SizedBox(
          width: Get.width,
          child: CustomText(
            text: text,

            color: const Color(0xFF1F2937),
            fontSize: FontConstants.font_16,

            weight: FontWeightConstants.bold,
            align: TextAlign.center,
            height: 1.40,
          ),
        ),
      ),
    );
  }
}
