class CommentModel {
  final String commentId;
  final String uid;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final int createdAt;
  final int? updatedAt;

  CommentModel({
    required this.commentId,
    required this.uid,
    required this.authorName,
    this.authorAvatarUrl,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json, String commentId) {
    return CommentModel(
      commentId: commentId,
      uid: json['uid'] as String,
      authorName: json['authorName'] as String,
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      content: json['content'] as String,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
