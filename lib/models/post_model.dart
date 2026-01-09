class PostModel {
  final String postId;
  final String uid;
  final String authorName;
  final String? authorAvatarUrl;
  final String? caption;
  final String musicId; // Tham chiếu đến musics/{musicId}
  final String musicTitle; // Snapshot từ music
  final String musicOwnerName; // Snapshot từ music
  final String audioUrl; // Snapshot từ music (để play nhanh)
  final String? coverUrl; // Snapshot từ music hoặc cover riêng của post
  final int createdAt;
  final int? updatedAt;
  final int commentCount;
  final int likesCount;
  
  // Music clip selection (like Facebook Music Note)
  final int? startTimeMs; // Start position in milliseconds
  final int? endTimeMs;   // End position in milliseconds

  PostModel({
    required this.postId,
    required this.uid,
    required this.authorName,
    this.authorAvatarUrl,
    this.caption,
    required this.musicId,
    required this.musicTitle,
    required this.musicOwnerName,
    required this.audioUrl,
    this.coverUrl,
    required this.createdAt,
    this.updatedAt,
    required this.commentCount,
    required this.likesCount,
    this.startTimeMs,
    this.endTimeMs,
  });

  factory PostModel.fromJson(Map<String, dynamic> json, String postId) {
    return PostModel(
      postId: postId,
      uid: json['uid'] as String,
      authorName: json['authorName'] as String? ?? 'Unknown',
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      caption: json['caption'] as String?,
      musicId: json['musicId'] as String,
      musicTitle: json['musicTitle'] as String,
      musicOwnerName: json['musicOwnerName'] as String,
      audioUrl: json['audioUrl'] as String,
      coverUrl: json['coverUrl'] as String?,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
      commentCount: json['commentCount'] as int? ?? 0,
      likesCount: json['likesCount'] as int? ?? 0,
      startTimeMs: json['startTimeMs'] as int?,
      endTimeMs: json['endTimeMs'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'caption': caption,
      'musicId': musicId,
      'musicTitle': musicTitle,
      'musicOwnerName': musicOwnerName,
      'audioUrl': audioUrl,
      'coverUrl': coverUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'commentCount': commentCount,
      'likesCount': likesCount,
      'startTimeMs': startTimeMs,
      'endTimeMs': endTimeMs,
    };
  }
  
  // Helper getters
  int get commentsCount => commentCount;
  int get savesCount => 0;
  String get musicArtist => musicOwnerName;
}
