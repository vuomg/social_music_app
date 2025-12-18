class MessageModel {
  final String messageId;
  final String senderUid;
  final String type; // "text" | "music"
  final String? text;
  final String? postId;
  final int createdAt;

  MessageModel({
    required this.messageId,
    required this.senderUid,
    required this.type,
    this.text,
    this.postId,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, String messageId) {
    return MessageModel(
      messageId: messageId,
      senderUid: json['senderUid'] as String,
      type: json['type'] as String,
      text: json['text'] as String?,
      postId: json['postId'] as String?,
      createdAt: json['createdAt'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderUid': senderUid,
      'type': type,
      'text': text,
      'postId': postId,
      'createdAt': createdAt,
    };
  }
}

