import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../repositories/favorite_repository.dart';

/// Widget nút Lưu - Truyền Post để lưu đầy đủ thông tin
class FavoriteButton extends StatefulWidget {
  final PostModel post;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const FavoriteButton({
    super.key,
    required this.post,
    this.size = 24,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  final FavoriteRepository _repo = FavoriteRepository();
  bool _isSaved = false;

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _checkSaved();
  }

  @override
  void didUpdateWidget(FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.musicId != widget.post.musicId) {
      _checkSaved();
    }
  }

  Future<void> _checkSaved() async {
    if (_userId.isEmpty) return;
    
    try {
      final result = await _repo.isFavorite(_userId, widget.post.musicId);
      if (mounted) {
        setState(() => _isSaved = result);
      }
    } catch (e) {
      debugPrint('Lỗi check saved: $e');
    }
  }

  Future<void> _toggleSave() async {
    if (_userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập')),
      );
      return;
    }

    // Optimistic update
    final previousState = _isSaved;
    setState(() => _isSaved = !_isSaved);

    try {
      if (!_isSaved) {
        // Nếu vừa chuyển từ True sang False => Xóa
        await _repo.removeFavorite(_userId, widget.post.musicId);
      } else {
        // Nếu vừa chuyển từ False sang True => Lưu
        await _repo.saveFromPost(_userId, widget.post);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isSaved ? 'Đã lưu vào danh sách 🔖' : 'Đã bỏ lưu bài hát'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Rollback
      debugPrint('Lỗi toggle save: $e');
      if (mounted) {
        setState(() => _isSaved = previousState);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể thực hiện, vui lòng thử lại')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isSaved ? Icons.bookmark : Icons.bookmark_border,
        color: _isSaved ? widget.activeColor : widget.inactiveColor,
        size: widget.size,
      ),
      onPressed: _toggleSave,
    );
  }
}
