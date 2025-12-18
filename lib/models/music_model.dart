class MusicModel {
  final String musicId;
  final String uid; // owner
  final String ownerName;
  final String? ownerAvatarUrl;
  final String title;
  final String genre;
  final String audioUrl;
  final String audioPath;
  final String? coverUrl;
  final String? coverPath;
  final int createdAt;
  final int? updatedAt;

  MusicModel({
    required this.musicId,
    required this.uid,
    required this.ownerName,
    this.ownerAvatarUrl,
    required this.title,
    required this.genre,
    required this.audioUrl,
    required this.audioPath,
    this.coverUrl,
    this.coverPath,
    required this.createdAt,
    this.updatedAt,
  });

  factory MusicModel.fromJson(Map<String, dynamic> json, String musicId) {
    return MusicModel(
      musicId: musicId,
      uid: json['uid'] as String,
      ownerName: json['ownerName'] as String,
      ownerAvatarUrl: json['ownerAvatarUrl'] as String?,
      title: json['title'] as String,
      genre: json['genre'] as String,
      audioUrl: json['audioUrl'] as String,
      audioPath: json['audioPath'] as String,
      coverUrl: json['coverUrl'] as String?,
      coverPath: json['coverPath'] as String?,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'ownerName': ownerName,
      'ownerAvatarUrl': ownerAvatarUrl,
      'title': title,
      'genre': genre,
      'audioUrl': audioUrl,
      'audioPath': audioPath,
      'coverUrl': coverUrl,
      'coverPath': coverPath,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

