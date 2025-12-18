import 'package:flutter/material.dart';
import '../utils/time_format.dart';
import 'dart:async';

/// Widget SeekBar để hiển thị và điều khiển vị trí phát nhạc
class SeekBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final Function(Duration) onSeek;
  final bool compact; // Nếu true, hiển thị compact hơn cho mini player

  const SeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.compact = false,
  });

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double _sliderValue = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _updateSliderValue();
  }

  @override
  void didUpdateWidget(SeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Chỉ cập nhật slider nếu không đang kéo
    if (!_isDragging) {
      _updateSliderValue();
    }
  }

  void _updateSliderValue() {
    if (widget.duration.inMilliseconds > 0) {
      setState(() {
        _sliderValue = widget.position.inMilliseconds.clamp(
          0.0,
          widget.duration.inMilliseconds.toDouble(),
        ) / widget.duration.inMilliseconds;
      });
    } else {
      setState(() {
        _sliderValue = 0.0;
      });
    }
  }

  void _onChanged(double value) {
    setState(() {
      _sliderValue = value;
      _isDragging = true;
    });
  }

  void _onChangeEnd(double value) {
    setState(() {
      _isDragging = false;
    });
    
    // Tính toán Duration từ giá trị slider và clamp để không vượt quá duration
    final validDuration = widget.duration.inMilliseconds > 0
        ? widget.duration.inMilliseconds
        : 1;
    
    final newPositionMs = (value * validDuration).round().clamp(0, validDuration);
    final newPosition = Duration(milliseconds: newPositionMs);
    
    // Gọi callback để seek
    widget.onSeek(newPosition);
  }

  @override
  Widget build(BuildContext context) {
    // Đảm bảo duration hợp lệ và position không vượt quá duration
    final validDurationMs = widget.duration.inMilliseconds > 0
        ? widget.duration.inMilliseconds
        : 1;
    
    final clampedPositionMs = widget.position.inMilliseconds.clamp(0, validDurationMs);
    
    // Tính toán giá trị slider (0.0 đến 1.0)
    final currentSliderValue = _isDragging
        ? _sliderValue.clamp(0.0, 1.0)
        : (validDurationMs > 0 ? clampedPositionMs / validDurationMs : 0.0).clamp(0.0, 1.0);
    
    // Tính toán Duration để hiển thị
    final currentDuration = _isDragging
        ? Duration(milliseconds: (currentSliderValue * validDurationMs).round().clamp(0, validDurationMs))
        : Duration(milliseconds: clampedPositionMs);
    
    if (widget.compact) {
      // Compact version cho mini player
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: currentSliderValue,
            min: 0.0,
            max: 1.0,
            onChanged: validDurationMs > 0 ? _onChanged : null,
            onChangeEnd: validDurationMs > 0 ? _onChangeEnd : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TimeFormat.formatDuration(currentDuration),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
                ),
                Text(
                  TimeFormat.formatDuration(widget.duration),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Full version cho PostDetailScreen
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Slider(
          value: currentSliderValue,
          min: 0.0,
          max: 1.0,
          onChanged: validDurationMs > 0 ? _onChanged : null,
          onChangeEnd: validDurationMs > 0 ? _onChangeEnd : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                TimeFormat.formatDuration(currentDuration),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[300],
                ),
              ),
              Text(
                TimeFormat.formatDuration(widget.duration),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[300],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

