import 'package:deepinheart/Controller/Model/freq_question_model.dart';
import 'package:deepinheart/services/translation_service.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class FreqQuestionTile extends StatefulWidget {
  FreqQuestionModel model;
  FreqQuestionTile({Key? key, required this.model}) : super(key: key);

  @override
  _FreqQuestionTileState createState() => _FreqQuestionTileState();
}

class _FreqQuestionTileState extends State<FreqQuestionTile> {
  bool isExpanded = false;
  String translatedQuestion = '';
  String translatedAnswer = '';

  @override
  void initState() {
    super.initState();
    TranslationService translationService = TranslationService();
    translationService.translate(widget.model.qestion).then((value) {
      setState(() {
        translatedQuestion = value;
      });
    });
    translationService.translate(widget.model.ans).then((value) {
      setState(() {
        translatedAnswer = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width,
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            isExpanded = !isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      text: translatedQuestion,
                      weight: FontWeightConstants.medium,
                      fontSize: FontConstants.font_14,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: primaryColor,
                    size: 24.w,
                  ),
                ],
              ),
              if (isExpanded) ...[
                SizedBox(height: 12.h),
                CustomText(
                  text: translatedAnswer ?? '',
                  weight: FontWeightConstants.regular,
                  fontSize: FontConstants.font_13,
                  color: lightGREY,
                  height: 1.5,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
