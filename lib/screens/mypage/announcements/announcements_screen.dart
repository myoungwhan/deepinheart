import 'package:deepinheart/Controller/Model/announcement_model.dart';
import 'package:deepinheart/Controller/Viewmodel/setting_provider.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_appbar.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({Key? key}) : super(key: key);

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAnnouncements();
    });
  }

  Future<void> _fetchAnnouncements() async {
    final settingProvider = Provider.of<SettingProvider>(
      context,
      listen: false,
    );
    await settingProvider.fetchAnnouncements(context);
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String dateString) {
    if (dateString.isEmpty) return '—';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  /// Card: show start date, or created_at if start is empty.
  String _dateOrCreatedForDisplay(EmergencyAnnouncement a) {
    if (a.startDate.isNotEmpty) return _formatDate(a.startDate);
    if (a.createdAt.isNotEmpty) return _formatDateTime(a.createdAt);
    return '—';
  }

  /// Detail: show "Date: start - end" or "Date: created" when start/end are empty.
  String _dateRangeForDetail(EmergencyAnnouncement a) {
    final hasStart = a.startDate.isNotEmpty;
    final hasEnd = a.endDate.isNotEmpty;
    if (hasStart && hasEnd) {
      return "${"Date".tr}: ${_formatDateTime(a.startDate)} - ${_formatDateTime(a.endDate)}";
    }
    if (hasStart) return "${"Date".tr}: ${_formatDateTime(a.startDate)}";
    if (a.createdAt.isNotEmpty) return "${"Date".tr}: ${_formatDateTime(a.createdAt)}";
    return "${"Date".tr}: —";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        title: "Announcements".tr,
        isLogo: false,
        centerTitle: false,
        action: [Container()],
      ),
      body: Consumer<SettingProvider>(
        builder: (context, settingProvider, child) {
          if (settingProvider.isLoadingAnnouncements) {
            return Center(child: CircularProgressIndicator());
          }

          final announcementsList =
              settingProvider.announcements?.data ?? <EmergencyAnnouncement>[];

          if (announcementsList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.announcement_outlined,
                    size: 64.w,
                    color: Colors.grey.shade400,
                  ),
                  UIHelper.verticalSpaceMd,
                  CustomText(
                    text: "No announcements available".tr,
                    fontSize: FontConstants.font_16,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            );
          }

          // Sort: top_fixed first, then by created_at descending
          final sortedAnnouncements = <EmergencyAnnouncement>[
            ...announcementsList,
          ]..sort((a, b) {
            if (a.topFixed && !b.topFixed) return -1;
            if (!a.topFixed && b.topFixed) return 1;
            try {
              final dateA = DateTime.parse(a.createdAt);
              final dateB = DateTime.parse(b.createdAt);
              return dateB.compareTo(dateA);
            } catch (e) {
              return 0;
            }
          });

          return RefreshIndicator(
            onRefresh: _fetchAnnouncements,
            child: ListView.builder(
              padding: EdgeInsets.all(15.w),
              itemCount: sortedAnnouncements.length,
              itemBuilder: (context, index) {
                final announcement = sortedAnnouncements[index];
                return _buildAnnouncementCard(announcement);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnnouncementCard(EmergencyAnnouncement announcement) {
    final isActive =
        announcement.isActive && announcement.status.toLowerCase() == 'active';
    final isTopFixed = announcement.topFixed;

    return GestureDetector(
      onTap: () {
        _showAnnouncementDetail(announcement);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isTopFixed ? primaryColor : borderColor,
            width: isTopFixed ? 2 : 1,
          ),
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
            // Header with top fixed badge
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isTopFixed ? primaryColor.withOpacity(0.1) : null,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  topRight: Radius.circular(12.r),
                ),
              ),
              child: Row(
                children: [
                  if (isTopFixed) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: CustomText(
                        text: "Top Fixed".tr,
                        fontSize: FontConstants.font_10,
                        weight: FontWeightConstants.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],
                  Expanded(
                    child: CustomText(
                      text: announcement.title,
                      fontSize: FontConstants.font_16,
                      weight: FontWeightConstants.bold,
                      color: const Color(0xFF111726),
                      maxlines: 2,
                    ),
                  ),
                  if (!isActive)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: CustomText(
                        text: announcement.statusLabel,
                        fontSize: FontConstants.font_10,
                        color: Colors.grey.shade700,
                      ),
                    ),
                ],
              ),
            ),

            // Content preview
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Remove HTML tags for preview
                  CustomText(
                    text: _stripHtmlTags(announcement.content),
                    fontSize: FontConstants.font_14,
                    color: const Color(0xFF374151),
                    maxlines: 3,
                    height: 1.5,
                  ),
                  UIHelper.verticalSpaceSm,
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14.w,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 4.w),
                      CustomText(
                        text: _dateOrCreatedForDisplay(announcement),
                        fontSize: FontConstants.font_12,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 12.w),
                      Icon(
                        Icons.visibility,
                        size: 14.w,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 4.w),
                      CustomText(
                        text: "${announcement.views} ${"views".tr}",
                        fontSize: FontConstants.font_12,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stripHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }

  void _showAnnouncementDetail(EmergencyAnnouncement announcement) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          constraints: BoxConstraints(maxHeight: Get.height * 0.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        text: announcement.title,
                        fontSize: FontConstants.font_18,
                        weight: FontWeightConstants.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date and views info
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16.w,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 8.w),
                          CustomText(
                            text: _dateRangeForDetail(announcement),
                            fontSize: FontConstants.font_12,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                      UIHelper.verticalSpaceSm,
                      Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 16.w,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 8.w),
                          CustomText(
                            text: "${"Views".tr}: ${announcement.views}",
                            fontSize: FontConstants.font_12,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                      UIHelper.verticalSpaceMd,

                      // Content (HTML)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: _buildHtmlContent(announcement.content),
                      ),
                    ],
                  ),
                ),
              ),

              // Close button
              Padding(
                padding: EdgeInsets.all(16.w),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: CustomText(
                      text: "Close".tr,
                      fontSize: FontConstants.font_14,
                      weight: FontWeightConstants.semiBold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHtmlContent(String html) {
    return Html(
      data: html,

      style: {
        "body": Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(FontConstants.font_14),
          color: const Color(0xFF374151),
        ),
        "p": Style(
          margin: Margins.only(bottom: 8),
          fontSize: FontSize(FontConstants.font_14),
        ),
        "ul": Style(
          margin: Margins.only(left: 16, bottom: 8),
          padding: HtmlPaddings.zero,
        ),
        "li": Style(
          margin: Margins.only(bottom: 4),
          fontSize: FontSize(FontConstants.font_14),
        ),
        "strong": Style(fontWeight: FontWeight.w600),
        "b": Style(fontWeight: FontWeight.w600),
      },
    );
  }
}
