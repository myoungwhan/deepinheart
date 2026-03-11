import 'dart:io';
import 'package:deepinheart/Controller/Model/inquiry_model.dart';
import 'package:deepinheart/Controller/Viewmodel/setting_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:deepinheart/main.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/custom_textfiled.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

class CustomerServiceScreen extends StatefulWidget {
  const CustomerServiceScreen({Key? key}) : super(key: key);

  @override
  State<CustomerServiceScreen> createState() => _CustomerServiceScreenState();
}

class _CustomerServiceScreenState extends State<CustomerServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String? _selectedInquiryType;
  bool _isUrgent = false;
  File? _selectedFile;
  String? _selectedFileName;
  bool _isSubmitting = false;
  bool _isLoading = false;
  List<Inquiry> _inquiries = [];

  final List<String> _inquiryTypes = [
    'general',
    'technical',
    'billing',
    'complaint',
  ];

  @override
  void initState() {
    super.initState();
    _fetchInquiries();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _fetchInquiries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        Get.snackbar(
          'Error'.tr,
          'Please login to view inquiries'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final response = await http.get(
        Uri.parse(ApiEndPoints.INQUIRIES),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final inquiryModel = InquiryModel.fromJson(data);
        setState(() {
          _inquiries = inquiryModel.data;
        });
      } else {
        Get.snackbar(
          'Error'.tr,
          'Failed to load inquiries'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error'.tr,
        'Failed to load inquiries'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitInquiry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedInquiryType == null) {
      Get.snackbar(
        'Error'.tr,
        'Please select inquiry type'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        Get.snackbar(
          'Error'.tr,
          'Please login to submit inquiry'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndPoints.INQUIRIES),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['inquiry_type'] = _selectedInquiryType!;
      request.fields['title'] = _titleController.text.trim();
      request.fields['detail'] = _detailController.text.trim();
      request.fields['is_urgent'] = _isUrgent ? '1' : '0';

      if (_selectedFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('attachment', _selectedFile!.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar(
          'Success'.tr,
          'Inquiry submitted successfully'.tr,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Reset form
        _titleController.clear();
        _detailController.clear();
        setState(() {
          _selectedInquiryType = null;
          _isUrgent = false;
          _selectedFile = null;
          _selectedFileName = null;
        });

        // Refresh inquiries list
        _fetchInquiries();
      } else {
        final errorData = jsonDecode(responseBody);
        final errorMessage =
            errorData['message'] ?? 'Failed to submit inquiry'.tr;
        Get.snackbar(
          'Error'.tr,
          errorMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error'.tr,
        'Failed to submit inquiry'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showAttachmentSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: CustomText(
            text: 'Add Attachment'.tr,
            fontSize: FontConstants.font_16,
            weight: FontWeightConstants.medium,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: primaryColor),
                title: CustomText(text: 'Camera'.tr),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: primaryColor),
                title: CustomText(text: 'Gallery'.tr),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.insert_drive_file, color: primaryColor),
                title: CustomText(text: 'File'.tr),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
          _selectedFileName = image.name;
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error'.tr,
        'Failed to pick image: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error'.tr,
        'Failed to pick file: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingProvider = Provider.of<SettingProvider>(context);
    final settings = settingProvider.settings;

    return Scaffold(
      backgroundColor: isMainDark ? bgColordark : bgColor,
      appBar: AppBar(
        title: CustomText(
          text: 'Customer Service'.tr,
          fontSize: FontConstants.font_18,
          weight: FontWeightConstants.bold,
        ),
        backgroundColor: isMainDark ? bgColordark : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isMainDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient:
                isMainDark
                    ? null
                    : LinearGradient(
                      colors: [Colors.white, Colors.white.withOpacity(0.95)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchInquiries,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact Information Card
              if (settings != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    gradient:
                        isMainDark
                            ? LinearGradient(
                              colors: [cardColor, cardColor.withOpacity(0.8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                            : LinearGradient(
                              colors: [
                                Colors.white,
                                primaryColor.withOpacity(0.02),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color:
                          isMainDark
                              ? Colors.white.withOpacity(0.1)
                              : primaryColor.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isMainDark
                                ? Colors.black.withOpacity(0.3)
                                : primaryColor.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              Icons.support_agent,
                              color: primaryColor,
                              size: 24.w,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  text: 'Contact Us'.tr,
                                  fontSize: FontConstants.font_18,
                                  weight: FontWeightConstants.bold,
                                  color: primaryColor,
                                ),
                                CustomText(
                                  text: 'We\'re here to help'.tr,
                                  fontSize: FontConstants.font_12,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      UIHelper.verticalSpaceMd,
                      if (settings.customerPhoneService.isNotEmpty)
                        _buildContactItem(
                          Icons.phone_rounded,
                          'Phone'.tr,
                          settings.customerPhoneService,
                          () {
                            // Handle phone call
                          },
                        ),
                      if (settings.customerServiceEmail.isNotEmpty) ...[
                        UIHelper.verticalSpaceSm,
                        _buildContactItem(
                          Icons.email_rounded,
                          'Email'.tr,
                          settings.customerServiceEmail,
                          () {
                            // Handle email
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              UIHelper.verticalSpaceL,

              // Submit Inquiry Form
              Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 24.h,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  CustomText(
                    text: 'Submit Inquiry'.tr,
                    fontSize: FontConstants.font_20,
                    weight: FontWeightConstants.bold,
                  ),
                ],
              ),
              UIHelper.verticalSpaceMd,
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: isMainDark ? cardColor : Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color:
                        isMainDark
                            ? Colors.white.withOpacity(0.1)
                            : borderColor,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isMainDark
                              ? Colors.black.withOpacity(0.2)
                              : Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Inquiry Type Dropdown
                      Row(
                        children: [
                          Icon(
                            Icons.category_rounded,
                            size: 18.w,
                            color: primaryColor,
                          ),
                          SizedBox(width: 8.w),
                          CustomText(
                            text: 'Inquiry Type'.tr,
                            fontSize: FontConstants.font_14,
                            weight: FontWeightConstants.medium,
                          ),
                        ],
                      ),
                      UIHelper.verticalSpaceSm,
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          gradient:
                              isMainDark
                                  ? LinearGradient(
                                    colors: [
                                      cardColor,
                                      cardColor.withOpacity(0.8),
                                    ],
                                  )
                                  : LinearGradient(
                                    colors: [
                                      Colors.grey.withOpacity(0.05),
                                      Colors.grey.withOpacity(0.02),
                                    ],
                                  ),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color:
                                _selectedInquiryType != null
                                    ? primaryColor.withOpacity(0.3)
                                    : borderColor,
                            width: 1.5,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedInquiryType,
                            isExpanded: true,
                            hint: CustomText(
                              text: 'Select inquiry type'.tr,
                              fontSize: FontConstants.font_14,
                              color: hintColor,
                            ),
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: primaryColor,
                              size: 24.w,
                            ),
                            items:
                                _inquiryTypes.map((String type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(6.w),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6.r,
                                            ),
                                          ),
                                          child: Icon(
                                            _getInquiryTypeIcon(type),
                                            size: 16.w,
                                            color: primaryColor,
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        CustomText(
                                          text: type.tr,
                                          fontSize: FontConstants.font_14,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedInquiryType = newValue;
                              });
                            },
                          ),
                        ),
                      ),
                      UIHelper.verticalSpaceMd,

                      // Title Field
                      Customtextfield(
                        hint: 'Enter inquiry title'.tr,
                        controller: _titleController,
                        required: false,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter title'.tr;
                          }
                          return null;
                        },
                      ),
                      UIHelper.verticalSpaceMd,

                      // Details Field
                      Customtextfield(
                        hint: 'Enter inquiry details'.tr,
                        controller: _detailController,
                        maxLines: 5,
                        required: false,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter details'.tr;
                          }
                          return null;
                        },
                      ),
                      UIHelper.verticalSpaceMd,

                      // Attachment
                      CustomText(
                        text: 'Attachment'.tr,
                        fontSize: FontConstants.font_14,
                        weight: FontWeightConstants.medium,
                      ),
                      UIHelper.verticalSpaceSm,
                      if (_selectedFile == null)
                        InkWell(
                          onTap: () => _showAttachmentSourceDialog(),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor.withOpacity(0.1),
                                  primaryColor.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.3),
                                width: 1.5,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.attach_file_rounded,
                                  color: primaryColor,
                                  size: 20.w,
                                ),
                                SizedBox(width: 8.w),
                                CustomText(
                                  text: 'Add Attachment'.tr,
                                  fontSize: FontConstants.font_14,
                                  weight: FontWeightConstants.medium,
                                  color: primaryColor,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors:
                                  isMainDark
                                      ? [
                                        primaryColor.withOpacity(0.2),
                                        primaryColor.withOpacity(0.1),
                                      ]
                                      : [
                                        primaryColor.withOpacity(0.1),
                                        primaryColor.withOpacity(0.05),
                                      ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  Icons.attach_file_rounded,
                                  color: primaryColor,
                                  size: 20.w,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: _selectedFileName ?? 'File',
                                      fontSize: FontConstants.font_14,
                                      weight: FontWeightConstants.medium,
                                      maxlines: 1,
                                    ),
                                    CustomText(
                                      text: 'Tap to change'.tr,
                                      fontSize: FontConstants.font_12,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Container(
                                  padding: EdgeInsets.all(4.w),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.red,
                                    size: 18.w,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedFile = null;
                                    _selectedFileName = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      UIHelper.verticalSpaceMd,

                      // Urgent Checkbox
                      Visibility(
                        visible: false,
                        child: Row(
                          children: [
                            Checkbox(
                              value: _isUrgent,
                              onChanged: (value) {
                                setState(() {
                                  _isUrgent = value ?? false;
                                });
                              },
                              activeColor: primaryColor,
                            ),
                            Expanded(
                              child: CustomText(
                                text: 'Mark as urgent'.tr,
                                fontSize: FontConstants.font_14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      UIHelper.verticalSpaceL,

                      // Submit Button
                      Container(
                        width: double.infinity,
                        height: 50.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                _isSubmitting
                                    ? [
                                      primaryColor.withOpacity(0.5),
                                      primaryColor.withOpacity(0.3),
                                    ]
                                    : [
                                      primaryColor,
                                      primaryColor.withOpacity(0.8),
                                    ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow:
                              _isSubmitting
                                  ? []
                                  : [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: Offset(0, 8),
                                      spreadRadius: 0,
                                    ),
                                  ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isSubmitting ? null : _submitInquiry,
                            borderRadius: BorderRadius.circular(12.r),
                            child: Center(
                              child:
                                  _isSubmitting
                                      ? SizedBox(
                                        width: 24.w,
                                        height: 24.h,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.send_rounded,
                                            color: Colors.white,
                                            size: 20.w,
                                          ),
                                          SizedBox(width: 8.w),
                                          CustomText(
                                            text: 'Submit'.tr,
                                            fontSize: FontConstants.font_16,
                                            weight: FontWeightConstants.bold,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              UIHelper.verticalSpaceL,

              // My Inquiries List
              Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 24.h,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  CustomText(
                    text: 'My Inquiries'.tr,
                    fontSize: FontConstants.font_20,
                    weight: FontWeightConstants.bold,
                  ),
                ],
              ),
              UIHelper.verticalSpaceMd,
              _isLoading
                  ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.h),
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  )
                  : _inquiries.isEmpty
                  ? Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(40.h),
                    decoration: BoxDecoration(
                      color: isMainDark ? cardColor : Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64.w,
                          color: Colors.grey,
                        ),
                        UIHelper.verticalSpaceMd,
                        CustomText(
                          text: 'No inquiries yet'.tr,
                          fontSize: FontConstants.font_16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _inquiries.length,
                    itemBuilder: (context, index) {
                      final inquiry = _inquiries[index];
                      return _buildInquiryCard(inquiry);
                    },
                  ),
              UIHelper.verticalSpaceL,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color:
              isMainDark
                  ? Colors.white.withOpacity(0.05)
                  : primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                isMainDark
                    ? Colors.white.withOpacity(0.1)
                    : primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: primaryColor, size: 20.w),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: label,
                    fontSize: FontConstants.font_12,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 2.h),
                  CustomText(
                    text: value,
                    fontSize: FontConstants.font_14,
                    weight: FontWeightConstants.medium,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16.w,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getInquiryTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'general':
        return Icons.info_rounded;
      case 'technical':
        return Icons.build_rounded;
      case 'billing':
        return Icons.payment_rounded;
      case 'complaint':
        return Icons.report_problem_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Widget _buildInquiryCard(Inquiry inquiry) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        gradient:
            isMainDark
                ? LinearGradient(
                  colors: [cardColor, cardColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                : LinearGradient(
                  colors: [Colors.white, Colors.white.withOpacity(0.95)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color:
              isMainDark
                  ? Colors.white.withOpacity(0.1)
                  : borderColor.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isMainDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(18.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: inquiry.title,
                        fontSize: FontConstants.font_16,
                        weight: FontWeightConstants.bold,
                      ),
                      UIHelper.verticalSpaceSm,
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          _buildStatusChip(
                            inquiry.statusLabel.tr,
                            _getStatusColor(inquiry.status),
                            _getStatusIcon(inquiry.status),
                          ),
                          _buildStatusChip(
                            inquiry.inquiryTypeLabel.tr,
                            primaryColor,
                            _getInquiryTypeIcon(inquiry.inquiryType),
                          ),
                          if (inquiry.isUrgent)
                            _buildStatusChip(
                              'Urgent'.tr,
                              Colors.red,
                              Icons.priority_high_rounded,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            UIHelper.verticalSpaceSm,
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color:
                    isMainDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: CustomText(
                text: inquiry.detail,
                fontSize: FontConstants.font_14,
                maxlines: 3,
              ),
            ),
            UIHelper.verticalSpaceSm,
            if (inquiry.response != null && inquiry.response!.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.1),
                      primaryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: primaryColor,
                          size: 18.w,
                        ),
                        SizedBox(width: 8.w),
                        CustomText(
                          text: 'Response'.tr,
                          fontSize: FontConstants.font_14,
                          weight: FontWeightConstants.bold,
                          color: primaryColor,
                        ),
                      ],
                    ),
                    UIHelper.verticalSpaceSm,
                    CustomText(
                      text: inquiry.response!,
                      fontSize: FontConstants.font_14,
                    ),
                    if (inquiry.respondedAt != null) ...[
                      UIHelper.verticalSpaceSm,
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14.w,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 4.w),
                          CustomText(
                            text:
                                'Responded At'.tr + ': ${inquiry.respondedAt}',
                            fontSize: FontConstants.font_12,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              UIHelper.verticalSpaceSm,
            ],
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14.w,
                  color: Colors.grey,
                ),
                SizedBox(width: 4.w),
                CustomText(
                  text: 'Created At'.tr + ': ${inquiry.createdAt}',
                  fontSize: FontConstants.font_12,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.w, color: color),
          SizedBox(width: 6.w),
          CustomText(
            text: label,
            fontSize: FontConstants.font_12,
            color: color,
            weight: FontWeightConstants.medium,
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_rounded;
      case 'in_progress':
        return Icons.hourglass_empty_rounded;
      case 'resolved':
        return Icons.check_circle_rounded;
      case 'closed':
        return Icons.close_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}
