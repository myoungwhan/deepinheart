import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:deepinheart/Controller/Model/service_category_model.dart';
import 'package:deepinheart/Controller/Model/texnomy_model.dart';
import 'package:deepinheart/Views/colors.dart';
import 'package:deepinheart/main.dart';
import 'package:deepinheart/services/translation_helper.dart';
import 'package:deepinheart/services/translation_service.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceCategoryCard extends StatefulWidget {
  Category model;
  bool isActive;
  var callBack;
  double? fSize;
  ServiceCategoryCard({
    required this.model,
    required this.isActive,
    this.callBack,
    this.fSize,
    Key? key,
  }) : super(key: key);

  @override
  State<ServiceCategoryCard> createState() => _ServiceCategoryCardState();
}

class _ServiceCategoryCardState extends State<ServiceCategoryCard> {
  TranslationService translationService = TranslationService();
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.callBack(widget.model);
        });
      },
      child: Card(
        elevation: 0.5,
        color: isMainDark ? Colors.white : null,
        shape: RoundedRectangleBorder(
          side:
              !widget.isActive
                  ? BorderSide.none
                  : BorderSide(width: 0.5, color: primaryColor),

          borderRadius: BorderRadius.circular(5.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              //   constraints: BoxConstraints(maxWidth: 124),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(widget.model.image),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 7),
              child: Center(
                child: CustomText(
                  text: widget.model.name,
                  fontSize: widget.fSize ?? FontConstants.font_14,
                  maxlines: 2,
                  color: isMainDark ? Colors.black : Colors.black,
                  align: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
