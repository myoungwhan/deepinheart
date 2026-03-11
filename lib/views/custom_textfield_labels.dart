// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pattern_formatter/pattern_formatter.dart';
import 'package:deepinheart/views/text_styles.dart';

import 'colors.dart';

class CustomTextFieldLabels extends StatefulWidget {
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
  var fillColor;

  TextInputFormatter? formate;

  CustomTextFieldLabels(
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
      this.fillColor,
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
      this.validator});

  @override
  State<CustomTextFieldLabels> createState() => _CustomTextFieldLabelsState();
}

class _CustomTextFieldLabelsState extends State<CustomTextFieldLabels> {
  bool iserror = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          obscureText: widget.isObscure != null ? widget.isObscure! : false,
          keyboardType: widget.keyboard ?? TextInputType.text,
          maxLines: widget.keyboard == TextInputType.multiline
              ? widget.maxLines ?? 6
              : 1,
          readOnly: widget.readOnly ?? false,
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

              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black)),
              border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey)),

              //   filled: true,
              contentPadding: EdgeInsets.only(
                  top: widget.keyboard == TextInputType.multiline ? 13 : 3,
                  bottom: 3,
                  right: 15,
                  left: 15),
              focusColor: Colors.black,
              hoverColor: Colors.black,
              alignLabelWithHint: true,
              floatingLabelAlignment: FloatingLabelAlignment.start,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              fillColor: Color(0xffF4F4F4),
              filled: true,
              hintText: widget.hint,
              labelText: widget.text ?? "",
              suffixIcon: widget.suffix ?? null,
              prefixIcon: widget.prefix ?? null,
              hintStyle: TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey,
                  fontWeight: FontWeight.normal)),
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
