import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AttachmentModal extends StatelessWidget {
  final Function(AttachmentType) onAttachmentSelected;

  const AttachmentModal({Key? key, required this.onAttachmentSelected})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: greyColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Title
          Padding(
            padding: EdgeInsets.all(24.w),
            child: CustomText(
              text: 'Attachments',
              fontSize: FontConstants.font_18,
              weight: FontWeightConstants.semiBold,
              color: Colors.black,
            ),
          ),

          // Attachment options
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Color(0xFF3B82F6), // Light blue
                  onTap: () {
                    Navigator.pop(context);
                    onAttachmentSelected(AttachmentType.camera);
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: Color(0xFF10B981), // Light green
                  onTap: () {
                    Navigator.pop(context);
                    onAttachmentSelected(AttachmentType.gallery);
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.attach_file,
                  label: 'File',
                  color: Color(0xFF8B5CF6), // Light purple
                  onTap: () {
                    Navigator.pop(context);
                    onAttachmentSelected(AttachmentType.file);
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 32.h),

          // Divider
          Container(
            height: 1.h,
            color: borderColor,
            margin: EdgeInsets.symmetric(horizontal: 24.w),
          ),

          SizedBox(height: 16.h),

          // Cancel button
          Padding(
            padding: EdgeInsets.only(bottom: 24.h),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                margin: EdgeInsets.symmetric(horizontal: 24.w),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: CustomText(
                    text: 'Cancel',
                    fontSize: FontConstants.font_16,
                    weight: FontWeightConstants.medium,
                    color: greyColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 28.w),
          ),
          SizedBox(height: 12.h),
          CustomText(
            text: label,
            fontSize: FontConstants.font_14,
            weight: FontWeightConstants.medium,
            color: Colors.black,
          ),
        ],
      ),
    );
  }
}

enum AttachmentType { camera, gallery, file }
