class ReactionType {
  static const String like = 'like';
  static const String love = 'love';
  static const String haha = 'haha';
  static const String wow = 'wow';
  static const String sad = 'sad';
  static const String angry = 'angry';

  static const List<String> all = [like, love, haha, wow, sad, angry];

  static bool isValid(String type) {
    return all.contains(type);
  }
}
