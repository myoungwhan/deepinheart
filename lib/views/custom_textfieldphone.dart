import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';

import '../Views/text_styles.dart';
import '../views/colors.dart';

class CustomTextFieldPhone extends StatefulWidget {
  final String? hint;
  final String? text;
  final TextEditingController? controller;
  final bool? isObscure;
  final Function(PhoneNumber)? onChanged;
  final FormFieldValidator<PhoneNumber>? validator;
  TextInputType? keyboard;
  FocusNode? focusNode;
  bool? isvalid;
  var suffix;
  bool? required;
  var fkey;
  CustomTextFieldPhone({
    this.controller,
    this.hint,
    this.isObscure,
    this.text,
    this.onChanged,
    this.focusNode,
    this.isvalid,
    this.fkey,
    this.suffix,
    required this.required,
    this.keyboard,
    this.validator,
  });

  @override
  State<CustomTextFieldPhone> createState() => _CustomTextFieldPhoneState();
}

class _CustomTextFieldPhoneState extends State<CustomTextFieldPhone> {
  bool iserror = false;
  bool _hasError = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.text != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.0),
                    child: CustomText(
                      text: widget.text,
                      fontSize: FontConstants.font_14,
                      weight: FontWeightConstants.medium,
                      color: Color(0xff374151),
                      height: 1.43,
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(left: 3.0.sp),
                    child: CustomText(
                      text: '*',
                      fontSize: FontConstants.font_14,
                      weight: FontWeightConstants.medium,
                      color: Colors.red,
                      height: 1.43,
                    ),
                  ),
                ],
              ),
            Container(
              width: MediaQuery.of(context).size.width,
              margin: EdgeInsets.symmetric(
                vertical: widget.text != null ? 8 : 0,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 0),
                child: IntlPhoneField(
                  key: widget.fkey,
                  initialCountryCode: 'KR',
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  obscureText:
                      widget.isObscure != null ? widget.isObscure! : false,
                  onChanged: widget.onChanged,
                  validator: (value) {
                    final error =
                        widget.validator != null
                            ? widget.validator!(value)
                            : _defaultValidator(value);
                    setState(() {
                      _hasError = error != null;
                    });
                    return error;
                  },
                  disableLengthCheck: true,
                  controller: widget.controller,
                  focusNode: widget.focusNode ?? null,
                  style: textStylemontserratRegular(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  showDropdownIcon: false,
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.05),
                    hintText: widget.hint,
                    alignLabelWithHint: true,
                    suffixIcon: widget.suffix,
                    floatingLabelAlignment: FloatingLabelAlignment.start,
                    contentPadding: EdgeInsets.symmetric(horizontal: 15),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    hintStyle: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String? _defaultValidator(PhoneNumber? value) {
    if (widget.required! && (value == null || value.number.isEmpty)) {
      return 'This field is required';
    }
    return null;
  }

  String? defaultValidator(value) {
    if (widget.hint == "Email") {
      if (!GetUtils.isEmail(widget.controller!.text)) {
        setState(() {
          iserror = true;
        });
      } else {
        setState(() {
          iserror = false;
        });
      }
    }
    return null;
  }
}
