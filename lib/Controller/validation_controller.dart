import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ValidationController extends GetxController {
  RxString username = RxString('');
  RxString email = RxString('');
  RxString phone = RxString('');
  RxBool isPhonevalid = RxBool(false);
  RxBool isEmailvalid = RxBool(false);

  RxnString errorText = RxnString(null);
  Rxn<Function()> submitFunc = Rxn<Function()>(null);

  @override
  void onInit() {
    super.onInit();
    debounce<String>(email, validationEmail,
        time: const Duration(milliseconds: 500));
    debounce<String>(phone, validationPhone,
        time: const Duration(milliseconds: 500));

    // debounce<String>(username, validations, time: const Duration(milliseconds: 500));
  }

  void validationEmail(String val) async {
    errorText.value = null; // reset validation errors to nothing
    submitFunc.value = null; // disable submit while validating
    // if (val.isNotEmpty) {
    //   if (lengthOK(val) && await available(val)) {
    //     print('All validations passed, enable submit btn...');
    //     submitFunc.value = submitFunction();
    //     errorText.value = null;
    //   }
    // }
    if (GetUtils.isEmail(val)) {
      isEmailvalid.value = true;
      checkAllValidation();
    } else {
      isEmailvalid.value = false;
    }
  }

  void validationPhone(String val) async {
    errorText.value = null; // reset validation errors to nothing
    submitFunc.value = null; // disable submit while validating

    if (GetUtils.isPhoneNumber(val)) {
      isPhonevalid.value = true;
      checkAllValidation();
    } else {
      isPhonevalid.value = false;
    }
  }

  void checkAllValidation() {
    if (isPhonevalid.value && isEmailvalid.value) {
      submitFunc.value = submitFunction();
      errorText.value = null;
    }
  }

  bool lengthOK(String val, {int minLen = 5}) {
    if (val.length < minLen) {
      errorText.value = 'min. 5 chars';
      return false;
    }
    return true;
  }

  Future<bool> available(String val) async {
    print('Query availability of: $val');
    await Future.delayed(
        const Duration(seconds: 1), () => print('Available query returned'));

    if (val == "Sylvester") {
      errorText.value = 'Name Taken';
      return false;
    }
    return true;
  }

  void usernameChanged(String val) {
    username.value = val;
  }

  void emailChanged(String val) {
    email.value = val;
  }

  void phoneChanged(String val) {
    phone.value = val;
  }

  Future<bool> Function() submitFunction() {
    return () async {
      print('Make database call to create ${username.value} accountkk');
      await Future.delayed(const Duration(seconds: 1), () {});
      return true;
    };
  }
}
