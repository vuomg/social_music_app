import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../repositories/post_repository.dart';
import '../../repositories/user_repository.dart';
import '../../models/user_model.dart';
import '../../models/music_model.dart';
import '../../widgets/music_picker_sheet.dart';
import '../../widgets/post_preview_card.dart';

class CreatePostScreen extends StatefulWidget {
  final VoidCallback? onPostSuccess;
  
  const CreatePostScreen({
    super.key,
    this.onPostSuccess,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  bool _isLoading = false;
  
  MusicModel? _selectedMusic;
  File? _postCoverFile; // Cover riêng cho post (optional)
  
  final PostRepository _postRepository = PostRepository();
  final UserRepository _userRepository = UserRepository();
  UserModel? _currentUserInfo;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      final userInfo = await _userRepository.getUser(user.uid);
      if (mounted) {
        setState(() {
          _currentUserInfo = userInfo;
        });
      }
    }
  }

  Future<void> _handlePickCover() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _postCoverFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handlePost() async {
    if (_selectedMusic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn nhạc từ thư viện')),
      );
      return;
    }

    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final uid = user.uid;
      final userInfo = await _userRepository.getUser(uid);
      String authorName = userInfo?.displayName ?? user.displayName ?? 'Unknown';
      final authorAvatarUrl = userInfo?.avatarUrl;
      
      if (authorName.length > 50) {
        authorName = authorName.substring(0, 50);
      }

      final caption = _captionController.text.trim().isEmpty
          ? null
          : _captionController.text.trim();

      // Tạo post từ music
      await _postRepository.createPostFromMusic(
        uid: uid,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        caption: caption,
        music: _selectedMusic!,
        postCoverFile: _postCoverFile,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Reset form
        _captionController.clear();
        setState(() {
          _selectedMusic = null;
          _postCoverFile = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng bài thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Chuyển sang tab Feed sau khi đăng thành công
        if (widget.onPostSuccess != null) {
          widget.onPostSuccess!();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng bài: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Load user info khi build (chỉ load 1 lần)
    if (_currentUserInfo == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadUserInfo();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo bài đăng'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton.icon(
              onPressed: _selectedMusic != null ? _handlePost : null,
              icon: const Icon(Icons.send),
              label: const Text('Đăng'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section 1: Chọn nhạc
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.library_music, 
                            color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'Chọn nhạc',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_selectedMusic != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Đã chọn',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  builder: (context) => MusicPickerSheet(
                                    onSelect: (music) {
                                      setState(() {
                                        _selectedMusic = music;
                                      });
                                    },
                                  ),
                                );
                              },
                        icon: const Icon(Icons.search),
                        label: Text(_selectedMusic != null
                            ? _selectedMusic!.title
                            : 'Tìm và chọn nhạc *'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      if (_selectedMusic != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _selectedMusic!.coverUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: _selectedMusic!.coverUrl!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[700],
                                          child: const Icon(Icons.music_note),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[700],
                                          child: const Icon(Icons.music_note),
                                        ),
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[700],
                                        child: const Icon(Icons.music_note),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedMusic!.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_selectedMusic!.ownerName} • ${_selectedMusic!.genre}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _selectedMusic = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Section 2: Caption
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.text_fields,
                            color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'Caption',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(Tùy chọn)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _captionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Viết gì đó về bài nhạc này...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Section 3: Cover riêng
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.image,
                            color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'Ảnh bìa riêng',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(Tùy chọn)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handlePickCover,
                        icon: Icon(_postCoverFile != null
                            ? Icons.check_circle
                            : Icons.add_photo_alternate),
                        label: Text(_postCoverFile != null
                            ? 'Đã chọn ảnh bìa'
                            : 'Chọn ảnh bìa riêng'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      if (_postCoverFile != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _postCoverFile!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _postCoverFile = null;
                            });
                          },
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Xóa ảnh bìa'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Preview Section
              if (_selectedMusic != null) ...[
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.preview,
                      color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Xem trước',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PostPreviewCard(
                  music: _selectedMusic!,
                  caption: _captionController.text.trim().isEmpty
                      ? null
                      : _captionController.text.trim(),
                  postCoverFile: _postCoverFile,
                  currentUser: _currentUserInfo,
                ),
                const SizedBox(height: 24),
              ],
              
              // Submit button
              if (_selectedMusic != null)
                ElevatedButton(
                  onPressed: _isLoading ? null : _handlePost,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Đăng bài',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
