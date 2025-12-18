class UserModel {
  final String uid;
  final String displayName;
  final String? avatarUrl;
  final String? birthday; // Format: YYYY-MM-DD
  final String? phone;
  final String? bio;
  final String? address;
  final int createdAt;
  final int updatedAt;

  UserModel({
    required this.uid,
    required this.displayName,
    this.avatarUrl,
    this.birthday,
    this.phone,
    this.bio,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      birthday: json['birthday'] as String?,
      phone: json['phone'] as String?,
      bio: json['bio'] as String?,
      address: json['address'] as String?,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'birthday': birthday,
      'phone': phone,
      'bio': bio,
      'address': address,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? avatarUrl,
    String? birthday,
    String? phone,
    String? bio,
    String? address,
    int? createdAt,
    int? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      birthday: birthday ?? this.birthday,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
