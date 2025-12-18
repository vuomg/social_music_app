class FriendRequestModel {
  final String fromUid;
  final String fromName;
  final String? fromAvatarUrl;
  final int createdAt;

  FriendRequestModel({
    required this.fromUid,
    required this.fromName,
    this.fromAvatarUrl,
    required this.createdAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      fromUid: json['fromUid'] as String,
      fromName: json['fromName'] as String,
      fromAvatarUrl: json['fromAvatarUrl'] as String?,
      createdAt: json['createdAt'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromUid': fromUid,
      'fromName': fromName,
      'fromAvatarUrl': fromAvatarUrl,
      'createdAt': createdAt,
    };
  }
}

