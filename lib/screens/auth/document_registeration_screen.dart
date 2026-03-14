import 'dart:io';
import 'package:deepinheart/screens_consoler/dashboard_screen.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:deepinheart/Controller/Viewmodel/loading_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:deepinheart/screens/auth/login_View.dart';

class DocumentRegistrationScreen extends StatefulWidget {
  @override
  _DocumentRegistrationScreenState createState() =>
      _DocumentRegistrationScreenState();
}

class _DocumentRegistrationScreenState
    extends State<DocumentRegistrationScreen> {
  File? _selectedDocument;
  String? _selectedFileName;
  final ImagePicker _picker = ImagePicker();

  // Registration data from previous screen
  String? name;
  String? nickName;
  String? email;
  String? phone;
  String? password;
  String? passwordConfirmation;
  List<int>? category_id;
  List<int>? taxonomie_id;

  @override
  void initState() {
    super.initState();
    _getRegistrationData();
  }

  void _getRegistrationData() {
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      name = arguments['name'];
      nickName = arguments['nickName'];
      email = arguments['email'];
      phone = arguments['phone'];
      password = arguments['password'];
      passwordConfirmation = arguments['passwordConfirmation'];
      category_id = List<int>.from(arguments['category_id'] ?? []);
      taxonomie_id = List<int>.from(arguments['taxonomie_id'] ?? []);

      print("Registration data received:");
      print("Name: $name");
      print("Email: $email");
      print("Phone: $phone");
      print("taxonomie_id: $taxonomie_id");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedDocument = File(pickedFile.path);
          _selectedFileName = pickedFile.name;
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: CustomText(text: "Error selecting image: $e")),
      );
    }
  }

  Future<void> _pickPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedDocument = File(result.files.single.path!);
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      print("Error picking PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: CustomText(text: "Error selecting PDF: $e")),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: CustomText(
            text: "Select Source".tr,
            weight: FontWeightConstants.medium,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: CustomText(text: "Take Photo".tr),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: CustomText(text: "Choose from Gallery".tr),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.picture_as_pdf),
                title: CustomText(text: "Select PDF File".tr),
                onTap: () {
                  Navigator.pop(context);
                  _pickPDF();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitDocuments() async {
    if (_selectedDocument == null) {
      UIHelper.showBottomFlash(
        context,
        title: "",
        message: "Please upload a document first".tr,
        isError: true,
      );
      return;
    }

    // Check file size (10MB limit)
    if (_selectedDocument!.lengthSync() > 10 * 1024 * 1024) {
      UIHelper.showBottomFlash(
        context,
        title: "",
        message: "File size exceeds 10MB limit".tr,
        isError: true,
      );
      return;
    }

    // Validate registration data
    if (name == null || email == null || phone == null || password == null) {
      UIHelper.showBottomFlash(
        context,
        title: "",
        message: "Registration data is missing".tr,
        isError: true,
      );
      return;
    }

    try {
      LoadingProvider loadingProvider = context.read<LoadingProvider>();
      UserViewModel userViewModel = context.read<UserViewModel>();

      loadingProvider.showLoading();

      // Format phone number
      String phoneNumber = phone!;
      if (phoneNumber.startsWith('++')) {
        phoneNumber = phoneNumber.substring(1);
      }
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+$phoneNumber';
      }

      print("Submitting counselor registration with document:");
      print("Document path: ${_selectedDocument!.path}");
      print("Phone: $phoneNumber");

      // Call registration API with document
      // userDataHandling will handle success/error messages and navigation
      await userViewModel.registerUserWithAPI(
        context: context,
        name: name!,
        nickName: nickName ?? name!,
        role: enumUserTypes.counselor.name,
        email: email!,
        phone: phoneNumber,
        password: password!,
        passwordConfirmation: passwordConfirmation!,
        documentPath: _selectedDocument!.path,
        category_id: category_id ?? [],
        taxonomie_id: taxonomie_id ?? [],
      );

      // userDataHandling handles loading state and navigation
    } catch (e) {
      LoadingProvider loadingProvider = context.read<LoadingProvider>();
      loadingProvider.hideLoading();

      print("Counselor registration error: $e");
      UIHelper.showBottomFlash(
        context,
        title: "",
        message: "Registration failed: ${e.toString()}",
        isError: true,
      );
    }
  }

  Widget _buildDocumentPreview() {
    if (_selectedDocument == null) {
      return Container(
        width: 256,
        height: 320,
        alignment: Alignment.center,
        child: Image.asset('images/certificate.png'),
      );
    }

    // Check if it's a PDF file
    if (_selectedFileName?.toLowerCase().endsWith('.pdf') ?? false) {
      return Stack(
        children: [
          Container(
            width: 256,
            height: 320,
            decoration: BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFF246595), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.picture_as_pdf, size: 64, color: Color(0xFF246595)),
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: CustomText(
                    text: _selectedFileName ?? 'PDF Document',
                    color: Color(0xFF374050),
                    fontSize: 14,
                    weight: FontWeightConstants.medium,
                    align: TextAlign.center,
                    maxlines: 2,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.red),
              onPressed: () {
                setState(() {
                  _selectedDocument = null;
                  _selectedFileName = null;
                });
              },
            ),
          ),
        ],
      );
    } else {
      // It's an image file
      return Stack(
        children: [
          Container(
            width: 256,
            height: 320,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: FileImage(_selectedDocument!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.red),
              onPressed: () {
                setState(() {
                  _selectedDocument = null;
                  _selectedFileName = null;
                });
              },
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF111726)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: CustomText(
          text: "Document Registration".tr,
          color: Color(0xFF111726),
          fontSize: 18,
          weight: FontWeightConstants.semiBold,
          height: 1.56,
        ),
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Introduction text
              CustomText(
                text:
                    'Please upload documents such as certificates, experience records, education credentials, and training materials required for counselor activities. Documents will be approved after admin review.'.tr,
                color: Color(0xFF374050),
                weight: FontWeightConstants.regular,
                height: 1.63,
              ),

              SizedBox(height: 16),

              // File upload guidelines
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF374050),
                          size: 21,
                        ),
                        SizedBox(width: 8),
                        CustomText(
                          text: 'File Upload Guidelines'.tr,
                          color: Color(0xFF374050),
                          fontSize: 14,
                          weight: FontWeightConstants.medium,
                          height: 1.43,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    CustomText(
                      text: '• Allowed file formats: PDF, JPG, PNG'.tr,
                      color: Color(0xFF4A5462),
                      fontSize: 12,
                      weight: FontWeightConstants.regular,
                      height: 1.33,
                    ),
                    SizedBox(height: 4),
                    CustomText(
                      text: '• Maximum file size: 10MB'.tr,
                      color: Color(0xFF4A5462),
                      fontSize: 12,
                      weight: FontWeightConstants.regular,
                      height: 1.33,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Document preview
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Color(0xFFF9FAFA),
                  border: Border.all(width: 2, color: Color(0xFFE4E7EB)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: _buildDocumentPreview(),
                ),
              ),

              SizedBox(height: 32),

              // How to take photos section
              CustomText(
                text: 'How to Take Photos'.tr,
                color: Color(0xFF111726),
                fontSize: 18,
                weight: FontWeightConstants.semiBold,
                height: 1.56,
              ),

              SizedBox(height: 16),

              _buildInstructionStep(1, 'Clean the camera lens'.tr),
              _buildInstructionStep(2, 'Position to show all document content'.tr),
              _buildInstructionStep(3, 'Ensure text is clearly visible'.tr),
              _buildInstructionStep(4, 'Wait if screen appears blank'.tr),
              _buildInstructionStep(
                5,
                'Ensure text and photo information are sufficient for processing'.tr,
              ),

              SizedBox(height: 32),

              // Upload button
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 34),
                  decoration: BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    border: Border.all(width: 2, color: Color(0xFFD0D5DA)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 36,
                        color: Color(0xFF374050),
                      ),
                      SizedBox(height: 12),
                      CustomText(
                        text: 'Take Document Photo'.tr,
                        color: Color(0xFF374050),
                        fontSize: 14,
                        weight: FontWeightConstants.medium,
                        height: 1.43,
                        align: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      CustomText(
                        text: 'or Select from Album/PDF'.tr,
                        color: Color(0xFF6A7280),
                        fontSize: 12,
                        weight: FontWeightConstants.regular,
                        height: 1.33,
                        align: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Sign up button
              SizedBox(
                width: double.infinity,
                height: 53,
                child: ElevatedButton(
                  onPressed: _submitDocuments,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF246595),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: CustomText(
                    text: 'Sign Up'.tr,
                    color: Colors.white,
                    fontSize: 14,
                    weight: FontWeightConstants.medium,
                    height: 1.5,
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Footer text
              CustomText(
                text:
                    'You can start counseling activities normally after admin approval.'.tr,
                color: Color(0xFF6A7280),
                fontSize: 12,
                weight: FontWeightConstants.regular,
                height: 1.33,
                align: TextAlign.center,
                maxlines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(int stepNumber, String instruction) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: EdgeInsets.only(right: 12, top: 2),
            decoration: BoxDecoration(
              color: Color(0xFF246595),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CustomText(
                text: stepNumber.toString(),
                color: Colors.white,
                fontSize: 12,
                weight: FontWeightConstants.medium,
                height: 1.33,
              ),
            ),
          ),
          Expanded(
            child: CustomText(
              text: instruction,
              color: Color(0xFF374050),
              fontSize: 14,
              weight: FontWeightConstants.regular,
              height: 1.43,
            ),
          ),
        ],
      ),
    );
  }
}
