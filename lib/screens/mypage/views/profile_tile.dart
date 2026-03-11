import 'package:deepinheart/main.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Assuming you already have this

class ProfileTile extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String phone;
  final String email;
  final VoidCallback onEditProfile;

  const ProfileTile({
    Key? key,
    required this.imageUrl,
    required this.name,
    required this.phone,
    required this.email,
    required this.onEditProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      decoration: BoxDecoration(
        color: isMainDark ? Color(0xff2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Image
          Container(
            width: 70,
            height: 70,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Color(0xFFF2F4F5),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Color(0xFF246595), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
          ),

          UIHelper.horizontalSpaceSm,

          // Profile Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + Edit Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CustomText(
                        text: name,
                        fontSize: FontConstants.font_16,
                        weight: FontWeightConstants.medium,

                        align: TextAlign.start,
                      ),
                    ),
                    GestureDetector(
                      onTap: onEditProfile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Color(0xFFD0D5DA),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: Colors.grey[700]),
                            const SizedBox(width: 4),
                            CustomText(
                              text: 'Edit Profile'.tr,
                              fontSize: FontConstants.font_12,
                              weight: FontWeight.w400,
                              color: Colors.grey[700]!,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // const SizedBox(height: 6),

                // Phone
                phone.isEmpty
                    ? Container()
                    : CustomText(
                      text: phone,
                      fontSize: FontConstants.font_14,
                      weight: FontWeight.w400,
                      color: isMainDark ? Colors.white70 : Colors.grey[700]!,
                    ),

                const SizedBox(height: 4),

                // Email
                CustomText(
                  text: email,
                  fontSize: FontConstants.font_14,
                  weight: FontWeight.w400,
                  color: isMainDark ? Colors.white70 : Colors.grey[700]!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
