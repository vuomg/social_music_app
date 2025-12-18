import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../repositories/music_repository.dart';
import '../../models/music_model.dart';
import '../../providers/auth_provider.dart' as app_auth;

class EditMusicScreen extends StatefulWidget {
  final MusicModel music;

  const EditMusicScreen({
    super.key,
    required this.music,
  });

  @override
  State<EditMusicScreen> createState() => _EditMusicScreenState();
}

class _EditMusicScreenState extends State<EditMusicScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String? _selectedGenre;
  bool _isLoading = false;
  File? _newCoverFile;

  final MusicRepository _musicRepository = MusicRepository();

  final List<String> _genres = [
    'Pop',
    'Rock',
    'Hip Hop',
    'Jazz',
    'Classical',
    'Electronic',
    'Country',
    'R&B',
  ];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.music.title;
    _selectedGenre = widget.music.genre;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handlePickCover() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _newCoverFile = File(pickedFile.path);
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGenre == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thể loại')),
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

    // Kiểm tra quyền
    if (widget.music.uid != user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có quyền sửa nhạc này')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final title = _titleController.text.trim();
      if (title.length > 120) {
        throw Exception('Tiêu đề không được quá 120 ký tự');
      }

      if (_selectedGenre!.length > 30) {
        throw Exception('Thể loại không được quá 30 ký tự');
      }

      await _musicRepository.updateMusic(
        musicId: widget.music.musicId,
        uid: user.uid,
        title: title,
        genre: _selectedGenre!,
        coverFile: _newCoverFile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật thông tin nhạc'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sửa thông tin nhạc'),
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
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _handleSave,
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
              // Cover preview
              Center(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _newCoverFile != null
                          ? Image.file(
                              _newCoverFile!,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            )
                          : widget.music.coverUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.music.coverUrl!,
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 200,
                                    height: 200,
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.music_note,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    width: 200,
                                    height: 200,
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.music_note,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 200,
                                  height: 200,
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.music_note,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: FloatingActionButton.small(
                        onPressed: _handlePickCover,
                        child: const Icon(Icons.edit),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tiêu đề';
                  }
                  if (value.length > 120) {
                    return 'Tiêu đề không được quá 120 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Genre
              DropdownButtonFormField<String>(
                value: _selectedGenre,
                decoration: const InputDecoration(
                  labelText: 'Genre',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.music_note),
                ),
                items: _genres.map((genre) {
                  return DropdownMenuItem<String>(
                    value: genre,
                    child: Text(genre),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _selectedGenre = value;
                  });
                },
                validator: (String? value) {
                  if (value == null) {
                    return 'Vui lòng chọn thể loại';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Không thể thay đổi file audio. Chỉ có thể sửa title, genre và cover.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[200],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

