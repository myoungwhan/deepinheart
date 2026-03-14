import 'dart:convert';
import 'package:deepinheart/Controller/Viewmodel/loading_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/screens/counselor/views/dialogs/message_alert_dialog.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_button.dart';
import 'package:deepinheart/views/custom_textfiled.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:provider/provider.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({Key? key}) : super(key: key);

  @override
  _ChangePasswordDialogState createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // Password visibility states
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      // Check if current password is correct
      if (_currentCtrl.text.isEmpty) {
        // Get.snackbar(
        //   'Error',
        //   'Please enter your current password',
        //   backgroundColor: Colors.red,
        //   colorText: Colors.white,
        // );
        Get.dialog(
          MessageAlertDialog(
            title: 'Error',
            message: 'Please enter your current password',
          ),
        );
        return;
      }

      // Check if new password and confirm password match
      if (_newCtrl.text != _confirmCtrl.text) {
        Get.dialog(
          MessageAlertDialog(
            title: 'Error',
            message: 'New passwords do not match',
          ),
        );

        return;
      }

      // Check if new password is different from current password
      if (_currentCtrl.text == _newCtrl.text) {
        Get.dialog(
          MessageAlertDialog(
            title: 'Error',
            message: 'New password must be different from current password',
          ),
        );

        return;
      }

      final userViewModel = context.read<UserViewModel>();

      try {
        // Show loading state
        context.read<LoadingProvider>().showLoading();

        // Call the API to change password
        final result = await userViewModel.changePassword(
          currentPassword: _currentCtrl.text,
          newPassword: _newCtrl.text,
          newPasswordConfirmation: _confirmCtrl.text,
        );

        if (result['success']) {
          // Show success message
          Get.dialog(
            MessageAlertDialog(
              title: 'Success',
              message: result['message'] ?? 'Password changed successfully!',
            ),
          );

          // Clear form
          _currentCtrl.clear();
          _newCtrl.clear();
          _confirmCtrl.clear();

          // Reset visibility states
          setState(() {
            _isCurrentPasswordVisible = false;
            _isNewPasswordVisible = false;
            _isConfirmPasswordVisible = false;
          });

          // Close dialog
          Get.back();
        } else {
          // Show error message
          print(result.toString());
          Get.dialog(
            MessageAlertDialog(
              title: 'Error',
              message: jsonDecode(result['error'])['message'],
            ),
          );
        }
      } catch (e) {
        print('Error changing password: $e');
        Get.dialog(
          MessageAlertDialog(
            title: 'Error',
            message: 'Failed to change password: $e',
          ),
        );
      } finally {
        // Hide loading state
        context.read<LoadingProvider>().hideLoading();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: CustomText(
        text: 'Password change'.tr,

        fontSize: 18,
        weight: FontWeight.w600,
        // color: Colors.black,
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 20),

      content: SizedBox(
        width: Get.width * 0.8,

        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Customtextfield(
                  controller: _currentCtrl,
                  required: true,
                  hint: 'Enter the current password'.tr,
                  text: 'Current password'.tr,
                  prefix: Icon(Icons.lock_outline),
                  isObscure: !_isCurrentPasswordVisible,
                  showPasswordToggle: true,
                  keyboard: TextInputType.text,
                  suffix: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                      });
                    },
                    child: Icon(
                      _isCurrentPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: greyColor,
                      size: 20.w,
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Please enter your current password";
                    }
                    return null;
                  },
                ),
                UIHelper.verticalSpaceSm,

                Customtextfield(
                  controller: _newCtrl,
                  required: true,
                  hint: 'Enter a new password'.tr,
                  text: 'New password'.tr,
                  prefix: Icon(Icons.lock),
                  isObscure: !_isNewPasswordVisible,
                  showPasswordToggle: true,
                  keyboard: TextInputType.text,
                  suffix: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isNewPasswordVisible = !_isNewPasswordVisible;
                      });
                    },
                    child: Icon(
                      _isNewPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: greyColor,
                      size: 20.w,
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Please enter a new password";
                    } else if (value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),
                UIHelper.verticalSpaceSm5,
                CustomText(
                  text:
                      'English, numbers, special character combination 8-20 character'
                          .tr,
                  fontSize: 12,
                  weight: FontWeight.w400,
                  color: Colors.black54,
                ),
                UIHelper.verticalSpaceMd,

                Customtextfield(
                  controller: _confirmCtrl,
                  required: true,
                  hint: 'New password re - entry'.tr,
                  text: 'Check the new password'.tr,
                  prefix: Icon(Icons.lock_outline),
                  isObscure: !_isConfirmPasswordVisible,
                  showPasswordToggle: true,
                  keyboard: TextInputType.text,
                  suffix: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                    child: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: greyColor,
                      size: 20.w,
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Please confirm your new password";
                    } else if (value != _newCtrl.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
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
                      }, text: 'change'.tr),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
