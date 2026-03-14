import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pattern_formatter/pattern_formatter.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/text_styles.dart';

// Korean Phone Number Formatter
class KoreanPhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digit characters
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Limit to 11 digits (Korean mobile numbers)
    if (digitsOnly.length > 11) {
      digitsOnly = digitsOnly.substring(0, 11);
    }

    // Format Korean phone number
    String formatted = _formatKoreanPhoneNumber(digitsOnly);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatKoreanPhoneNumber(String digitsOnly) {
    if (digitsOnly.length <= 3) {
      return digitsOnly;
    } else if (digitsOnly.length <= 7) {
      return '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3)}';
    } else if (digitsOnly.length <= 11) {
      return '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 7)}-${digitsOnly.substring(7)}';
    } else {
      return '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 7)}-${digitsOnly.substring(7)}';
    }
  }
}

class Customtextfield extends StatefulWidget {
  final String? hint;
  final String? text;
  final TextEditingController? controller;
  final bool? isObscure;
  final Function(String)? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboard;
  final FocusNode? focusNode;
  final bool? isvalid;
  final Widget? suffix;
  final bool required;
  final int? maxLines;
  final bool? readOnly;
  final double? fontSize;
  final VoidCallback? onTap;
  final String? egText;
  final double? border;
  final double? fieldWidth;
  final double? height;
  final Widget? prefix;
  final double? elevation;
  final TextInputFormatter? formate;
  final CrossAxisAlignment? mainCrossAlignment;
  final TextAlign? textalign;
  final bool? showPasswordToggle;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;
  final Function(String)? onSubmitted;
  final AutovalidateMode? autovalidateMode;

  Customtextfield({
    Key? key,
    this.controller,
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
    this.elevation,
    this.mainCrossAlignment,
    this.textalign,
    this.validator,
    this.showPasswordToggle = false,
    this.borderColor = Colors.grey,
    this.focusedBorderColor = primaryColor,
    this.errorBorderColor = Colors.red,
    this.onSubmitted,
    this.autovalidateMode,
  }) : super(key: key);

  @override
  State<Customtextfield> createState() => _CustomtextfieldState();
}

class _CustomtextfieldState extends State<Customtextfield> {
  bool _obscureText = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isObscure ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: widget.mainCrossAlignment ?? CrossAxisAlignment.start,
      children: [
        if (widget.text != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CustomText(
                  text: widget.text,
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.medium,
                  color: Get.isDarkMode ? Colors.white : Color(0xff374151),
                  height: 1.43,
                ),
                if (widget.required)
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
          ),
        Container(
          width: widget.fieldWidth ?? MediaQuery.of(context).size.width,
          margin: EdgeInsets.symmetric(vertical: widget.text != null ? 8 : 0),
          child: TextFormField(
            obscureText: _obscureText,
            keyboardType: widget.keyboard ?? TextInputType.text,
            autovalidateMode:
                widget.autovalidateMode ?? AutovalidateMode.disabled,
            onSaved: (value) => widget.onSubmitted!(value!),
            maxLines:
                widget.keyboard == TextInputType.multiline
                    ? widget.maxLines ?? 6
                    : 1,
            readOnly: widget.readOnly ?? false,
            controller: widget.controller,

            onChanged: (value) {
              setState(() {
                _hasError = false;
              });
              if (widget.onChanged != null) {
                widget.onChanged!(value);
              }
            },
            onTap: widget.onTap,

            focusNode: widget.focusNode,
            validator: (value) {
              final error =
                  widget.validator != null
                      ? widget.validator!(value)
                      : _defaultValidator(value);
              // Use post-frame callback to avoid setState during build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _hasError = error != null;
                  });
                }
              });
              return error;
            },
            // inputFormatters: [
            //   widget.formate ??
            //       (widget.keyboard == TextInputType.phone
            //           ? KoreanPhoneNumberFormatter()
            //           : widget.keyboard == TextInputType.number ||
            //               widget.keyboard ==
            //                   TextInputType.numberWithOptions(decimal: true)
            //           ? ThousandsFormatter(allowFraction: true)
            //           : TextInputFormatter.withFunction(
            //             (oldValue, newValue) => newValue,
            //           )),
            // ],
            style: textStyleRobotoRegular(
              fontSize: FontConstants.font_14,
              color: Get.isDarkMode ? Colors.white : Colors.black,
              weight: FontWeightConstants.medium,
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                vertical: widget.keyboard == TextInputType.multiline ? 13 : 12,
                horizontal: 16,
              ),
              filled: true,
              fillColor:
                  Get.isDarkMode
                      ? Colors.white10
                      : Colors.grey.withOpacity(0.05),
              hintText:
                  widget.keyboard == TextInputType.phone
                      ? (widget.hint ?? "010-1234-5678")
                      : widget.hint,
              hintStyle: textStyleRobotoRegular(
                fontSize: FontConstants.font_14,
                color: Get.isDarkMode ? Colors.grey[400] : Colors.grey,
                weight: FontWeightConstants.regular,
              ),
              border: _buildBorder(),
              enabledBorder: _buildBorder(),
              focusedBorder: _buildBorder(isFocused: true),
              errorBorder: _buildBorder(isError: true),
              focusedErrorBorder: _buildBorder(isError: true, isFocused: true),

              helper:
                  widget.egText != null
                      ? Container(
                        transform: Matrix4.translationValues(-10, 3, 0),
                        child: CustomText(
                          text: widget.egText,
                          fontSize: FontConstants.font_12,
                          color:
                              Get.isDarkMode ? Colors.grey[400] : Colors.grey,
                          weight: FontWeightConstants.regular,
                          height: 1.33,
                        ),
                      )
                      : null,
              suffixIcon:
                  widget.showPasswordToggle! && widget.isObscure!
                      ? IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color:
                              Get.isDarkMode ? Colors.grey[400] : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      )
                      : widget.suffix,
              prefixIcon: widget.prefix,
            ),
          ),
        ),
      ],
    );
  }

  InputBorder _buildBorder({bool isFocused = false, bool isError = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.border ?? 7.0),
      borderSide: BorderSide(
        color:
            isError
                ? widget.errorBorderColor!
                : isFocused
                ? widget.focusedBorderColor!
                : widget.borderColor!,
        width: isFocused ? 1.5 : 1,
      ),
    );
  }

  String? _defaultValidator(String? value) {
    if (widget.required && (value == null || value.isEmpty)) {
      return 'This field is required';
    }
    return null;
  }
}
