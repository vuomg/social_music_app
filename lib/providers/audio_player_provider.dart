import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/post_model.dart';

class AudioPlayerProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  PostModel? _currentPost;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Duration _bufferedPosition = Duration.zero;
  
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _bufferedPositionSubscription;

  PostModel? get currentPost => _currentPost;
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  Duration get bufferedPosition => _bufferedPosition;
  AudioPlayer get audioPlayer => _audioPlayer;

  AudioPlayerProvider() {
    _initAudioSession();
    _initListeners();
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      // Silent fail - audio session is optional
    }
  }

  void _initListeners() {
    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });

    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      _position = position;
      
      // Auto-loop clip nếu có endTime
      if (_currentPost?.endTimeMs != null && _isPlaying) {
        if (position.inMilliseconds >= _currentPost!.endTimeMs!) {
          // Loop back to start
          final startMs = _currentPost!.startTimeMs ?? 0;
          _audioPlayer.seek(Duration(milliseconds: startMs));
        }
      }
      
      notifyListeners();
    });

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    _bufferedPositionSubscription = _audioPlayer.bufferedPositionStream.listen((buffered) {
      _bufferedPosition = buffered;
      notifyListeners();
    });
  }

  Future<void> playPost(PostModel post) async {
    try {
      // Validate URL
      if (post.audioUrl.isEmpty) {
        debugPrint('❌ Audio URL is empty for post: ${post.postId}');
        return;
      }

      debugPrint('🎵 Attempting to play: ${post.musicTitle}');
      debugPrint('   URL: ${post.audioUrl}');
      if (post.startTimeMs != null && post.endTimeMs != null) {
        debugPrint('   Clip: ${post.startTimeMs}ms - ${post.endTimeMs}ms');
      }

      // Nếu đang phát post khác, dừng lại
      if (_currentPost?.postId != post.postId) {
        await _audioPlayer.stop();
        
        // Set URL với error handling
        try {
          await _audioPlayer.setUrl(post.audioUrl);
        } catch (e) {
          debugPrint('❌ Failed to set URL: $e');
          // Try alternative: setFilePath nếu là local file
          if (post.audioUrl.startsWith('file://')) {
            final path = post.audioUrl.replaceFirst('file://', '');
            await _audioPlayer.setFilePath(path);
          } else {
            rethrow;
          }
        }
        
        _currentPost = post;
      }
      
      // Seek to start time nếu có
      if (post.startTimeMs != null) {
        await _audioPlayer.seek(Duration(milliseconds: post.startTimeMs!));
      }
      
      await _audioPlayer.play();
      _isPlaying = true;
      notifyListeners();
      
      debugPrint('✅ Playing: ${post.musicTitle}');
    } catch (e, stackTrace) {
      debugPrint('❌ Lỗi phát nhạc: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Reset state
      _isPlaying = false;
      notifyListeners();
    }
  }

  /// Phát nhạc từ URL (generic method)
  Future<void> playUrl(
    String url, {
    String? title,
    String? author,
    String? coverUrl,
    String? postId,
  }) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(url);
      
      // Tạo PostModel tạm nếu cần (dùng cho preview music)
      if (postId != null) {
        _currentPost = PostModel(
          postId: postId,
          uid: '',
          authorName: author ?? 'Unknown',
          authorAvatarUrl: null,
          caption: null,
          musicId: postId, // Tạm dùng postId làm musicId
          musicTitle: title ?? 'Unknown',
          musicOwnerName: author ?? 'Unknown',
          audioUrl: url,
          coverUrl: coverUrl,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: null,
          commentCount: 0,
          likesCount: 0,
        );
      }
      
      await _audioPlayer.play();
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi phát nhạc từ URL: $e');
      rethrow;
    }
  }

  Future<void> togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Lỗi toggle play/pause: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      debugPrint('Lỗi seek: $e');
    }
  }

  /// Alias cho seek để tương thích với yêu cầu
  Future<void> seekTo(Duration position) async {
    await seek(position);
  }

  /// Tua đi 10 giây
  Future<void> seekForward() async {
    try {
      final newPositionMs = (_position.inMilliseconds + 10000).clamp(
        0,
        _duration.inMilliseconds,
      );
      final newPosition = Duration(milliseconds: newPositionMs);
      await _audioPlayer.seek(newPosition);
    } catch (e) {
      debugPrint('Lỗi seek forward: $e');
    }
  }

  /// Tua ngược 10 giây
  Future<void> seekBackward() async {
    try {
      final newPositionMs = (_position.inMilliseconds - 10000).clamp(
        0,
        _duration.inMilliseconds,
      );
      final newPosition = Duration(milliseconds: newPositionMs);
      await _audioPlayer.seek(newPosition);
    } catch (e) {
      debugPrint('Lỗi seek backward: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      _currentPost = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi stop: $e');
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _bufferedPositionSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
