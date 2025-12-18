{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null",

    "users": {
      "$uid": {
        ".read": "auth != null && auth.uid == $uid",
        ".write": "auth != null && auth.uid == $uid",
        "displayName": { ".validate": "newData.isString() && newData.val().length > 0 && newData.val().length <= 50" },
        "avatarUrl": { ".validate": "newData.isString() || newData.val() == null" },
        "createdAt": { ".validate": "newData.isNumber()" },
        "updatedAt": { ".validate": "newData.isNumber()" }
      }
    },

    "posts": {
      "$postId": {
        ".read": "auth != null",
        ".write": "auth != null && (!data.exists() || data.child('uid').val() == auth.uid)",

        ".validate": "newData.hasChildren(['uid','musicId','musicTitle','musicOwnerName','audioUrl','createdAt','reactionSummary','commentCount'])",

        "uid": { ".validate": "newData.isString() && newData.val() == auth.uid" },

        "authorName": { ".validate": "newData.isString() && newData.val().length > 0 && newData.val().length <= 50" },
        "authorAvatarUrl": { ".validate": "newData.isString() || newData.val() == null" },

        "caption": { ".validate": "newData.isString() || newData.val() == null" },

        "musicId": { ".validate": "newData.isString() && newData.val().length > 0" },
        "musicTitle": { ".validate": "newData.isString() && newData.val().length > 0 && newData.val().length <= 120" },
        "musicOwnerName": { ".validate": "newData.isString() && newData.val().length > 0 && newData.val().length <= 50" },

        "audioUrl": { ".validate": "newData.isString() && newData.val().length > 0" },
        "coverUrl": { ".validate": "newData.isString() || newData.val() == null" },

        "createdAt": { ".validate": "newData.isNumber()" },
        "updatedAt": { ".validate": "newData.isNumber() || newData.val() == null" },

        "commentCount": { ".validate": "newData.isNumber() && newData.val() >= 0" },

        "reactionSummary": {
          ".validate": "newData.hasChildren(['like','love','haha','wow','sad','angry'])",
          "like": { ".validate": "newData.isNumber() && newData.val() >= 0" },
          "love": { ".validate": "newData.isNumber() && newData.val() >= 0" },
          "haha": { ".validate": "newData.isNumber() && newData.val() >= 0" },
          "wow":  { ".validate": "newData.isNumber() && newData.val() >= 0" },
          "sad":  { ".validate": "newData.isNumber() && newData.val() >= 0" },
          "angry": { ".validate": "newData.isNumber() && newData.val() >= 0" }
        }
      }
    },

    "postReactions": {
      "$postId": {
        "$uid": {
          ".read": "auth != null",
          ".write": "auth != null && auth.uid == $uid",
          ".validate": "newData.hasChildren(['type','updatedAt'])",
          "type": {
            ".validate": "newData.isString() && (newData.val() == 'like' || newData.val() == 'love' || newData.val() == 'haha' || newData.val() == 'wow' || newData.val() == 'sad' || newData.val() == 'angry')"
          },
          "updatedAt": { ".validate": "newData.isNumber()" }
        }
      }
    },

    "comments": {
      "$postId": {
        "$commentId": {
          ".read": "auth != null",
          ".write": "auth != null && (!data.exists() || data.child('uid').val() == auth.uid)",

          ".validate": "newData.hasChildren(['uid','content','createdAt'])",
          "uid": { ".validate": "newData.isString() && newData.val() == auth.uid" },
          "authorName": { ".validate": "newData.isString() && newData.val().length > 0 && newData.val().length <= 50" },
          "authorAvatarUrl": { ".validate": "newData.isString() || newData.val() == null" },
          "content": { ".validate": "newData.isString() && newData.val().length > 0 && newData.val().length <= 500" },
          "createdAt": { ".validate": "newData.isNumber()" },
          "updatedAt": { ".validate": "newData.isNumber() || newData.val() == null" }
        }
      }
    },

    "musics": {
      "$musicId": {
        ".read": "auth != null",
        ".write": "auth != null && (!data.exists() || data.child('uid').val() == auth.uid)",

        ".validate": "newData.hasChildren(['uid','ownerName','title','genre','audioUrl','audioPath','createdAt'])",

        "uid": { ".validate": "newData.isString() && newData.val() == auth.uid" },
        "ownerName": { ".validate": "newData.isString() && newData.val().length > 0 && newData.val().length <= 50" },
        "ownerAvatarUrl": { ".validate": "newData.isString() || newData.val() == null" },

        "title": { ".validate": "newData.isString() && newData.val().length > 0 && newData.val().length <= 120" },
        "genre": { ".validate": "newData.isString() && newData.val().length > 0 && newData.val().length <= 30" },

        "audioUrl": { ".validate": "newData.isString() && newData.val().length > 0" },
        "audioPath": { ".validate": "newData.isString() && newData.val().length > 0" },
        "coverUrl": { ".validate": "newData.isString() || newData.val() == null" },
        "coverPath": { ".validate": "newData.isString() || newData.val() == null" },

        "createdAt": { ".validate": "newData.isNumber()" },
        "updatedAt": { ".validate": "newData.isNumber() || newData.val() == null" }
      }
    }
  }
}
