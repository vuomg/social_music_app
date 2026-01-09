class MusicRoom {
  final String roomId;        // 4-digit code
  final String hostUid;
  final String hostName;
  final String? hostAvatarUrl;
  final String? musicId;
  final String? musicTitle;
  final String? audioUrl;
  final bool isPlaying;
  final int currentPositionMs;
  final int createdAt;
  final int updatedAt;
  final Map<String, MemberInfo> members;

  MusicRoom({
    required this.roomId,
    required this.hostUid,
    required this.hostName,
    this.hostAvatarUrl,
    this.musicId,
    this.musicTitle,
    this.audioUrl,
    required this.isPlaying,
    required this.currentPositionMs,
    required this.createdAt,
    required this.updatedAt,
    required this.members,
  });

  factory MusicRoom.fromJson(Map<String, dynamic> json) {
    final membersMap = <String, MemberInfo>{};
    if (json['members'] != null) {
      final membersData = Map<String, dynamic>.from(json['members'] as Map);
      membersData.forEach((key, value) {
        membersMap[key] = MemberInfo.fromJson(Map<String, dynamic>.from(value as Map));
      });
    }

    return MusicRoom(
      roomId: json['roomId'] as String,
      hostUid: json['hostUid'] as String,
      hostName: json['hostName'] as String,
      hostAvatarUrl: json['hostAvatarUrl'] as String?,
      musicId: json['musicId'] as String?,
      musicTitle: json['musicTitle'] as String?,
      audioUrl: json['audioUrl'] as String?,
      isPlaying: json['isPlaying'] as bool? ?? false,
      currentPositionMs: json['currentPositionMs'] as int? ?? 0,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
      members: membersMap,
    );
  }

  Map<String, dynamic> toJson() {
    final membersData = <String, dynamic>{};
    members.forEach((key, value) {
      membersData[key] = value.toJson();
    });

    return {
      'roomId': roomId,
      'hostUid': hostUid,
      'hostName': hostName,
      'hostAvatarUrl': hostAvatarUrl,
      'musicId': musicId,
      'musicTitle': musicTitle,
      'audioUrl': audioUrl,
      'isPlaying': isPlaying,
      'currentPositionMs': currentPositionMs,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'members': membersData,
    };
  }

  int get memberCount => members.length;
}

class MemberInfo {
  final String displayName;
  final String? avatarUrl;
  final int joinedAt;

  MemberInfo({
    required this.displayName,
    this.avatarUrl,
    required this.joinedAt,
  });

  factory MemberInfo.fromJson(Map<String, dynamic> json) {
    return MemberInfo(
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      joinedAt: json['joinedAt'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'joinedAt': joinedAt,
    };
  }
}
