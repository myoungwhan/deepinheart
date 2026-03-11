import 'package:cached_network_image/cached_network_image.dart';
import 'package:deepinheart/Controller/Model/favorite_client_model.dart';
import 'package:deepinheart/Controller/Viewmodel/counselor_appointment_provider.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class FavClients extends StatefulWidget {
  const FavClients({Key? key}) : super(key: key);

  @override
  State<FavClients> createState() => _FavClientsState();
}

class _FavClientsState extends State<FavClients> {
  @override
  void initState() {
    super.initState();
    _loadFavoriteClients();
  }

  Future<void> _loadFavoriteClients() async {
    final provider = Provider.of<CounselorAppointmentProvider>(
      context,
      listen: false,
    );
    await provider.fetchFavoriteClients(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CounselorAppointmentProvider>(
      builder: (context, provider, child) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: borderColor),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: SizedBox(
            width: Get.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UIHelper.verticalSpaceSm,
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        align: TextAlign.start,
                        text: 'Favorite Clients'.tr,
                        fontSize: FontConstants.font_18,
                        height: 1.3,
                        weight: FontWeightConstants.semiBold,
                        color: Color(0xFF111726),
                      ),
                      Spacer(),
                      CustomText(
                        text: "View All".tr,
                        color: primaryColorConsulor,
                        fontSize: FontConstants.font_14,
                        weight: FontWeightConstants.medium,
                      ),
                    ],
                  ),
                ),
                Divider(thickness: 1, color: borderColor),
                UIHelper.verticalSpaceSm,
                // Content based on state
                _buildContent(provider),
                UIHelper.verticalSpaceMd,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(CounselorAppointmentProvider provider) {
    if (provider.isFavoriteClientsLoading) {
      return _buildLoadingState();
    }

    if (provider.favoriteClientsError != null) {
      return _buildErrorState(provider.favoriteClientsError!);
    }

    if (provider.favoriteClients.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: provider.favoriteClients.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder:
          (context, index) => _buildClientCard(provider.favoriteClients[index]),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Center(
        child: CircularProgressIndicator(
          color: primaryColorConsulor,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 32.w),
          SizedBox(height: 8.h),
          CustomText(
            text: 'Failed to load clients'.tr,
            fontSize: FontConstants.font_14,
            color: lightGREY,
          ),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: _loadFavoriteClients,
            child: CustomText(
              text: 'Tap to retry'.tr,
              fontSize: FontConstants.font_14,
              color: primaryColorConsulor,
              weight: FontWeightConstants.medium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.people_outline, color: lightGREY, size: 40.w),
            SizedBox(height: 8.h),
            CustomText(
              text: 'No favorite clients yet'.tr,
              fontSize: FontConstants.font_14,
              color: lightGREY,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(FavoriteClient client) {
    // Generate avatar colors based on client name
    final colorIndex = client.name.hashCode % _avatarColors.length;
    final avatarColor = _avatarColors[colorIndex]['background']!;
    final initialColor = _avatarColors[colorIndex]['text']!;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          _buildAvatar(client, avatarColor, initialColor),
          SizedBox(width: 12.w),

          // Name and details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: client.name,
                  fontSize: FontConstants.font_16,
                  weight: FontWeightConstants.semiBold,
                  color: Color(0xFF111726),
                ),
                SizedBox(height: 4.h),
                CustomText(
                  text: _buildSubtitle(client),
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.regular,
                  color: lightGREY,
                ),
              ],
            ),
          ),

          // Chat icon
          Visibility(
            visible: false,
            child: Container(
              width: 40.w,
              height: 40.w,
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: primaryColorConsulor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(AppIcons.chatsvg),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
    FavoriteClient client,
    Color backgroundColor,
    Color textColor,
  ) {
    if (client.hasProfileImage) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: client.profileImage!,
          width: 48.w,
          height: 48.w,
          fit: BoxFit.cover,
          placeholder:
              (context, url) => Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: backgroundColor.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor,
                    ),
                  ),
                ),
              ),
          errorWidget:
              (context, url, error) => _buildInitialAvatar(
                client.initial,
                backgroundColor,
                textColor,
              ),
        ),
      );
    }

    return _buildInitialAvatar(client.initial, backgroundColor, textColor);
  }

  Widget _buildInitialAvatar(
    String initial,
    Color backgroundColor,
    Color textColor,
  ) {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: CustomText(
          text: initial,
          fontSize: FontConstants.font_18,
          weight: FontWeightConstants.bold,
          color: textColor,
        ),
      ),
    );
  }

  String _buildSubtitle(FavoriteClient client) {
    final parts = <String>[];

    // if (client.sessionCount > 0) {
    parts.add('${client.sessionCount} ${"sessions".tr}');
    //  }

    // if (client.rating > 0) {
    parts.add('${"Rating".tr} ${client.rating.toStringAsFixed(1)}');
    // }

    return parts.isNotEmpty ? parts.join(' · ') : 'New client'.tr;
  }

  // Predefined avatar colors
  static const List<Map<String, Color>> _avatarColors = [
    {
      'background': Color(0xFFE8D5F2), // Light purple
      'text': Color(0xFF8B5CF6), // Dark purple
    },
    {
      'background': Color(0xFFD1FAE5), // Light green
      'text': Color(0xFF10B981), // Dark green
    },
    {
      'background': Color(0xFFDBEAFE), // Light blue
      'text': Color(0xFF3B82F6), // Dark blue
    },
    {
      'background': Color(0xFFFEE2E2), // Light red
      'text': Color(0xFFEF4444), // Dark red
    },
    {
      'background': Color(0xFFFEF3C7), // Light yellow
      'text': Color(0xFFF59E0B), // Dark yellow
    },
    {
      'background': Color(0xFFE0E7FF), // Light indigo
      'text': Color(0xFF6366F1), // Dark indigo
    },
  ];
}
