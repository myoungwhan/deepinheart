enum MessageType { text, image, file, video, audio }

class Message {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isFromUser;
  final String? avatarUrl;
  final String? senderName;
  final bool isRead;
  final MessageType messageType;
  final String? mediaUrl;
  final String? mediaPath;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;

  Message({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isFromUser,
    this.avatarUrl,
    this.senderName,
    this.isRead = false,
    this.messageType = MessageType.text,
    this.mediaUrl,
    this.mediaPath,
    this.fileName,
    this.fileSize,
    this.mimeType,
  });

  Message copyWith({
    String? id,
    String? text,
    DateTime? timestamp,
    bool? isFromUser,
    String? avatarUrl,
    String? senderName,
    bool? isRead,
    MessageType? messageType,
    String? mediaUrl,
    String? mediaPath,
    String? fileName,
    int? fileSize,
    String? mimeType,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isFromUser: isFromUser ?? this.isFromUser,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      senderName: senderName ?? this.senderName,
      isRead: isRead ?? this.isRead,
      messageType: messageType ?? this.messageType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaPath: mediaPath ?? this.mediaPath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isFromUser': isFromUser,
      'avatarUrl': avatarUrl,
      'senderName': senderName,
      'isRead': isRead,
      'messageType': messageType.name,
      'mediaUrl': mediaUrl,
      'mediaPath': mediaPath,
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      text: json['text'],
      timestamp: DateTime.parse(json['timestamp']),
      isFromUser: json['isFromUser'],
      avatarUrl: json['avatarUrl'],
      senderName: json['senderName'],
      isRead: json['isRead'] ?? false,
      messageType: MessageType.values.firstWhere(
        (e) => e.name == json['messageType'],
        orElse: () => MessageType.text,
      ),
      mediaUrl: json['mediaUrl'],
      mediaPath: json['mediaPath'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
    );
  }
}
