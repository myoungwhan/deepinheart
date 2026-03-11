// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pattern_formatter/pattern_formatter.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/text_styles.dart';

import 'colors.dart';

class CustomTextFieldUnderline extends StatefulWidget {
  final String? hint;
  final String? text;
  final TextEditingController? controller;
  final bool? isObscure;
  final Function(String)? onChanged;
  final FormFieldValidator<String>? validator;
  TextInputType? keyboard;
  FocusNode? focusNode;
  bool? isvalid;
  var suffix;
  bool? required;
  int? maxLines;
  var readOnly;
  var fontSize;
  var onTap;
  var egText;
  var border;
  var fieldWidth;
  var height;
  var prefix;
  var bordercolr;
  var borderWidth;
  var textSize;

  TextInputFormatter? formate;

  CustomTextFieldUnderline(
      {this.controller,
      this.hint,
      this.isObscure,
      this.text,
      this.onChanged,
      this.focusNode,
      this.isvalid,
      this.suffix,
      required this.required,
      this.keyboard,
      this.maxLines,
      this.readOnly,
      this.fontSize,
      this.onTap,
      this.egText,
      this.border,
      this.formate,
      this.fieldWidth,
      this.height,
      this.prefix,
      this.borderWidth,
      this.bordercolr,
      this.textSize,
      this.validator});

  @override
  State<CustomTextFieldUnderline> createState() =>
      _CustomTextFieldUnderlineState();
}

class _CustomTextFieldUnderlineState extends State<CustomTextFieldUnderline> {
  bool iserror = false;
  bool isReadOnly = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      isReadOnly = widget.readOnly ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.text != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.0),
                      child: CustomText(
                        text: widget.text,
                        fontSize: widget.textSize ?? 20.0,
                        isSemibold: true,
                      )),
                  InkWell(
                    onTap: () {
                      setState(() {
                        isReadOnly = !isReadOnly;
                      });
                    },
                    child: SvgPicture.asset(
                      AppIcons.editSvg,
                      width: 20.0,
                    ),
                  )
                ],
              )
            : Container(),
        Container(
          width: widget.fieldWidth ?? MediaQuery.of(context).size.width,
          //    height: widget.height ?? 45.0,
          // height: widget.keyboard == TextInputType.multiline
          //     ? widget.maxLines != null
          //         ? 50 * widget.maxLines!.toDouble()
          //         : 200
          //     : 50,
          margin: EdgeInsets.symmetric(vertical: widget.text != null ? 0 : 0),
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 0),
              child: TextFormField(
                obscureText:
                    widget.isObscure != null ? widget.isObscure! : false,
                keyboardType: widget.keyboard ?? TextInputType.text,
                maxLines: widget.keyboard == TextInputType.multiline
                    ? widget.maxLines ?? null
                    : 1,
                readOnly: isReadOnly,
                controller: this.widget.controller,
                onChanged: widget.onChanged,
                onTap: widget.onTap,
                focusNode: widget.focusNode ?? null,
                validator: widget.required!
                    ? widget.validator != null
                        ? widget.validator
                        : defaultValidator
                    : null,
                inputFormatters: [
                  widget.keyboard == TextInputType.number ||
                          widget.keyboard ==
                              TextInputType.numberWithOptions(decimal: true)
                      ? ThousandsFormatter(allowFraction: true)
                      : TextInputFormatter.withFunction(
                          (oldValue, newValue) => newValue)
                ],
                style: textStyleSegeoui(
                    fontSize: 16, color: Colors.black, weight: FontWeight.w400),
                decoration: InputDecoration(
                    // label: widget.text != null
                    //     ? Text(widget.text!)
                    //     : Container(),
                    //   alignLabelWithHint: true,

                    contentPadding: EdgeInsets.only(
                        top:
                            widget.keyboard == TextInputType.multiline ? 13 : 3,
                        bottom: 5,
                        right: 5,
                        left: 5),
                    focusColor: Colors.black,
                    hoverColor: Colors.black,
                    filled: false,
                    fillColor: Colors.grey[200],
                    hintText: widget.hint,
                    suffixIcon: widget.suffix ?? null,
                    prefixIcon: widget.prefix ?? null,
                    hintStyle: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey,
                        fontWeight: FontWeight.normal)),
              )),
        ),
        widget.egText != null
            ? Row(
                children: [
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text(
                      widget.egText!,
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14.0,
                          fontWeight: FontWeight.normal),
                    ),
                  ),
                ],
              )
            : Container()
      ],
    );
  }

  String? defaultValidator(value) {
    if (value == null || value.isEmpty) {
      return 'Please enter some text';
    }
    return null;
  }
}
