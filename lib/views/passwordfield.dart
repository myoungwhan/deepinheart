import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

import '../Views/text_styles.dart';
import 'colors.dart';

class PasswordField extends StatefulWidget {
  final String text;
  var controller;
  PasswordField({Key? key, required this.text, this.controller})
      : super(key: key);

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool visibility = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 50,
      margin: EdgeInsets.symmetric(vertical: 7),
      child: Card(
          margin: EdgeInsets.zero,
          elevation: 5,
          shape: RoundedRectangleBorder(
              // side: BorderSide(width: 1, color: whiteColor),
              borderRadius: BorderRadius.circular(5)),
          child: TextField(
            obscureText: visibility,
            keyboardType: TextInputType.text,
            controller: this.widget.controller,
            style: textStyleSegeoui(
                fontSize: 16, color: Colors.black, weight: FontWeight.w400),
            decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    const Radius.circular(5.0),
                  ),
                  borderSide: BorderSide(
                    width: 0,
                    style: BorderStyle.none,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                hintText: "Enter Password".tr,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: SvgPicture.asset(
                    "images/lock.svg",
                    color: Colors.black,
                    width: 10,
                  ),
                ),
                suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        visibility = !visibility;
                      });
                    },
                    icon: Icon(
                      visibility ? Icons.visibility : Icons.visibility_off,
                      color: Colors.black,
                    )

                    //const Icon(Icons.remove_red_eye, color: Colors.black,),
                    ),
                hintStyle: textStyleRobotoRegular(color: hintColor)),
          )),
    );
  }
}
