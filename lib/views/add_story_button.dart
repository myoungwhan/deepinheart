import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/custom_text.dart';

class AddStoryButton extends StatelessWidget {
  const AddStoryButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SvgPicture.asset(
          AppIcons.addstorysvg,
          width: 60.0,
        ),
        CustomText(
          text: "Add\nStory",
          fontSize: 12.0,
          align: TextAlign.center,
        )
      ],
    );
  }
}
