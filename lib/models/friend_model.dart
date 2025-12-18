class FriendModel {
  final String friendUid;
  final String displayName;
  final String? avatarUrl;
  final int createdAt;

  FriendModel({
    required this.friendUid,
    required this.displayName,
    this.avatarUrl,
    required this.createdAt,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      friendUid: json['friendUid'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: json['createdAt'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'friendUid': friendUid,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt,
    };
  }
}

