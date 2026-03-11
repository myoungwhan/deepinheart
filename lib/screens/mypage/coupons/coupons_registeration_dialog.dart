import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/views/custom_button.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/custom_textfiled.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class CouponsRegisterationDialog extends StatefulWidget {
  const CouponsRegisterationDialog({Key? key}) : super(key: key);

  @override
  State<CouponsRegisterationDialog> createState() =>
      _CouponsRegisterationDialogState();
}

class _CouponsRegisterationDialogState
    extends State<CouponsRegisterationDialog> {
  final TextEditingController _couponCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _couponCodeController.dispose();
    super.dispose();
  }

  Future<void> _registerCoupon() async {
    if (_couponCodeController.text.trim().isEmpty) {
      Get.snackbar(
        'Error'.tr,
        'Please enter a coupon code'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final result = await userViewModel.registerCoupon(
      _couponCodeController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      Get.back();
      Get.snackbar(
        'Success'.tr,
        result['message'] ?? 'Coupon registered successfully'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error'.tr,
        result['message'] ?? 'Failed to register coupon'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: CustomText(
        text: "Coupon registration".tr,
        fontSize: FontConstants.font_18,
        weight: FontWeightConstants.bold,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.all(20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Customtextfield(
            required: true,
            controller: _couponCodeController,
            hint: "Please enter the coupon code".tr,
            text: "Coupon code".tr,
          ),
          UIHelper.verticalSpaceMd,
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  () {
                    if (!_isLoading) {
                      Get.back();
                    }
                  },
                  text: "Cancel".tr,
                  isCancelButton: true,
                ),
              ),
              UIHelper.horizontalSpaceSm,
              Expanded(
                child:
                    _isLoading
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                        : CustomButton(
                          _registerCoupon,
                          text: "Registration".tr,
                          isCancelButton: false,
                        ),
              ),
            ],
          ),
          UIHelper.verticalSpaceMd,
        ],
      ),
    );
  }
}
