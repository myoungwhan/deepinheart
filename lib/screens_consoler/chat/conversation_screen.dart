import 'package:cached_network_image/cached_network_image.dart';
import 'package:deepinheart/screens/calls/chat_screen.dart';
import 'package:deepinheart/screens_consoler/chat/models/conversation_model.dart';
import 'package:deepinheart/screens_consoler/chat/providers/chat_provider.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/consuler_custom_nav_bar.dart';
import 'package:deepinheart/views/custom_appbar.dart';
import 'package:deepinheart/views/custom_nav_bar.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/custom_textfiled.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ConversationScreen extends StatefulWidget {
  bool isFromConsuler;
  ConversationScreen({Key? key, this.isFromConsuler = true}) : super(key: key);

  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  // Search controller
  final TextEditingController _searchController = TextEditingController();

  // Search query state
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.fetchConversations(context);
  }

  // Get filtered conversations based on search query
  List<ConversationData> _getFilteredConversations(
    List<ConversationData> conversations,
  ) {
    if (_searchQuery.isEmpty) {
      return conversations;
    }

    return conversations.where((conversation) {
      final name = conversation.clientName.toLowerCase();
      final lastMessage = conversation.displayMessage.toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || lastMessage.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(title: "Conversation".tr, action: [Container()]),
      bottomNavigationBar:
          widget.isFromConsuler
              ? ConsulerCustomBottomNav(1)
              : CustomBottomNav(2),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return RefreshIndicator(
            onRefresh: () => chatProvider.refreshConversations(context),
            color: primaryColorConsulor,
            child: Container(
              width: Get.width,
              height: Get.height,
              child: Column(
                children: [
                  Customtextfield(
                    required: false,
                    hint: "Search chat rooms".tr,
                    controller: _searchController,
                    borderColor: borderColor,
                    onChanged: (data) {
                      setState(() {
                        _searchQuery = data;
                      });
                    },
                    prefix: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: SvgPicture.asset(
                        AppIcons.searchsvg,
                        width: 25.0,
                        color: hintColor,
                      ),
                    ),
                  ),
                  UIHelper.verticalSpaceMd,
                  Expanded(child: _buildContent(chatProvider)),
                ],
              ),
            ).paddingAll(15.0),
          );
        },
      ),
    );
  }

  Widget _buildContent(ChatProvider chatProvider) {
    if (chatProvider.isLoading) {
      return _buildLoadingState();
    }

    if (chatProvider.error != null) {
      return _buildErrorState(chatProvider.error!);
    }

    final filteredConversations = _getFilteredConversations(
      chatProvider.conversations,
    );

    if (filteredConversations.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoResultsWidget();
    }

    if (chatProvider.conversations.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: filteredConversations.length,
      itemBuilder:
          (context, index) =>
              _buildConversationTile(filteredConversations[index]),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: primaryColorConsulor,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.w, color: Colors.red.shade300),
          SizedBox(height: 16.h),
          CustomText(
            text: 'Failed to load conversations'.tr,
            fontSize: FontConstants.font_16,
            weight: FontWeightConstants.medium,
            color: lightGREY,
          ),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: _loadConversations,
            child: CustomText(
              text: 'Tap to retry'.tr,
              fontSize: FontConstants.font_14,
              weight: FontWeightConstants.medium,
              color: primaryColorConsulor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64.w, color: lightGREY),
          SizedBox(height: 16.h),
          CustomText(
            text: 'No conversations yet'.tr,
            fontSize: FontConstants.font_16,
            weight: FontWeightConstants.medium,
            color: lightGREY,
          ),
          SizedBox(height: 8.h),
          CustomText(
            text: 'Your chat conversations will appear here'.tr,
            fontSize: FontConstants.font_14,
            weight: FontWeightConstants.regular,
            color: lightGREY,
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(ConversationData conversation) {
    // Generate avatar colors based on client name
    final colorIndex = conversation.clientName.hashCode % _avatarColors.length;
    final avatarColor = _avatarColors[colorIndex]['background']!;
    final initialColor = _avatarColors[colorIndex]['text']!;

    return GestureDetector(
      onTap: () => _navigateToChat(conversation),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
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
            // Avatar with online status
            Stack(
              children: [
                _buildAvatar(conversation, avatarColor, initialColor),
                // Online status indicator
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14.w,
                    height: 14.w,
                    decoration: BoxDecoration(
                      color:
                          conversation.appointment.user?.isOnline ?? false
                              ? greenColor
                              : greyColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 12.w),

            // Name and message details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          text: conversation.clientName,
                          fontSize: FontConstants.font_16,
                          weight: FontWeightConstants.semiBold,
                          color: Color(0xFF111726),
                        ),
                      ),
                      CustomText(
                        text: conversation.formattedTime,
                        fontSize: FontConstants.font_12,
                        weight: FontWeightConstants.regular,
                        color: lightGREY,
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.displayMessage,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight:
                                conversation.hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                            color:
                                conversation.hasUnread
                                    ? Color(0xFF111726)
                                    : lightGREY,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.hasUnread) ...[
                        SizedBox(width: 8.w),
                        Container(
                          width: 10.w,
                          height: 10.w,
                          decoration: BoxDecoration(
                            color: primaryColorConsulor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
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

  Widget _buildAvatar(
    ConversationData conversation,
    Color backgroundColor,
    Color textColor,
  ) {
    final hasImage =
        conversation.clientImage != null &&
        conversation.clientImage!.isNotEmpty;

    if (hasImage) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: conversation.clientImage!,
          width: 50.w,
          height: 50.w,
          fit: BoxFit.cover,
          placeholder:
              (context, url) => Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: backgroundColor,
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
                conversation.clientInitial,
                backgroundColor,
                textColor,
              ),
        ),
      );
    }

    return _buildInitialAvatar(
      conversation.clientInitial,
      backgroundColor,
      textColor,
    );
  }

  Widget _buildInitialAvatar(
    String initial,
    Color backgroundColor,
    Color textColor,
  ) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
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

  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64.w, color: lightGREY),
          SizedBox(height: 16.h),
          CustomText(
            text: 'No conversations found'.tr,
            fontSize: FontConstants.font_16,
            weight: FontWeightConstants.medium,
            color: lightGREY,
          ),
          SizedBox(height: 8.h),
          CustomText(
            text: 'Try searching with a different keyword'.tr,
            fontSize: FontConstants.font_14,
            weight: FontWeightConstants.regular,
            color: lightGREY,
          ),
        ],
      ),
    );
  }

  void _navigateToChat(ConversationData conversation) {
    final appointment = conversation.appointment;

    // Navigate to chat screen with appointment details
    print(appointment.isCompleted.toString());
    Get.to(
      () => ChatScreen(
        counselorName: conversation.clientName,
        channelName: appointment.chanelId,
        userId: appointment.user?.id ?? 0,
        counselorRate: appointment.methodCoins.toDouble(),
        appointmentId: appointment.id,
        counselorId: appointment.counselor?.id,
        isCounselor: true, // Counselor is viewing the chat
        isViewOnly: appointment.isCompleted, // View only if session completed
        isTroat: appointment.isTroat,
      ),
    );
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
