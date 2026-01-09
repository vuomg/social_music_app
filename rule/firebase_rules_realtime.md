{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null",

    "users": {
      "$uid": {
        ".read": "auth != null",
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
        "uid": { ".validate": "newData.isString() && newData.val() == auth.uid" },
        "caption": { ".validate": "newData.isString() || newData.val() == null" },
        "musicId": { ".validate": "newData.isString()" },
        "musicTitle": { ".validate": "newData.isString()" },
        "musicOwnerName": { ".validate": "newData.isString()" },
        "audioUrl": { ".validate": "newData.isString()" },
        "coverUrl": { ".validate": "newData.isString() || newData.val() == null" },
        "createdAt": { ".validate": "newData.isNumber()" },
        "commentCount": { ".validate": "newData.isNumber() && newData.val() >= 0" },
        "likesCount": { ".validate": "newData.isNumber() && newData.val() >= 0" }
      }
    },

    "postLikes": {
      "$postId": {
        "$uid": {
          ".read": "auth != null",
          ".write": "auth != null && auth.uid == $uid",
          ".validate": "newData.val() === true"
        }
      }
    },

    "comments": {
      "$postId": {
        "$commentId": {
          ".read": "auth != null",
          ".write": "auth != null && (!data.exists() || data.child('uid').val() == auth.uid)",
          "uid": { ".validate": "newData.isString() && newData.val() == auth.uid" },
          "content": { ".validate": "newData.isString() && newData.val().length > 0 && newData.val().length <= 500" },
          "createdAt": { ".validate": "newData.isNumber()" }
        }
      }
    },

    "musics": {
      "$musicId": {
        ".read": "auth != null",
        ".write": "auth != null && (!data.exists() || data.child('uid').val() == auth.uid)",
        "uid": { ".validate": "newData.isString() && newData.val() == auth.uid" },
        "title": { ".validate": "newData.isString() && newData.val().length > 0" },
        "genre": { ".validate": "newData.isString()" },
        "audioUrl": { ".validate": "newData.isString()" }
      }
    },

    "musicRooms": {
      "$roomId": {
        ".read": "auth != null",
        ".write": "auth != null && (!data.exists() || data.child('hostUid').val() == auth.uid || data.child('members').child(auth.uid).exists())",
        ".validate": "newData.child('roomId').isString() && newData.child('roomId').val().matches(/^[0-9]{4}$/)",
        
        "roomId": { ".validate": "newData.isString() && newData.val().matches(/^[0-9]{4}$/)" },
        "hostUid": { ".validate": "newData.isString()" },
        "hostName": { ".validate": "newData.isString()" },
        "musicId": { ".validate": "newData.isString() || newData.val() == null" },
        "musicTitle": { ".validate": "newData.isString() || newData.val() == null" },
        "audioUrl": { ".validate": "newData.isString() || newData.val() == null" },
        "isPlaying": { ".validate": "newData.isBoolean()" },
        "currentPositionMs": { ".validate": "newData.isNumber() && newData.val() >= 0" },
        "createdAt": { ".validate": "newData.isNumber()" },
        "updatedAt": { ".validate": "newData.isNumber()" },
        
        "members": {
          "$memberUid": {
            ".write": "auth != null && (auth.uid == $memberUid || root.child('musicRooms').child($roomId).child('hostUid').val() == auth.uid)",
            "displayName": { ".validate": "newData.isString()" },
            "avatarUrl": { ".validate": "newData.isString() || newData.val() == null" },
            "joinedAt": { ".validate": "newData.isNumber()" }
          }
        }
      }
    }
  }
}
