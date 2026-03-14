// import 'dart:io';
// import 'package:deepinheart/screens_consoler/chat/models/message.dart';
// import 'package:deepinheart/screens_consoler/chat/providers/chat_provider.dart';
// import 'package:deepinheart/screens_consoler/chat/widgets/attachment_modal.dart';
// import 'package:deepinheart/views/colors.dart';
// import 'package:deepinheart/views/custom_text.dart';
// import 'package:deepinheart/views/custom_textfiled.dart';
// import 'package:deepinheart/views/font_constants.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:provider/provider.dart';

// class ChatScreen extends StatefulWidget {
//   const ChatScreen({Key? key}) : super(key: key);

//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final ScrollController _scrollController = ScrollController();
//   final ImagePicker _imagePicker = ImagePicker();

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (context) => ChatProvider(),
//       child: Scaffold(
//         backgroundColor: whiteColor,
//         appBar: _buildAppBar(),
//         body: Consumer<ChatProvider>(
//           builder: (context, chatProvider, child) {
//             return Column(
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 Expanded(child: _buildMessageList(chatProvider)),
//                 _buildMessageInput(chatProvider),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       backgroundColor: Colors.white,
//       shadowColor: Colors.white,

//       elevation: 0,
//       leading: IconButton(
//         icon: Icon(Icons.arrow_back, color: Colors.black),
//         onPressed: () => Get.back(),
//       ),
//       centerTitle: true,
//       title: Consumer<ChatProvider>(
//         builder: (context, chatProvider, child) {
//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               CustomText(
//                 text: chatProvider.contactName,
//                 fontSize: FontConstants.font_18,
//                 weight: FontWeightConstants.semiBold,
//                 color: Colors.black,
//               ),
//               CustomText(
//                 text: chatProvider.isContactOnline ? 'Online' : 'Offline',
//                 fontSize: FontConstants.font_12,
//                 weight: FontWeightConstants.medium,
//                 color: chatProvider.isContactOnline ? greenColor : greyColor,
//               ),
//             ],
//           );
//         },
//       ),
//       actions: [
//         IconButton(
//           icon: Icon(Icons.person, color: Colors.black),
//           onPressed: () {
//             // Navigate to profile
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildMessageList(ChatProvider chatProvider) {
//     return ListView.builder(
//       controller: _scrollController,
//       padding: EdgeInsets.all(16.w),
//       itemCount: chatProvider.messages.length + (chatProvider.isTyping ? 1 : 0),
//       itemBuilder: (context, index) {
//         if (index == chatProvider.messages.length && chatProvider.isTyping) {
//           return _buildTypingIndicator();
//         }

//         final message = chatProvider.messages[index];
//         final isFirstMessageOfDay = _isFirstMessageOfDay(
//           index,
//           chatProvider.messages,
//         );
//         final showDateSeparator = isFirstMessageOfDay;

//         return Column(
//           children: [
//             if (showDateSeparator) _buildDateSeparator(message.timestamp),
//             _buildMessageBubble(message, chatProvider),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildDateSeparator(DateTime date) {
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final messageDate = DateTime(date.year, date.month, date.day);

//     String dateText;
//     if (messageDate == today) {
//       dateText = 'Today';
//     } else if (messageDate == today.subtract(Duration(days: 1))) {
//       dateText = 'Yesterday';
//     } else {
//       dateText = '${date.day}/${date.month}/${date.year}';
//     }

//     return Container(
//       margin: EdgeInsets.symmetric(vertical: 16.h),
//       child: Center(
//         child: Container(
//           padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
//           decoration: BoxDecoration(
//             color: greyColor.withOpacity(0.2),
//             borderRadius: BorderRadius.circular(12.r),
//           ),
//           child: CustomText(
//             text: dateText,
//             fontSize: FontConstants.font_12,
//             weight: FontWeightConstants.medium,
//             color: greyColor,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildMessageBubble(Message message, ChatProvider chatProvider) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 8.h),
//       child: Row(
//         mainAxisAlignment:
//             message.isFromUser
//                 ? MainAxisAlignment.end
//                 : MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           if (!message.isFromUser) ...[
//             _buildAvatar(message),
//             SizedBox(width: 8.w),
//           ],
//           Flexible(
//             child: Container(
//               constraints: BoxConstraints(maxWidth: Get.width * 0.7),
//               padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
//               decoration: BoxDecoration(
//                 color: message.isFromUser ? primaryColorConsulor : Colors.white,
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(message.isFromUser ? 25 : 0),
//                   topRight: Radius.circular(message.isFromUser ? 0 : 25),
//                   bottomLeft: Radius.circular(25),
//                   bottomRight: Radius.circular(25),
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 4,
//                     offset: Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Message content based on type
//                   _buildMessageContent(message),
//                   if (message.text.isNotEmpty) SizedBox(height: 4.h),
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       CustomText(
//                         text: _formatTime(message.timestamp),
//                         fontSize: FontConstants.font_10,
//                         weight: FontWeightConstants.regular,
//                         color:
//                             message.isFromUser
//                                 ? Colors.white.withOpacity(0.7)
//                                 : greyColor,
//                       ),
//                       if (message.isFromUser && message.isRead) ...[
//                         SizedBox(width: 4.w),
//                         CustomText(
//                           text: 'Read',
//                           fontSize: FontConstants.font_10,
//                           weight: FontWeightConstants.regular,
//                           color: Colors.white.withOpacity(0.7),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           if (message.isFromUser) SizedBox(width: 8.w),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessageContent(Message message) {
//     switch (message.messageType) {
//       case MessageType.text:
//         return CustomText(
//           text: message.text,
//           fontSize: FontConstants.font_14,
//           weight: FontWeightConstants.regular,
//           color: message.isFromUser ? Colors.white : Colors.black,
//         );

//       case MessageType.image:
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               width: 200.w,
//               height: 150.h,
//               decoration: BoxDecoration(
//                 color: Colors.grey[300],
//                 borderRadius: BorderRadius.circular(8.r),
//               ),
//               child: _buildImageContent(message),
//             ),
//             if (message.text.isNotEmpty) ...[
//               SizedBox(height: 8.h),
//               CustomText(
//                 text: message.text,
//                 fontSize: FontConstants.font_14,
//                 weight: FontWeightConstants.regular,
//                 color: message.isFromUser ? Colors.white : Colors.black,
//               ),
//             ],
//           ],
//         );

//       case MessageType.file:
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               padding: EdgeInsets.all(12.w),
//               decoration: BoxDecoration(
//                 color:
//                     message.isFromUser
//                         ? Colors.white.withOpacity(0.2)
//                         : Colors.grey[100],
//                 borderRadius: BorderRadius.circular(8.r),
//               ),
//               child: Row(
//                 children: [
//                   Icon(
//                     Icons.insert_drive_file,
//                     color: message.isFromUser ? Colors.white : Colors.grey[600],
//                     size: 24.w,
//                   ),
//                   SizedBox(width: 8.w),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         CustomText(
//                           text: message.fileName ?? 'Unknown file',
//                           fontSize: FontConstants.font_14,
//                           weight: FontWeightConstants.medium,
//                           color:
//                               message.isFromUser ? Colors.white : Colors.black,
//                         ),
//                         if (message.fileSize != null)
//                           CustomText(
//                             text: _formatFileSize(message.fileSize!),
//                             fontSize: FontConstants.font_12,
//                             weight: FontWeightConstants.regular,
//                             color:
//                                 message.isFromUser
//                                     ? Colors.white.withOpacity(0.7)
//                                     : Colors.grey[600],
//                           ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             if (message.text.isNotEmpty) ...[
//               SizedBox(height: 8.h),
//               CustomText(
//                 text: message.text,
//                 fontSize: FontConstants.font_14,
//                 weight: FontWeightConstants.regular,
//                 color: message.isFromUser ? Colors.white : Colors.black,
//               ),
//             ],
//           ],
//         );

//       default:
//         return CustomText(
//           text: message.text,
//           fontSize: FontConstants.font_14,
//           weight: FontWeightConstants.regular,
//           color: message.isFromUser ? Colors.white : Colors.black,
//         );
//     }
//   }

//   Widget _buildImageContent(Message message) {
//     if (message.mediaPath != null) {
//       // Local file path
//       return ClipRRect(
//         borderRadius: BorderRadius.circular(8.r),
//         child: Image.file(
//           File(message.mediaPath!),
//           fit: BoxFit.cover,
//           errorBuilder: (context, error, stackTrace) {
//             return Icon(Icons.image, size: 40.w, color: Colors.grey[600]);
//           },
//         ),
//       );
//     } else if (message.mediaUrl != null) {
//       // Network URL
//       return ClipRRect(
//         borderRadius: BorderRadius.circular(8.r),
//         child: Image.network(
//           message.mediaUrl!,
//           fit: BoxFit.cover,
//           errorBuilder: (context, error, stackTrace) {
//             return Icon(Icons.image, size: 40.w, color: Colors.grey[600]);
//           },
//         ),
//       );
//     } else {
//       // No image available
//       return Icon(Icons.image, size: 40.w, color: Colors.grey[600]);
//     }
//   }

//   String _formatFileSize(int bytes) {
//     if (bytes < 1024) return '$bytes B';
//     if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
//     if (bytes < 1024 * 1024 * 1024)
//       return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
//     return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
//   }

//   Widget _buildAvatar(Message message) {
//     return Container(
//       width: 32.w,
//       height: 32.w,
//       decoration: BoxDecoration(
//         color: Color(0xFFE8D5F2),
//         shape: BoxShape.circle,
//       ),
//       child: Center(
//         child: CustomText(
//           text: message.senderName?.substring(0, 1) ?? 'E',
//           fontSize: FontConstants.font_12,
//           weight: FontWeightConstants.bold,
//           color: Color(0xFF8B5CF6),
//         ),
//       ),
//     );
//   }

//   Widget _buildTypingIndicator() {
//     return Container(
//       margin: EdgeInsets.only(bottom: 8.h),
//       child: Row(
//         children: [
//           _buildAvatar(
//             Message(
//               id: 'typing',
//               text: '',
//               timestamp: DateTime.now(),
//               isFromUser: false,
//               senderName: 'Emily',
//             ),
//           ),
//           SizedBox(width: 8.w),
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(18.r),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 4,
//                   offset: Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 _buildTypingDot(0),
//                 SizedBox(width: 4.w),
//                 _buildTypingDot(1),
//                 SizedBox(width: 4.w),
//                 _buildTypingDot(2),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTypingDot(int index) {
//     return TweenAnimationBuilder<double>(
//       tween: Tween(begin: 0.0, end: 1.0),
//       duration: Duration(milliseconds: 600),
//       builder: (context, value, child) {
//         return Container(
//           width: 6.w,
//           height: 6.w,
//           decoration: BoxDecoration(
//             color: greyColor.withOpacity(0.3 + (0.7 * value)),
//             shape: BoxShape.circle,
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildMessageInput(ChatProvider chatProvider) {
//     return Container(
//       padding: EdgeInsets.all(16.w),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 4,
//             offset: Offset(0, -2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           IconButton(
//             icon: Icon(Icons.attach_file, color: Colors.black),
//             onPressed: () => _showAttachmentModal(context, chatProvider),
//           ),
//           Expanded(
//             child: Customtextfield(
//               required: false,
//               controller: chatProvider.messageController,
//               hint: 'Type a message...',
//               //  hintStyle: TextStyle(color: greyColor, fontSize: 14.sp),
//               border: 25.0,

//               maxLines: null,
//               onSubmitted: (_) => chatProvider.sendMessage(),
//             ),
//           ),
//           SizedBox(width: 8.w),
//           GestureDetector(
//             onTap: chatProvider.sendMessage,
//             child: Container(
//               width: 40.w,
//               height: 40.w,
//               decoration: BoxDecoration(
//                 color: primaryColorConsulor,
//                 borderRadius: BorderRadius.circular(20.r),
//               ),
//               child: Icon(Icons.send, color: Colors.white, size: 20.w),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   bool _isFirstMessageOfDay(int index, List<Message> messages) {
//     if (index == 0) return true;

//     final currentMessage = messages[index];
//     final previousMessage = messages[index - 1];

//     final currentDate = DateTime(
//       currentMessage.timestamp.year,
//       currentMessage.timestamp.month,
//       currentMessage.timestamp.day,
//     );

//     final previousDate = DateTime(
//       previousMessage.timestamp.year,
//       previousMessage.timestamp.month,
//       previousMessage.timestamp.day,
//     );

//     return currentDate != previousDate;
//   }

//   String _formatTime(DateTime dateTime) {
//     final hour = dateTime.hour;
//     final minute = dateTime.minute.toString().padLeft(2, '0');
//     final period = hour >= 12 ? 'PM' : 'AM';
//     final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

//     return '$displayHour:$minute $period';
//   }

//   void _showAttachmentModal(BuildContext context, ChatProvider chatProvider) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder:
//           (context) => AttachmentModal(
//             onAttachmentSelected: (attachmentType) {
//               _handleAttachmentSelection(attachmentType, chatProvider);
//             },
//           ),
//     );
//   }

//   void _handleAttachmentSelection(
//     AttachmentType attachmentType,
//     ChatProvider chatProvider,
//   ) {
//     switch (attachmentType) {
//       case AttachmentType.camera:
//         _handleCameraSelection(chatProvider);
//         break;
//       case AttachmentType.gallery:
//         _handleGallerySelection(chatProvider);
//         break;
//       case AttachmentType.file:
//         _handleFileSelection(chatProvider);
//         break;
//     }
//   }

//   void _handleCameraSelection(ChatProvider chatProvider) async {
//     try {
//       final XFile? image = await _imagePicker.pickImage(
//         source: ImageSource.camera,
//         imageQuality: 80,
//         maxWidth: 1920,
//         maxHeight: 1080,
//       );

//       if (image != null) {
//         final file = File(image.path);
//         final fileSize = await file.length();
//         final fileName = image.name;

//         chatProvider.sendMediaMessage(
//           messageType: MessageType.image,
//           mediaPath: image.path,
//           fileName: fileName,
//           fileSize: fileSize,
//           mimeType: 'image/jpeg',
//           caption: 'Photo from camera',
//         );
//       }
//     } catch (e) {
//       _showErrorSnackBar('Failed to capture image: $e');
//     }
//   }

//   void _handleGallerySelection(ChatProvider chatProvider) async {
//     try {
//       final XFile? image = await _imagePicker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 80,
//         maxWidth: 1920,
//         maxHeight: 1080,
//       );

//       if (image != null) {
//         final file = File(image.path);
//         final fileSize = await file.length();
//         final fileName = image.name;

//         chatProvider.sendMediaMessage(
//           messageType: MessageType.image,
//           mediaPath: image.path,
//           fileName: fileName,
//           fileSize: fileSize,
//           mimeType: 'image/jpeg',
//           caption: 'Photo from gallery',
//         );
//       }
//     } catch (e) {
//       _showErrorSnackBar('Failed to pick image: $e');
//     }
//   }

//   void _handleFileSelection(ChatProvider chatProvider) async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.any,
//         allowMultiple: false,
//       );

//       if (result != null && result.files.single.path != null) {
//         final fileSize = result.files.single.size;
//         final fileName = result.files.single.name;
//         final mimeType = result.files.single.extension;

//         chatProvider.sendMediaMessage(
//           messageType: MessageType.file,
//           mediaPath: result.files.single.path,
//           fileName: fileName,
//           fileSize: fileSize,
//           mimeType: mimeType,
//           caption: 'Document file',
//         );
//       }
//     } catch (e) {
//       _showErrorSnackBar('Failed to pick file: $e');
//     }
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: Duration(seconds: 3),
//       ),
//     );
//   }
// }
