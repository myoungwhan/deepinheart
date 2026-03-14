import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_button.dart';
import 'package:deepinheart/views/custom_textfiled.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/ui_helpers.dart';

class DeleteAccountDialog extends StatefulWidget {
  final Future<void> Function(String password) onWithdraw;

  const DeleteAccountDialog({Key? key, required this.onWithdraw})
    : super(key: key);

  @override
  _DeleteAccountDialogState createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  bool _agreed = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      UIHelper.showBottomFlash(
        context,
        title: 'Error'.tr,
        message: 'You must agree before withdrawal'.tr,
        isError: true,
      );
      return;
    }
    await widget.onWithdraw(_passwordCtrl.text);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.fromLTRB(24, 24, 24, 0),
      insetPadding: EdgeInsets.symmetric(horizontal: 15),

      title: Column(
        children: [
          CustomText(
            text: 'Membership withdrawal'.tr,
            fontSize: 18,
            weight: FontWeight.w600,
            color: Colors.black,
          ),
          UIHelper.verticalSpaceSm,
          CustomText(
            text:
                'All your personal information is deleted and cannot be recovered when you withdraw.'
                    .tr,
            fontSize: 14,
            weight: FontWeight.w400,
            color: Colors.grey[700]!,
            align: TextAlign.center,
          ),
        ],
      ),
      contentPadding: EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: Get.width * 0.8,

        child: SingleChildScrollView(
          child: Column(
            children: [
              // Warning box
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFFFEBEB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: '• All coins and coupons are destroyed.'.tr,
                      fontSize: 14,
                      weight: FontWeight.w400,
                      color: Colors.red,
                    ),
                    UIHelper.verticalSpaceSm,
                    CustomText(
                      text:
                          '• Consultation history and payment information will be deleted.'
                              .tr,
                      fontSize: 14,
                      weight: FontWeight.w400,
                      color: Colors.red,
                    ),
                    UIHelper.verticalSpaceSm5,
                    CustomText(
                      text:
                          '• The connected social account information is deleted.'
                              .tr,
                      fontSize: 14,
                      weight: FontWeight.w400,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),

              UIHelper.verticalSpaceMd,

              // Password field
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: 'verify password'.tr,
                      fontSize: 14,
                      weight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    UIHelper.verticalSpaceSm5,
                    Customtextfield(
                      controller: _passwordCtrl,
                      required: true,
                      hint: 'Enter your password'.tr,
                      text: '',
                      prefix: Icon(Icons.lock_outline),
                      isObscure: true,
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? 'Please enter password'.tr
                                  : null,
                    ),
                  ],
                ),
              ),

              UIHelper.verticalSpaceMd,

              // Agreement checkbox
              Row(
                children: [
                  Checkbox(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v!),
                  ),
                  Expanded(
                    child: CustomText(
                      text:
                          'We have confirmed the above and agree to withdraw.'
                              .tr,
                      fontSize: 14,
                      weight: FontWeight.w400,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              UIHelper.verticalSpaceMd,
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      () {
                        Get.back();
                      },
                      text: 'cancellation'.tr,
                      isCancelButton: true,
                    ),
                  ),

                  SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(() {
                      _submit();
                      Get.back();
                    }, text: 'Withdrawal'.tr),
                  ),
                ],
              ),
              UIHelper.verticalSpaceMd,
            ],
          ),
        ),
      ),
    );
  }
}
