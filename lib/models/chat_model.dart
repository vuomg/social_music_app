class ChatModel {
  final String chatId;
  final Map<String, bool> members;
  final String? lastMessage;
  final int? lastMessageAt;

  ChatModel({
    required this.chatId,
    required this.members,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json, String chatId) {
    return ChatModel(
      chatId: chatId,
      members: (json['members'] as Map<dynamic, dynamic>?)
              ?.map((key, value) => MapEntry(key.toString(), value as bool)) ??
          {},
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: json['lastMessageAt'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'members': members,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt,
    };
  }
}

