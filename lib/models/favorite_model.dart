/// Model cho bài nhạc Đã Lưu - Lưu đầy đủ info để hiện thị nhanh
class FavoriteModel {
  final String musicId;
  final String userId;
  final String title;
  final String ownerName;
  final String? coverUrl;
  final int createdAt;

  FavoriteModel({
    required this.musicId,
    required this.userId,
    required this.title,
    required this.ownerName,
    this.coverUrl,
    required this.createdAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json, String id) {
    return FavoriteModel(
      musicId: id,
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? 'Không tên',
      ownerName: json['ownerName'] as String? ?? 'Ẩn danh',
      coverUrl: json['coverUrl'] as String?,
      createdAt: (json['createdAt'] is int) ? json['createdAt'] as int : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'ownerName': ownerName,
      'coverUrl': coverUrl,
      'createdAt': createdAt,
    };
  }
}
