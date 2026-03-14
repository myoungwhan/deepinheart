import 'dart:io';
import 'dart:convert';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/custom_textfiled.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({Key? key}) : super(key: key);

  @override
  _EditProfileDialogState createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _nicknameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String _selectedGender = 'Male';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final userData = userViewModel.userModel?.data;

    _nameController = TextEditingController(text: userData?.name ?? '');
    _nicknameController = TextEditingController(text: userData?.nickName ?? '');
    _phoneController = TextEditingController(
      text: UIHelper.formatKoreanPhoneNumber(userData?.phone ?? ''),
    );
    _emailController = TextEditingController(text: userData?.email ?? '');

    // Set gender from user data
    if (userData?.gender != null) {
      String apiGender = userData!.gender!.toLowerCase();
      if (apiGender == 'male') {
        _selectedGender = 'Male';
      } else if (apiGender == 'female') {
        _selectedGender = 'Female';
      } else {
        _selectedGender = 'Male';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Extract error message from API response
  /// Handles different error response formats
  String _extractErrorMessage(Map<String, dynamic> result) {
    try {
      // Check if there's a direct message
      if (result['message'] != null) {
        final message = result['message'];

        // If message is a string, return it directly
        if (message is String) {
          return message;
        }

        // If message is a Map (validation errors), parse it
        if (message is Map<String, dynamic>) {
          List<String> errorMessages = [];
          message.forEach((key, value) {
            if (value is List) {
              errorMessages.addAll(value.map((e) => e.toString()));
            } else if (value is String) {
              errorMessages.add(value);
            } else {
              errorMessages.add(value.toString());
            }
          });
          return errorMessages.isNotEmpty
              ? errorMessages.join('\n')
              : 'Failed to update profile'.tr;
        }
      }

      // Check for error field (raw JSON string that needs parsing)
      if (result['error'] != null) {
        final errorData = result['error'];

        // If error is a string, try to parse it as JSON
        if (errorData is String) {
          try {
            final parsedError = jsonDecode(errorData);
            if (parsedError is Map<String, dynamic>) {
              // Check for message in parsed error
              if (parsedError['message'] != null) {
                final message = parsedError['message'];
                if (message is String) {
                  return message;
                } else if (message is Map) {
                  List<String> errorMessages = [];
                  message.forEach((key, value) {
                    if (value is List) {
                      errorMessages.addAll(value.map((e) => e.toString()));
                    } else if (value is String) {
                      errorMessages.add(value);
                    }
                  });
                  return errorMessages.isNotEmpty
                      ? errorMessages.join('\n')
                      : 'Failed to update profile'.tr;
                }
              }
              // Check for errors field in parsed error
              if (parsedError['errors'] != null &&
                  parsedError['errors'] is Map) {
                List<String> errorMessages = [];
                (parsedError['errors'] as Map).forEach((key, value) {
                  if (value is List) {
                    errorMessages.addAll(value.map((e) => e.toString()));
                  } else if (value is String) {
                    errorMessages.add(value);
                  }
                });
                return errorMessages.isNotEmpty
                    ? errorMessages.join('\n')
                    : 'Failed to update profile'.tr;
              }
            }
          } catch (e) {
            // If parsing fails, return the raw string
            return errorData;
          }
        }
      }

      // Check for errors field (Laravel validation format)
      if (result['errors'] != null && result['errors'] is Map) {
        List<String> errorMessages = [];
        (result['errors'] as Map).forEach((key, value) {
          if (value is List) {
            errorMessages.addAll(value.map((e) => e.toString()));
          } else if (value is String) {
            errorMessages.add(value);
          }
        });
        return errorMessages.isNotEmpty
            ? errorMessages.join('\n')
            : 'Failed to update profile'.tr;
      }
    } catch (e) {
      debugPrint('Error extracting error message: $e');
    }

    // Default error message
    return 'Failed to update profile'.tr;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error'.tr,
        'Failed to pick image: $e'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);

      // Validate required fields
      // if (_nicknameController.text.trim().isEmpty) {
      //   UIHelper.showBottomFlash(
      //     context,
      //     title: 'Validation Error'.tr,
      //     message: 'Nickname is required'.tr,
      //     isError: true,
      //   );
      //   setState(() {
      //     _isLoading = false;
      //   });
      //   return;
      // }

      if (_phoneController.text.trim().isEmpty) {
        Get.snackbar(
          'Validation Error'.tr,
          'Phone number is required'.tr,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Call updatePersonalInfo
      final result = await userViewModel.updatePersonalInfo(
        gender: _selectedGender.toLowerCase(),
        nickName: _nicknameController.text.trim(),
        phone: _phoneController.text.replaceAll(
          RegExp(r'[^\d]'),
          '',
        ), // Remove dashes and non-digits
        address1: userViewModel.userModel?.data.address1 ?? '',
        address2: userViewModel.userModel?.data.address2 ?? '',
        introduction: userViewModel.userModel?.data.introduction ?? '',
        zip: userViewModel.userModel?.data.zip ?? '',
        image: _selectedImage,
      );

      if (result['success'] == true) {
        await userViewModel.fetchUserData();
        Get.snackbar(
          'Success'.tr,
          'Profile updated successfully'.tr,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Navigator.of(context).pop();
      } else {
        // Extract error message from API response
        String errorMessage = _extractErrorMessage(result);
        Get.snackbar(
          'Error'.tr,
          errorMessage,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error'.tr,
        'An error occurred: $e'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDarkMode ? theme.dialogBackgroundColor : Colors.white,
      insetPadding: EdgeInsets.all(25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDarkMode ? theme.dialogBackgroundColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Consumer<UserViewModel>(
          builder: (context, userViewModel, child) {
            final userData = userViewModel.userModel?.data;

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  CustomText(
                    text: 'Edit profile'.tr,
                    fontSize: FontConstants.font_20,
                    weight: FontWeightConstants.bold,
                    color: isDarkMode ? Colors.white : Color(0xFF333333),
                  ),

                  UIHelper.verticalSpaceMd,

                  // Profile Picture Section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isDarkMode
                                      ? Colors.white38
                                      : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child:
                                _selectedImage != null
                                    ? Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    )
                                    : userData?.profileImage != null &&
                                        userData!.profileImage.isNotEmpty
                                    ? Image.network(
                                      userData.profileImage,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return _buildDefaultAvatar();
                                      },
                                    )
                                    : _buildDefaultAvatar(),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(0xFF3478B5),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      isDarkMode
                                          ? theme.dialogBackgroundColor
                                          : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  UIHelper.verticalSpaceL,

                  // Name Field
                  _buildInputField(
                    label: 'Name'.tr,
                    controller: _nameController,
                    enabled: false, // Name cannot be changed
                    helperText:
                        'Contact customer service if changes are needed'.tr,
                  ),

                  UIHelper.verticalSpaceSm,

                  // Nickname Field
                  _buildInputField(
                    label: 'Nickname'.tr,
                    controller: _nicknameController,
                  ),

                  UIHelper.verticalSpaceSm,

                  // Gender Field
                  _buildGenderField(),

                  UIHelper.verticalSpaceSm,

                  // Phone Number Field
                  _buildInputField(
                    label: 'Phone Number'.tr,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),

                  UIHelper.verticalSpaceSm,

                  // Email Field
                  _buildInputField(
                    label: 'Email'.tr,
                    controller: _emailController,
                    enabled: false, // Email cannot be changed
                    helperText: 'Email cannot be changed.'.tr,
                  ),

                  UIHelper.verticalSpaceL,

                  // Action Buttons
                  Row(
                    children: [
                      // Cancellation Button
                      Expanded(
                        child: Container(
                          height: 48,
                          child: OutlinedButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color:
                                    isDarkMode
                                        ? Colors.white38
                                        : Colors.grey.shade400,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: CustomText(
                              text: 'cancellation'.tr,
                              fontSize: FontConstants.font_16,
                              weight: FontWeightConstants.medium,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.black87,
                            ),
                          ),
                        ),
                      ),

                      UIHelper.horizontalSpaceSm,

                      // Save Button
                      Expanded(
                        child: Container(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF3478B5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child:
                                _isLoading
                                    ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : CustomText(
                                      text: 'save'.tr,
                                      fontSize: FontConstants.font_16,
                                      weight: FontWeightConstants.semiBold,
                                      color: Colors.white,
                                    ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
      child: Icon(
        Icons.person,
        size: 50,
        color: isDarkMode ? Colors.grey[600] : Colors.grey.shade400,
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType? keyboardType,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Customtextfield(
          required: false,
          controller: controller,
          text: label,
          hint: label,
          readOnly: !enabled,
          keyboard: keyboardType ?? TextInputType.text,
          validator: (value) {
            if (!enabled) return null;
            if (value == null || value.isEmpty) {
              return "Please enter $label".tr;
            }
            return null;
          },
        ),
        if (helperText != null) ...[
          UIHelper.verticalSpaceSm,
          CustomText(
            text: helperText,
            fontSize: FontConstants.font_12,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey.shade600,
          ),
        ],
      ],
    );
  }

  Widget _buildGenderField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: "Gender".tr,
          fontSize: FontConstants.font_14,
          weight: FontWeightConstants.medium,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        UIHelper.verticalSpaceSm,
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white10 : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(7.0),
            border: Border.all(
              width: 0.5,
              color: isDarkMode ? Colors.white24 : Colors.grey,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value:
                  ['Male', 'Female'].contains(_selectedGender)
                      ? _selectedGender
                      : 'Male',
              isExpanded: true,
              dropdownColor:
                  isDarkMode
                      ? Theme.of(context).dialogBackgroundColor
                      : Colors.white,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: isDarkMode ? Colors.grey[400] : Colors.grey,
                size: 20,
              ),
              items:
                  ['Male', 'Female'].map((String gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: CustomText(
                        text: gender.tr,
                        fontSize: FontConstants.font_14,
                        weight: FontWeightConstants.regular,
                        color: isDarkMode ? Colors.white : Colors.black,
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
}
