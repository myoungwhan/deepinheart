import 'dart:convert';

import 'package:deepinheart/Controller/Viewmodel/loading_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/services/translation_service.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_button.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/custom_textfiled.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({Key? key}) : super(key: key);

  @override
  _ChangePasswordViewState createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  // Form controllers
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Form state
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Change Password Card
            _buildChangePasswordCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildChangePasswordCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            CustomText(
              text: "Change Password".tr,
              fontSize: FontConstants.font_18,
              weight: FontWeightConstants.bold,
              color: Colors.black,
            ),
            UIHelper.verticalSpaceMd,

            // Current Password Field
            Customtextfield(
              controller: _currentPasswordController,
              required: true,
              hint: "Enter your current password".tr,
              text: "Current Password".tr,
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
                  return "Please enter your current password".tr;
                }
                return null;
              },
            ),
            UIHelper.verticalSpaceMd,

            // New Password Field
            Customtextfield(
              controller: _newPasswordController,
              required: true,
              hint: "Enter new password".tr,
              text: "New Password".tr,
              showPasswordToggle: true,

              isObscure: !_isNewPasswordVisible,
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
                  return "Please enter a new password".tr;
                } else if (value.length < 6) {
                  return "Password must be at least 6 characters".tr;
                }
                return null;
              },
            ),
            UIHelper.verticalSpaceMd,

            // Confirm New Password Field
            Customtextfield(
              controller: _confirmPasswordController,
              required: true,
              hint: "Enter new password again".tr,
              text: "Confirm New Password".tr,
              showPasswordToggle: true,

              isObscure: !_isConfirmPasswordVisible,
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
                  return "Please confirm your new password".tr;
                } else if (value != _newPasswordController.text) {
                  return "Passwords do not match".tr;
                }
                return null;
              },
            ),
            UIHelper.verticalSpaceMd,

            // Change Button
            CustomButton(
              _changePassword,
              text: "Change".tr,
              color: primaryColorConsulor,
              textcolor: Colors.white,
              fsize: FontConstants.font_16,
              weight: FontWeightConstants.medium,
            ),
          ],
        ),
      ),
    );
  }

  void _changePassword() async {
    if (_formKey.currentState!.validate()) {
      // Check if current password is correct (you would validate against your backend)
      if (_currentPasswordController.text.isEmpty) {
        Get.snackbar(
          'Error'.tr,
          'Please enter your current password'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Check if new password and confirm password match
      if (_newPasswordController.text != _confirmPasswordController.text) {
        Get.snackbar(
          'Error'.tr,
          'New passwords do not match'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Check if new password is different from current password
      if (_currentPasswordController.text == _newPasswordController.text) {
        Get.snackbar(
          'Error'.tr,
          'New password must be different from current password'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final userViewModel = context.read<UserViewModel>();

      try {
        // Show loading state
        context.read<LoadingProvider>().showLoading();

        // Call the API to change password
        final result = await userViewModel.changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
          newPasswordConfirmation: _confirmPasswordController.text,
        );

        if (result['success']) {
          // Show success message
          String message = await translationService.translate(
            result['message'],
          );

          Get.snackbar(
            'Success'.tr,
            message ?? 'Password changed successfully!'.tr,
            backgroundColor: greenColor,
            colorText: Colors.white,
          );

          // Clear form
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();

          // Reset visibility states
          setState(() {
            _isCurrentPasswordVisible = false;
            _isNewPasswordVisible = false;
            _isConfirmPasswordVisible = false;
          });
        } else {
          // Show error message
          print(result.toString());
          String message = await translationService.translate(
            jsonDecode(result['error'])['message'],
          );
          Get.snackbar(
            'Error'.tr,
            message,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } catch (e) {
        print('Error changing password: $e');
        Get.snackbar(
          'Error'.tr,
          'Failed to change password: $e'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } finally {
        // Hide loading state
        context.read<LoadingProvider>().hideLoading();
      }
    }
  }
}
