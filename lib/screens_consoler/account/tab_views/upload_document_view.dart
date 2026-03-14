import 'package:auto_size_text/auto_size_text.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/Controller/Viewmodel/setting_provider.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UploadDocumentView extends StatefulWidget {
  const UploadDocumentView({Key? key}) : super(key: key);

  @override
  _UploadDocumentViewState createState() => _UploadDocumentViewState();
}

class _UploadDocumentViewState extends State<UploadDocumentView> {
  final ImagePicker _imagePicker = ImagePicker();

  // Get required document types based on settings
  List<String> _getRequiredDocumentTypes(SettingProvider settingProvider) {
    List<String> requiredTypes = [];

    // Map settings to document types
    if (settingProvider.isIdCardCopyRequired) {
      requiredTypes.add('Identity Document'.tr);
    }
    if (settingProvider.isLicenseCopyRequired) {
      requiredTypes.add('Professional License'.tr);
    }
    if (settingProvider.isResumeRequired) {
      requiredTypes.add('Experience Letter'.tr);
    }
    if (settingProvider.isApplicationSelfIntroRequired) {
      // Application Self Intro might map to a specific document type
      // For now, we'll add it as a separate type or map it appropriately
      requiredTypes.add('Application Self Introduction'.tr);
    }
    if (settingProvider.isBankAccountCopyRequired) {
      requiredTypes.add('Bank Account Copy'.tr);
    }

    return requiredTypes;
  }

  // Get available document types based on settings
  List<String> _getAvailableDocumentTypes(SettingProvider settingProvider) {
    List<String> types = [];

    // Add document types based on settings
    if (settingProvider.isLicenseCopyRequired) {
      types.add('Professional License');
    }
    if (settingProvider.isResumeRequired) {
      types.add('Experience Letter');
    }
    // Degree Certificate, Training Certificate are always available
    types.add('Degree Certificate');
    types.add('Training Certificate');

    if (settingProvider.isIdCardCopyRequired) {
      types.add('Identity Document');
    }
    types.add('Background Check');
    types.add('Insurance Certificate');

    // Add required document types that might not be in the main list
    if (settingProvider.isApplicationSelfIntroRequired) {
      types.add('Application Self Introduction');
    }
    if (settingProvider.isBankAccountCopyRequired) {
      types.add('Bank Account Copy');
    }

    types.add('Other');

    return types;
  }

  // Get missing required documents
  List<String> _getMissingRequiredDocuments(SettingProvider settingProvider) {
    final requiredTypes = _getRequiredDocumentTypes(settingProvider);
    final uploadedTypes =
        _uploadedDocuments
            .map((doc) => (doc['name'] ?? doc['documentType'] ?? '').toString())
            .toList();

    return requiredTypes
        .where((type) => !uploadedTypes.contains(type))
        .toList();
  }

  // Uploaded documents data
  List<Map<String, dynamic>> _uploadedDocuments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUploadedDocuments();
  }

  // Load uploaded documents from API
  Future<void> _loadUploadedDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final documents = await userViewModel.getUploadedDocuments();

      setState(() {
        _uploadedDocuments = documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading documents: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document Registration Section
            _buildDocumentRegistrationSection(),
            UIHelper.verticalSpaceMd,

            // Uploaded Documents Section
            _buildUploadedDocumentsSection(),
            UIHelper.verticalSpaceMd,

            // Information Note
            _buildInformationNote(),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentRegistrationSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          CustomText(
            text: "Document Registration".tr,
            fontSize: FontConstants.font_18,
            weight: FontWeightConstants.bold,
            color: Colors.black,
          ),
          UIHelper.verticalSpaceMd,

          // Instructions Box
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text:
                      "Please upload required documents such as certifications, experience letters, education certificates, and training records. These will be reviewed and approved by our administrators."
                          .tr,
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.regular,
                  color: Color(0xFF1976D2),
                ),
                UIHelper.verticalSpaceSm,
                CustomText(
                  text: "Allowed file types: PDF, JPG, PNG".tr,
                  fontSize: FontConstants.font_12,
                  weight: FontWeightConstants.medium,
                  color: Color(0xFF1976D2),
                ),
                CustomText(
                  text: "Maximum file size: 10MB".tr,
                  fontSize: FontConstants.font_12,
                  weight: FontWeightConstants.medium,
                  color: Color(0xFF1976D2),
                ),
              ],
            ),
          ),
          UIHelper.verticalSpaceMd,

          // Upload Area
          _buildUploadArea(),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _showUploadOptions,
      child: Container(
        width: double.infinity,
        height: 120.h,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 32.w, color: Colors.grey[600]),
            UIHelper.verticalSpaceSm,
            CustomText(
              text: "Take Document Photo".tr,
              fontSize: FontConstants.font_14,
              weight: FontWeightConstants.medium,
              color: Colors.grey[700],
            ),
            SizedBox(height: 4.h),
            CustomText(
              text: "or Upload from Gallery".tr,
              fontSize: FontConstants.font_12,
              weight: FontWeightConstants.regular,
              color: Colors.grey[500],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadedDocumentsSection() {
    return Consumer<SettingProvider>(
      builder: (context, settingProvider, child) {
        final missingRequired = _getMissingRequiredDocuments(settingProvider);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              CustomText(
                text: "Uploaded Documents".tr,
                fontSize: FontConstants.font_20,
                weight: FontWeightConstants.bold,
                color: Colors.black,
              ),
              UIHelper.verticalSpaceMd,

              // Required Documents Notice (if any are missing)
              if (missingRequired.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.orange.shade200, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade700,
                        size: 20.w,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: CustomText(
                          text:
                              "${"Required Documents Missing".tr}: ${missingRequired.join(", ")}",
                          fontSize: FontConstants.font_12,
                          weight: FontWeightConstants.medium,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),

                UIHelper.verticalSpaceMd,
              ],

              // Documents List
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_uploadedDocuments.isEmpty && missingRequired.isEmpty)
                Container(
                  padding: EdgeInsets.all(32.w),
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 64.w,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16.h),
                      CustomText(
                        text: "No documents uploaded yet".tr,
                        fontSize: FontConstants.font_16,
                        weight: FontWeightConstants.medium,
                        color: Colors.grey[600],
                      ),
                      SizedBox(height: 8.h),
                      CustomText(
                        text: "Upload your first document to get started".tr,
                        fontSize: FontConstants.font_14,
                        weight: FontWeightConstants.regular,
                        color: Colors.grey[500],
                      ),
                    ],
                  ),
                )
              else ...[
                // Show missing required documents first
                ...missingRequired
                    .map(
                      (docType) => _buildRequiredDocumentPlaceholder(docType),
                    )
                    .toList(),
                // Then show uploaded documents
                ..._uploadedDocuments
                    .map((document) => _buildDocumentCard(document))
                    .toList(),
              ],
            ],
          ),
        );
      },
    );
  }

  // Build placeholder card for required documents that haven't been uploaded
  Widget _buildRequiredDocumentPlaceholder(String documentType) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade200.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showUploadOptionsWithType(documentType);
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.orange.shade300, width: 1),
            ),
            child: Row(
              children: [
                // Compact Icon
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    _getDocumentIcon(documentType),
                    color: Colors.white,
                    size: 22.w,
                  ),
                ),
                SizedBox(width: 12.w),

                // Document Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomText(
                              text: documentType.tr,
                              fontSize: FontConstants.font_14,
                              weight: FontWeightConstants.semiBold,
                              color: Colors.orange.shade900,
                              maxlines: 1,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          // Compact Required Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade700,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: CustomText(
                              text: "Required".tr,
                              fontSize: FontConstants.font_9,
                              weight: FontWeightConstants.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3.h),
                      CustomText(
                        text: "Tap to upload".tr,
                        fontSize: FontConstants.font_11,
                        weight: FontWeightConstants.regular,
                        color: Colors.orange.shade700,
                        maxlines: 1,
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 8.w),

                // Compact Upload Icon Button
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade600, Colors.orange.shade700],
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.upload_rounded,
                    color: Colors.white,
                    size: 18.w,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Get appropriate icon for document type
  IconData _getDocumentIcon(String documentType) {
    final lowerType = documentType.toLowerCase();
    if (lowerType.contains('identity') || lowerType.contains('id card')) {
      return Icons.badge_outlined;
    } else if (lowerType.contains('license') ||
        lowerType.contains('professional')) {
      return Icons.verified_outlined;
    } else if (lowerType.contains('resume') ||
        lowerType.contains('experience')) {
      return Icons.work_outline;
    } else if (lowerType.contains('bank') || lowerType.contains('account')) {
      return Icons.account_balance_outlined;
    } else if (lowerType.contains('application') ||
        lowerType.contains('self intro')) {
      return Icons.description_outlined;
    } else {
      return Icons.description_outlined;
    }
  }

  Widget _buildDocumentCard(Map<String, dynamic> document) {
    // Get status color and text color based on status
    Color statusColor;
    Color textColor;

    switch (document['status']?.toString().toLowerCase()) {
      case 'approved':
        statusColor = greenColor;
        textColor = Colors.white;
        break;
      case 'rejected':
        statusColor = Color(0xFFF8D7DA);
        textColor = Colors.red;
        break;
      case 'under review':
      case 'pending':
        statusColor = Color(0xFFFFF3CD);
        textColor = Colors.black;
        break;
      default:
        statusColor = Colors.grey[300]!;
        textColor = Colors.black;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Document Icon - Clickable to open file
              Tooltip(
                message: 'Tap to open file'.tr,
                child: GestureDetector(
                  onTap: () => _openFileUrl(document['file']),
                  child: Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: _getFileIconColor(
                        _getFileNameFromUrl(document['file']),
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            _getFileIcon(_getFileNameFromUrl(document['file'])),
                            color: Colors.white,
                            size: 20.w,
                          ),
                        ),
                        // Small indicator that it's clickable
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.open_in_new,
                              size: 6.w,
                              color: _getFileIconColor(
                                _getFileNameFromUrl(document['file']),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // File Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: _getFileNameFromUrl(document['file']),
                      fontSize: FontConstants.font_14,
                      weight: FontWeightConstants.medium,
                      color: Colors.black,
                    ),
                    CustomText(
                      text: _formatFileInfo(document),
                      fontSize: FontConstants.font_12,
                      weight: FontWeightConstants.regular,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),

              // Delete Button
              GestureDetector(
                onTap: () => _deleteDocument(document['id']?.toString() ?? ''),
                child: Icon(Icons.delete, color: Colors.red, size: 20.w),
              ),
            ],
          ),

          UIHelper.verticalSpaceSm,

          // Document Type Dropdown
          Row(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 0.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(7.0),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Consumer<SettingProvider>(
                    builder: (context, settingProvider, child) {
                      final availableTypes = _getAvailableDocumentTypes(
                        settingProvider,
                      );
                      return DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value:
                              document['name'] ??
                              document['documentType'] ??
                              (availableTypes.isNotEmpty
                                  ? availableTypes.first
                                  : 'Other'),
                          isExpanded: true,
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey,
                            size: 16.w,
                          ),
                          items:
                              availableTypes.map((String type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: AutoSizeText(
                                    type.tr,
                                    maxLines: 1,
                                    minFontSize: 10,
                                    maxFontSize: 12,
                                  ),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              _updateDocumentType(
                                document['id']?.toString() ?? '',
                                newValue,
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),

              UIHelper.horizontalSpaceSm,
              // Status Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: CustomText(
                  text: (document['status'] ?? 'Unknown').toString().tr,
                  fontSize: FontConstants.font_12,
                  weight: FontWeightConstants.medium,
                  color: textColor,
                ),
              ),
            ],
          ),

          UIHelper.verticalSpaceSm,

          // Rejection Reason (if rejected)
          if (document['rejection_reason'] != null ||
              document['rejectionReason'] != null) ...[
            UIHelper.verticalSpaceSm,
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Color(0xFFF8D7DA),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: "Rejection Reason".tr,
                    fontSize: FontConstants.font_12,
                    weight: FontWeightConstants.bold,
                    color: Colors.red,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    text:
                        document['rejection_reason'] ??
                        document['rejectionReason'] ??
                        '',
                    fontSize: FontConstants.font_12,
                    weight: FontWeightConstants.regular,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper method to extract filename from URL
  String _getFileNameFromUrl(String? url) {
    if (url == null || url.isEmpty) return 'Unknown File'.tr;

    try {
      // Extract filename from URL path
      Uri uri = Uri.parse(url);
      String path = uri.path;
      String filename = path.split('/').last;

      // If filename is empty, use the full path
      if (filename.isEmpty) {
        filename = path;
      }

      return filename;
    } catch (e) {
      // If URL parsing fails, try to extract from the string directly
      String filename = url.split('/').last;
      return filename.isNotEmpty ? filename : 'Unknown File'.tr;
    }
  }

  // Helper method to get file extension
  String _getFileExtension(String filename) {
    if (filename.isEmpty) return '';
    List<String> parts = filename.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  // Helper method to get appropriate icon based on file extension
  IconData _getFileIcon(String filename) {
    String extension = _getFileExtension(filename);

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Helper method to get file icon color based on extension
  Color _getFileIconColor(String filename) {
    String extension = _getFileExtension(filename);

    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return Colors.green;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green.shade700;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'txt':
        return Colors.grey;
      case 'zip':
      case 'rar':
      case '7z':
        return Colors.purple;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
        return Colors.pink;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Colors.indigo;
      default:
        return primaryColorConsulor;
    }
  }

  // Helper method to open URL
  Future<void> _openFileUrl(String? url) async {
    print('url: $url');
    if (url == null || url.isEmpty) {
      Get.snackbar(
        'Error'.tr,
        'File URL not available'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      print('Attempting to parse URL: $url');
      Uri uri = Uri.parse(url);
      print('Parsed URI: $uri');

      // Try different launch modes
      bool canLaunch = await canLaunchUrl(uri);
      print('Can launch URL: $canLaunch');

      if (canLaunch) {
        print('Launching URL with external application mode...');
        bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('Launch result: $launched');

        if (!launched) {
          // Try with platform default mode
          print('Trying with platform default mode...');
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
          print('Platform default launch result: $launched');

          if (!launched) {
            Get.snackbar(
              'Error'.tr,
              'Failed to open file. Please try opening manually.'.tr,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
          }
        }
      } else {
        // Try to open with different approach
        print('Cannot launch URL, trying alternative approach...');

        // For web URLs, try opening in browser
        if (url.startsWith('http://') || url.startsWith('https://')) {
          print('Trying to open as web URL...');
          bool launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
            webOnlyWindowName: '_blank',
          );
          print('Web launch result: $launched');

          if (!launched) {
            Get.snackbar(
              'Error'.tr,
              'Cannot open file URL. URL: $url'.tr,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: Duration(seconds: 5),
            );
          }
        } else {
          Get.snackbar(
            'Error'.tr,
            'Cannot open file URL. Please check if the file exists.'.tr,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      print('Exception occurred: $e');
      Get.snackbar(
        'Error'.tr,
        'Failed to open file: ${e.toString()}'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
    }
  }

  // Helper method to format file information
  String _formatFileInfo(Map<String, dynamic> document) {
    String date = document['created_at'] ?? document['uploadDate'] ?? '';
    String size = document['file_size'] ?? document['fileSize'] ?? '';

    if (date.isNotEmpty && size.isNotEmpty) {
      return "$date • $size";
    } else if (date.isNotEmpty) {
      return date;
    } else if (size.isNotEmpty) {
      return size;
    } else {
      return 'No additional info'.tr;
    }
  }

  Widget _buildInformationNote() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            width: 24.w,
            height: 24.w,
            decoration: BoxDecoration(
              color: Color(0xFF1976D2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info, color: Colors.white, size: 16.w),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: CustomText(
              text:
                  "Once approved by our administrators, you will be able to provide counseling services normally."
                      .tr,
              fontSize: FontConstants.font_14,
              weight: FontWeightConstants.regular,
              color: Color(0xFF1976D2),
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 12.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    children: [
                      CustomText(
                        text: "Upload Document".tr,
                        fontSize: FontConstants.font_18,
                        weight: FontWeightConstants.semiBold,
                        color: Colors.black,
                      ),
                      UIHelper.verticalSpaceMd,

                      // Camera Option
                      _buildUploadOption(
                        icon: Icons.camera_alt,
                        title: "Take Photo".tr,
                        subtitle: "Capture document with camera".tr,
                        onTap: () {
                          Navigator.pop(context);
                          _takeDocumentPhoto();
                        },
                      ),

                      UIHelper.verticalSpaceSm,

                      // Gallery Option
                      _buildUploadOption(
                        icon: Icons.photo_library,
                        title: "Choose from Gallery".tr,
                        subtitle: "Select document from gallery".tr,
                        onTap: () {
                          Navigator.pop(context);
                          _pickFromGallery();
                        },
                      ),

                      UIHelper.verticalSpaceSm,

                      // File Option
                      _buildUploadOption(
                        icon: Icons.attach_file,
                        title: "Choose File".tr,
                        subtitle: "Select PDF or image file".tr,
                        onTap: () {
                          Navigator.pop(context);
                          _pickFile();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: primaryColorConsulor,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: Colors.white, size: 24.w),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: title,
                    fontSize: FontConstants.font_16,
                    weight: FontWeightConstants.medium,
                    color: Colors.black,
                  ),
                  CustomText(
                    text: subtitle,
                    fontSize: FontConstants.font_12,
                    weight: FontWeightConstants.regular,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16.w),
          ],
        ),
      ),
    );
  }

  void _takeDocumentPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        _processUploadedFile(image.path, image.name);
      }
    } catch (e) {
      Get.snackbar(
        'Error'.tr,
        'Failed to capture image: $e'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        _processUploadedFile(image.path, image.name);
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

  void _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        _processUploadedFile(file.path!, file.name);
      }
    } catch (e) {
      Get.snackbar(
        'Error'.tr,
        'Failed to pick file: $e'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _processUploadedFile(
    String filePath,
    String fileName, {
    String? preSelectedType,
  }) async {
    // Show document type selection dialog, or use pre-selected type
    String? selectedType = preSelectedType ?? await _showDocumentTypeDialog();

    if (selectedType != null) {
      // Prepare document data for upload
      List<Map<String, dynamic>> documents = [
        {'filePath': filePath, 'name': selectedType},
      ];

      // Upload document via API
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final result = await userViewModel.uploadDocuments(context, documents);

      if (result != null) {
        // Reload documents list
        await _loadUploadedDocuments();
      }
    }
  }

  // Show upload options with pre-selected document type
  void _showUploadOptionsWithType(String documentType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 12.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    children: [
                      CustomText(
                        text: "Upload ${documentType.tr}".tr,
                        fontSize: FontConstants.font_18,
                        weight: FontWeightConstants.semiBold,
                        color: Colors.black,
                      ),
                      UIHelper.verticalSpaceMd,

                      // Camera Option
                      _buildUploadOption(
                        icon: Icons.camera_alt,
                        title: "Take Photo".tr,
                        subtitle: "Capture document with camera".tr,
                        onTap: () {
                          Navigator.pop(context);
                          _takeDocumentPhotoWithType(documentType);
                        },
                      ),

                      UIHelper.verticalSpaceSm,

                      // Gallery Option
                      _buildUploadOption(
                        icon: Icons.photo_library,
                        title: "Choose from Gallery".tr,
                        subtitle: "Select document from gallery".tr,
                        onTap: () {
                          Navigator.pop(context);
                          _pickFromGalleryWithType(documentType);
                        },
                      ),

                      UIHelper.verticalSpaceSm,

                      // File Option
                      _buildUploadOption(
                        icon: Icons.attach_file,
                        title: "Choose File".tr,
                        subtitle: "Select PDF or image file".tr,
                        onTap: () {
                          Navigator.pop(context);
                          _pickFileWithType(documentType);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _takeDocumentPhotoWithType(String documentType) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        _processUploadedFile(
          image.path,
          image.name,
          preSelectedType: documentType,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error'.tr,
        'Failed to capture image: $e'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _pickFromGalleryWithType(String documentType) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        _processUploadedFile(
          image.path,
          image.name,
          preSelectedType: documentType,
        );
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

  void _pickFileWithType(String documentType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        _processUploadedFile(
          file.path!,
          file.name,
          preSelectedType: documentType,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error'.tr,
        'Failed to pick file: $e'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Show document type selection dialog
  Future<String?> _showDocumentTypeDialog() async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        final settingProvider = Provider.of<SettingProvider>(
          context,
          listen: false,
        );
        final availableTypes = _getAvailableDocumentTypes(settingProvider);

        return AlertDialog(
          title: CustomText(
            text: 'Select Document Type'.tr,
            fontSize: FontConstants.font_18,
            weight: FontWeightConstants.semiBold,
          ),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableTypes.length,
              itemBuilder: (context, index) {
                final type = availableTypes[index];
                return ListTile(
                  title: CustomText(
                    text: type.tr,
                    fontSize: FontConstants.font_14,
                    weight: FontWeightConstants.medium,
                  ),
                  onTap: () {
                    Navigator.of(context).pop(type);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: CustomText(
                text: 'Cancel'.tr,
                fontSize: FontConstants.font_14,
                weight: FontWeightConstants.medium,
                color: Colors.grey,
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteDocument(String documentId) async {
    // Show confirmation dialog first
    bool? confirmed = await _showDeleteConfirmationDialog();

    if (confirmed == true) {
      try {
        // Delete document via API
        final userViewModel = Provider.of<UserViewModel>(
          context,
          listen: false,
        );
        final success = await userViewModel.deleteDocument(documentId);

        if (success) {
          // Reload documents list
          await _loadUploadedDocuments();

          Get.snackbar(
            'Deleted'.tr,
            'Document deleted successfully'.tr,
            backgroundColor: primaryColorConsulor,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'Error'.tr,
            'Failed to delete document'.tr,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } catch (e) {
        Get.snackbar(
          'Error'.tr,
          'Failed to delete document: ${e.toString()}'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  // Modern confirmation dialog for document deletion
  Future<bool?> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          elevation: 10,
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    size: 30.w,
                    color: Colors.red,
                  ),
                ),

                SizedBox(height: 20.h),

                // Title
                CustomText(
                  text: 'Delete Document',
                  fontSize: FontConstants.font_18,
                  weight: FontWeightConstants.bold,
                  color: Colors.black,
                  align: TextAlign.center,
                ),

                SizedBox(height: 12.h),

                // Message
                CustomText(
                  text:
                      'Are you sure you want to delete this document? This action cannot be undone.',
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.regular,
                  color: Colors.grey[600],
                  align: TextAlign.center,
                  maxlines: 3,
                ),

                SizedBox(height: 24.h),

                // Action Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: Container(
                        height: 45.h,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                          child: CustomText(
                            text: 'Cancel'.tr,
                            fontSize: FontConstants.font_14,
                            weight: FontWeightConstants.medium,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 12.w),

                    // Delete Button
                    Expanded(
                      child: Container(
                        height: 45.h,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            elevation: 0,
                          ),
                          child: CustomText(
                            text: 'Delete'.tr,
                            fontSize: FontConstants.font_14,
                            weight: FontWeightConstants.medium,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateDocumentType(String documentId, String newType) async {
    // Show confirmation dialog first
    bool? confirmed = await _showUpdateConfirmationDialog(newType);

    if (confirmed == true) {
      try {
        // You might need to implement an update document type API endpoint
        // For now, we'll just update the local state
        setState(() {
          final documentIndex = _uploadedDocuments.indexWhere(
            (doc) => doc['id']?.toString() == documentId,
          );
          if (documentIndex != -1) {
            _uploadedDocuments[documentIndex]['document_type'] = newType;
          }
        });

        Get.snackbar(
          'Updated'.tr,
          'Document type updated to $newType'.tr,
          backgroundColor: primaryColorConsulor,
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
      } catch (e) {
        Get.snackbar(
          'Error'.tr,
          'Failed to update document type'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  // Modern confirmation dialog for document type update
  Future<bool?> _showUpdateConfirmationDialog(String newType) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          elevation: 10,
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    color: primaryColorConsulor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_document,
                    size: 30.w,
                    color: primaryColorConsulor,
                  ),
                ),

                SizedBox(height: 20.h),

                // Title
                CustomText(
                  text: 'Update Document Type'.tr,
                  fontSize: FontConstants.font_18,
                  weight: FontWeightConstants.bold,
                  color: Colors.black,
                  align: TextAlign.center,
                ),

                SizedBox(height: 12.h),

                // Message
                CustomText(
                  text:
                      'Are you sure you want to change the document type to "$newType"?'
                          .tr,
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.regular,
                  color: Colors.grey[600],
                  align: TextAlign.center,
                  maxlines: 3,
                ),

                SizedBox(height: 24.h),

                // Action Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: Container(
                        height: 45.h,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                          child: CustomText(
                            text: 'Cancel'.tr,
                            fontSize: FontConstants.font_14,
                            weight: FontWeightConstants.medium,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 12.w),

                    // Confirm Button
                    Expanded(
                      child: Container(
                        height: 45.h,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColorConsulor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            elevation: 0,
                          ),
                          child: CustomText(
                            text: 'Update'.tr,
                            fontSize: FontConstants.font_14,
                            weight: FontWeightConstants.medium,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
