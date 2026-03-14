import 'package:deepinheart/Controller/Viewmodel/loading_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:deepinheart/Controller/Viewmodel/api_client.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:deepinheart/screens/auth/login_View.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_appbar.dart';
import 'package:deepinheart/views/custom_button.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/custom_textfiled.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  TextEditingController emailController = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        UIHelper.hideKeyboard(context);
      },
      child: Scaffold(
        backgroundColor: whiteColor,
        appBar: customAppBar(
          title: "Forgot password".tr,
          isLogo: false,
          action: [UIHelper.horizontalSpaceMd],
        ),
        body: Container(
          width: Get.width,
          height: Get.height,
          padding: EdgeInsets.symmetric(horizontal: 20.r),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomText(
                    text: "Please enter your email to reset the password".tr,
                    color: Color(0xff989898),
                    height: 1.5,
                    fontSize: FontConstants.font_14,
                    weight: FontWeightConstants.medium,
                  ),
                  UIHelper.verticalSpaceMd,
                  Customtextfield(
                    required: true,
                    readOnly: false,
                    text: "Your Email".tr,
                    hint: "Enter your email".tr,
                    controller: emailController,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Please insert email".tr;
                      } else {
                        return null;
                      }
                    },
                  ),
                  UIHelper.verticalSpaceMd,
                  SizedBox(
                    width: Get.width,
                    child: CustomButton(
                      () async {
                        UIHelper.hideKeyboard(context);
                        if (!formKey.currentState!.validate()) {
                          return;
                        }
                        LoadingProvider provider =
                            context.read<LoadingProvider>();
                        provider.showLoading();

                        try {
                          final response = await ApiClient().request(
                            url: ApiEndPoints.FORGOT_PASSWORD,
                            method: "POST",
                            body: {"email": emailController.text},
                            context: context,
                          );

                          final success = response['success'] == true;
                          final message =
                              response['message']?.toString() ??
                              "Password reset link sent successfully.";
                          provider.hideLoading();

                          if (success) {
                            // Show success dialog and navigate to login
                            Get.back();
                            UIHelper.showDialogOk(
                              context,
                              title: "Success".tr,
                              message:
                                  "Password reset link sent successfully.".tr,
                              onOk: () {
                                // Navigate to login screen
                                Get.offAll(SignInScreen());
                              },
                            );
                          } else {
                            // Show error flash for failures
                            UIHelper.showBottomFlash(
                              context,
                              title: "Error".tr,
                              message: message,
                              isError: true,
                            );
                          }
                        } on ValidationException catch (e) {
                          // Show first email validation error if present
                          final emailErrors = e.errors['email'];
                          String errorMessage;
                          if (emailErrors is List && emailErrors.isNotEmpty) {
                            errorMessage = emailErrors.first.toString();
                          } else {
                            errorMessage = e.message;
                          }
                          provider.hideLoading();

                          UIHelper.showBottomFlash(
                            context,
                            title: "Error",
                            message: errorMessage,
                            isError: true,
                          );
                        } catch (e) {
                          provider.hideLoading();

                          UIHelper.showBottomFlash(
                            context,
                            title: "Error",
                            message: "Something went wrong. Please try again.",
                            isError: true,
                          );
                        }
                      },
                      text: "Reset Password".tr,

                      textcolor: whiteColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
