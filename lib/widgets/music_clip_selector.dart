import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/music_model.dart';
import '../providers/audio_player_provider.dart';

/// Widget để chọn đoạn nhạc (clip) từ bài hát hoàn chỉnh
/// Similar to Facebook Music Note feature
class MusicClipSelector extends StatefulWidget {
  final MusicModel music;
  final Function(int startMs, int endMs) onClipSelected;
  final int defaultDurationSeconds; // Độ dài mặc định của clip (vd: 30s)

  const MusicClipSelector({
    super.key,
    required this.music,
    required this.onClipSelected,
    this.defaultDurationSeconds = 30,
  });

  @override
  State<MusicClipSelector> createState() => _MusicClipSelectorState();
}

class _MusicClipSelectorState extends State<MusicClipSelector> {
  double _startTime = 0; // Initialize with default
  double _endTime = 30;  // Initialize with default
  double _totalDuration = 180; // Default 3 minutes
  bool _isPlaying = false;
  bool _isInitializing = true; // Loading state

  @override
  void initState() {
    super.initState();
    _initializeClip();
  }

  Future<void> _initializeClip() async {
    setState(() => _isInitializing = true);
    
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    
    try {
      // Load audio để lấy duration
      await audioProvider.playUrl(widget.music.audioUrl);
      await Future.delayed(const Duration(milliseconds: 800));
      
      final duration = audioProvider.duration.inSeconds.toDouble();
      
      if (duration > 0 && mounted) {
        setState(() {
          _totalDuration = duration;
          _startTime = 0;
          _endTime = widget.defaultDurationSeconds.toDouble();
          
          // Nếu bài hát ngắn hơn 30s, lấy toàn bộ
          if (_totalDuration < widget.defaultDurationSeconds) {
            _endTime = _totalDuration;
          }
          
          _isInitializing = false;
        });
      } else {
        // Fallback if duration not available
        if (mounted) {
          setState(() {
            _totalDuration = 180;
            _startTime = 0;
            _endTime = 30;
            _isInitializing = false;
          });
        }
      }
      
      await audioProvider.stop();
    } catch (e) {
      debugPrint('❌ Lỗi load audio: $e');
      // Fallback: assume 3 minutes
      if (mounted) {
        setState(() {
          _totalDuration = 180;
          _startTime = 0;
          _endTime = 30;
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _previewClip() async {
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    
    try {
      setState(() => _isPlaying = true);
      
      await audioProvider.playUrl(widget.music.audioUrl);
      await audioProvider.seek(Duration(seconds: _startTime.toInt()));
      
      // Auto stop tại endTime
      Future.delayed(Duration(seconds: (_endTime - _startTime).toInt()), () {
        if (mounted && _isPlaying) {
          audioProvider.stop();
          setState(() => _isPlaying = false);
        }
      });
    } catch (e) {
      print('❌ Lỗi preview: $e');
      setState(() => _isPlaying = false);
    }
  }

  void _stopPreview() {
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    audioProvider.stop();
    setState(() => _isPlaying = false);
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds.remainder(60);
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while initializing
    if (_isInitializing) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Đang tải: ${widget.music.title}',
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    final clipDuration = _endTime - _startTime;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Chọn đoạn nhạc',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.music.title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          
          // Timeline visualization
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                // Selected range highlight
                Positioned(
                  left: (_startTime / _totalDuration) * MediaQuery.of(context).size.width * 0.8,
                  width: (clipDuration / _totalDuration) * MediaQuery.of(context).size.width * 0.8,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Start time slider
          Row(
            children: [
              const SizedBox(
                width: 80,
                child: Text('Bắt đầu:', style: TextStyle(fontSize: 14)),
              ),
              Expanded(
                child: Slider(
                  value: _startTime,
                  min: 0,
                  max: _totalDuration - 5, // At least 5s clip
                  divisions: (_totalDuration - 5).toInt(),
                  label: _formatDuration(_startTime),
                  onChanged: (value) {
                    setState(() {
                      _startTime = value;
                      // Ensure clip is at least 5s
                      if (_endTime - _startTime < 5) {
                        _endTime = _startTime + 5;
                      }
                      // Ensure clip is at most default duration
                      if (_endTime - _startTime > widget.defaultDurationSeconds) {
                        _endTime = _startTime + widget.defaultDurationSeconds;
                      }
                    });
                  },
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(_formatDuration(_startTime), style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          
          // End time slider
          Row(
            children: [
              const SizedBox(
                width: 80,
                child: Text('Kết thúc:', style: TextStyle(fontSize: 14)),
              ),
              Expanded(
                child: Slider(
                  value: _endTime,
                  min: _startTime + 5, // At least 5s clip
                  max: (_startTime + widget.defaultDurationSeconds) > _totalDuration 
                      ? _totalDuration 
                      : _startTime + widget.defaultDurationSeconds,
                  divisions: (((_startTime + widget.defaultDurationSeconds) > _totalDuration 
                      ? _totalDuration 
                      : _startTime + widget.defaultDurationSeconds) - (_startTime + 5)).toInt(),
                  label: _formatDuration(_endTime),
                  onChanged: (value) {
                    setState(() => _endTime = value);
                  },
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(_formatDuration(_endTime), style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Duration info
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Độ dài: ${clipDuration.toInt()}s',
                style: const TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isPlaying ? _stopPreview : _previewClip,
                  icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                  label: Text(_isPlaying ? 'Dừng' : 'Nghe thử'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final startMs = (_startTime * 1000).toInt();
                    final endMs = (_endTime * 1000).toInt();
                    widget.onClipSelected(startMs, endMs);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Xong'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_isPlaying) {
      _stopPreview();
    }
    super.dispose();
  }
}
