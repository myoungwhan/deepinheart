import 'dart:io';
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
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/Controller/Viewmodel/loading_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/setting_provider.dart';

class PersonalView extends StatefulWidget {
  const PersonalView({Key? key}) : super(key: key);

  @override
  _PersonalViewState createState() => _PersonalViewState();
}

class _PersonalViewState extends State<PersonalView> {
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _suiteController = TextEditingController();
  final TextEditingController _introductionController = TextEditingController();

  // Form state
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _selectedGender = 'Male';
  File? _profileImage;
  final ImagePicker _imagePicker = ImagePicker();
  String? profileImageUrl;

  // Load user data from API
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  String _getProfileInitials() {
    final name = _nicknameController.text.trim().isNotEmpty
        ? _nicknameController.text.trim()
        : _nameController.text.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name[0].toUpperCase();
  }

  void _loadUserData() async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);

    // Check if userModel exists and has a token
    // if (userViewModel.userModel == null ||
    //     userViewModel.userModel!.data.token.isEmpty) {
    //   print('No user token available, using sample data');
    //   _loadSampleData();
    //   return;
    // }

    try {
      // Use WidgetsBinding to ensure we're not in build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        userViewModel.setLoading(true);
      });

      // Fetch user data from API
      final userData = await userViewModel.fetchUserData();

      if (userData != null && userData.success) {
        // Populate form fields with API data
        _nameController.text = userData.data.name;
        _emailController.text = userData.data.email;
        _nicknameController.text = userData.data.nickName;
        _mobileController.text = userData.data.phone.toString();
        _zipCodeController.text = userData.data.zip ?? '';
        _addressController.text = userData.data.address1 ?? '';
        _suiteController.text = userData.data.address2 ?? '';
        _introductionController.text = userData.data.introduction ?? '';
        profileImageUrl = userData.data.profileImage;

        // Set gender if available
        if (userData.data.gender != null) {
          // Convert API gender to proper case for dropdown
          String apiGender = userData.data.gender!.toLowerCase();
          print(
            'API Gender received: ${userData.data.gender} -> converted to: $apiGender',
          );
          if (apiGender == 'male') {
            _selectedGender = 'Male';
          } else if (apiGender == 'female') {
            _selectedGender = 'Female';
          } else {
            _selectedGender = 'Other';
          }
          print('Selected gender set to: $_selectedGender');
        }

        // Set profile image if available
        if (userData.data.profileImage.isNotEmpty) {
          // You might want to download and set the image here
          // For now, we'll keep the existing placeholder logic
        }

        setState(() {});
      } else {
        // Fallback to sample data if API fails
        _loadSampleData();
        Get.snackbar(
          'Warning'.tr,
          'Could not load user data. Using default values.'.tr,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error loading user data: $e');
      _loadSampleData();
      Get.snackbar(
        'Error'.tr,
        'Failed to load user data: $e'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      // Use WidgetsBinding to ensure we're not in build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        userViewModel.setLoading(false);
      });
    }
  }

  void _loadSampleData() {
    _nameController.text = 'Sarah Johnson';
    _emailController.text = 'sarah.johnson@example.com';
    _nicknameController.text = 'Caring Heart';
    _mobileController.text = '+1 (555) 123-4567';
    _zipCodeController.text = '10001';
    _addressController.text = '123 Main Street, New York, NY';
    _suiteController.text = 'Suite 456';
    _introductionController.text =
        'Hello, I am a licensed professional counselor with over 8 years of experience helping individuals navigate through life\'s challenges. I specialize in anxiety, depression and relationship counseling';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nicknameController.dispose();
    _mobileController.dispose();
    _zipCodeController.dispose();
    _addressController.dispose();
    _suiteController.dispose();
    _introductionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserViewModel, LoadingProvider>(
      builder: (context, userViewModel, loadingProvider, child) {
        return Scaffold(
          backgroundColor: Color(0xFFF5F5F5),
          body:
              loadingProvider.isLoading
                  ? Center(
                    child: CircularProgressIndicator(
                      color: primaryColorConsulor,
                    ),
                  )
                  : Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(15.w),
                      child: Column(
                        children: [
                          // Profile Image Card

                          // Main Form Card
                          _buildMainFormCard(),
                          UIHelper.verticalSpaceMd,

                          // Logout Card
                          _buildLogoutCard(),
                        ],
                      ),
                    ),
                  ),
        );
      },
    );
  }

  Widget _buildMainFormCard() {
    return Container(
      width: Get.width,
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor),
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
            // Profile Photo - only show if enabled
            Consumer<SettingProvider>(
              builder: (context, settingProvider, child) {
                if (!settingProvider.isProfilePhotoEnabled) {
                  return SizedBox.shrink();
                }
                return Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100.w,
                            height: 100.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _profileImage != null ||
                                      (profileImageUrl != null &&
                                          profileImageUrl!.isNotEmpty)
                                  ? Colors.grey[200]
                                  : Color(0xff4A90E2),
                              image:
                                  _profileImage != null
                                      ? DecorationImage(
                                        image: FileImage(_profileImage!),
                                        fit: BoxFit.cover,
                                      )
                                      : (profileImageUrl != null &&
                                              profileImageUrl!.isNotEmpty)
                                          ? DecorationImage(
                                            image: NetworkImage(
                                              profileImageUrl!,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                          : null,
                            ),
                            child: (_profileImage == null &&
                                    (profileImageUrl == null ||
                                        profileImageUrl!.isEmpty))
                                ? Center(
                                    child: Text(
                                      _getProfileInitials(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 32.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickProfileImage,
                              child: Container(
                                width: 32.w,
                                height: 32.w,
                                decoration: BoxDecoration(
                                  color: primaryColorConsulor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16.w,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    UIHelper.verticalSpaceMd,
                  ],
                );
              },
            ),

            // Name Field - only show if enabled
            Consumer<SettingProvider>(
              builder: (context, settingProvider, child) {
                final minLength = settingProvider.minNicknameLength;
                final maxLength = settingProvider.maxNicknameLength;
                final allowSpecialChars =
                    settingProvider.allowSpecialCharactersInNickname;

                if (!settingProvider.isProfileNameEnabled) {
                  return SizedBox.shrink();
                }
                return Customtextfield(
                  controller: _nameController,
                  required: true,
                  hint: "Enter your name".tr,
                  text: "Name".tr,
                  keyboard: TextInputType.name,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Please enter your name".tr;
                    }
                    if (value.length < minLength) {
                      return "Name must be at least $minLength characters long"
                          .tr;
                    }
                    if (value.length > maxLength) {
                      return "Name must be at most $maxLength characters long"
                          .tr;
                    }
                    if (!allowSpecialChars &&
                        !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                      return "Name must only contain letters and numbers".tr;
                    }
                    return null;
                  },
                );
              },
            ),
            UIHelper.verticalSpaceSm,

            // Gender Field
            SizedBox(child: _buildGenderField()),

            UIHelper.verticalSpaceSm,

            // Email Field
            Customtextfield(
              controller: _emailController,
              required: true,
              readOnly: true,
              hint: "Enter your email".tr,
              text: "Email".tr,
              keyboard: TextInputType.emailAddress,
              validator: (value) {
                if (value!.isEmpty) {
                  return "Please enter your email".tr;
                } else if (!GetUtils.isEmail(value)) {
                  return "Please enter a valid email".tr;
                }
                return null;
              },
            ),
            UIHelper.verticalSpaceSm,

            // Nickname Field
            Customtextfield(
              controller: _nicknameController,
              required: true,
              hint: "Enter your nickname".tr,
              text: "Nickname".tr,
              keyboard: TextInputType.text,
              validator: (value) {
                if (value!.isEmpty) {
                  return "Please enter your nickname".tr;
                }
                return null;
              },
            ),
            UIHelper.verticalSpaceSm,

            // Mobile Number Field
            Customtextfield(
              controller: _mobileController,
              required: true,
              hint: "Enter your mobile number".tr,
              text: "Mobile Number".tr,
              keyboard: TextInputType.phone,

              validator: (value) {
                if (value!.isEmpty) {
                  return "Please enter your mobile number".tr;
                }
                return null;
              },
            ),
            UIHelper.verticalSpaceSm,

            // Address Information Section
            CustomText(
              text: "Address Information *".tr,
              fontSize: FontConstants.font_16,
              weight: FontWeightConstants.medium,
              color: Colors.black,
            ),
            UIHelper.verticalSpaceSm,

            // ZIP Code
            Customtextfield(
              controller: _zipCodeController,
              required: false,
              hint: "ZIP Code".tr,
              keyboard: TextInputType.number,
            ),
            UIHelper.verticalSpaceSm,

            // Street Address
            Customtextfield(
              controller: _addressController,
              required: false,
              hint: "Street Address".tr,
              keyboard: TextInputType.streetAddress,
            ),
            UIHelper.verticalSpaceSm,

            // Suite/Apartment
            Customtextfield(
              controller: _suiteController,
              required: false,
              hint: "Suite/Apartment".tr,
              keyboard: TextInputType.text,
            ),
            UIHelper.verticalSpaceSm,

            // Introduction Field - only show if enabled
            Consumer<SettingProvider>(
              builder: (context, settingProvider, child) {
                // if (!settingProvider.isProfileSelfIntroEnabled) {
                //   return SizedBox.shrink();
                // }
                return Customtextfield(
                  controller: _introductionController,
                  required: false,
                  hint: "Tell us about yourself".tr,
                  text: "Introduction".tr,
                  keyboard: TextInputType.multiline,
                  maxLines: 4,
                );
              },
            ),
            UIHelper.verticalSpaceMd,

            // Save Button
            CustomButton(
              _saveProfile,
              text: "Save".tr,
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

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: "Gender".tr,
          fontSize: FontConstants.font_16,
          weight: FontWeightConstants.medium,
          color: Colors.black,
        ),
        UIHelper.verticalSpaceSm,
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0.h),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(7.0),
            border: Border.all(width: 0.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value:
                  ['Male', 'Female', 'Other'].contains(_selectedGender)
                      ? _selectedGender
                      : 'Female',
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey,
                size: 20.w,
              ),
              items:
                  ['Male', 'Female', 'Other'].map((String gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: CustomText(
                        text: gender.tr,
                        fontSize: FontConstants.font_14,
                        weight: FontWeightConstants.regular,
                        color: Colors.black,
                      ),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: CustomButton(
        _logout,
        text: "Logout".tr,
        color: Colors.white,
        textcolor: Colors.red,
        fsize: FontConstants.font_16,
        weight: FontWeightConstants.medium,
        buttonBorderColor: Colors.red,
        isCancelButton: true,
      ),
    );
  }

  void _pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 300,
        maxHeight: 300,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error'.tr,
        'Failed to pick image: $e'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);

      // Check if userModel exists and has a token
      // if (userViewModel.userModel == null ||
      //     userViewModel.userModel!.data.token.isEmpty) {
      //   Get.snackbar(
      //     'Error',
      //     'No authentication token available. Please login again.',
      //     backgroundColor: Colors.red,
      //     colorText: Colors.white,
      //   );
      //   return;
      // }

      try {
        // Show loading indicator
        userViewModel.setLoading(true);

        // Prepare data for API call
        final result = await userViewModel.updatePersonalInfo(
          gender: _selectedGender.toLowerCase(),
          nickName: _nicknameController.text,
          phone: _mobileController.text,
          address1: _addressController.text,
          address2: _suiteController.text,
          introduction: _introductionController.text,
          zip: _zipCodeController.text,
          image: _profileImage,
        );

        if (result['success']) {
          String message = await translationService.translate(
            result['message'],
          );
          print("+++++message: $message");
          UIHelper.showBottomFlash(
            context,
            title: "",
            message: message,
            isError: false,
          );

          // Optionally refresh the user data
          _loadUserData();
        } else {
          String message = await translationService.translate(
            result['message'],
          );
          UIHelper.showBottomFlash(
            context,
            title: "",
            message: message,
            isError: true,
          );
        }
      } catch (e) {
        print('Error saving profile: $e');
        Get.snackbar(
          'Error'.tr,
          'Failed to update profile: $e'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } finally {
        userViewModel.setLoading(false);
      }
    }
  }

  void _logout() {
    UIHelper.showDialogOk(
      context,
      title: 'log out'.tr,
      message: 'Would you really log out?'.tr,
      onConfirm: () {
        Get.back();
        context.read<UserViewModel>().clearUserModel();
      },
    );
  }
}
