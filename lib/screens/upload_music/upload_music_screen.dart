import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../repositories/music_repository.dart';
import '../../repositories/user_repository.dart';
import '../../models/user_model.dart';

class UploadMusicScreen extends StatefulWidget {
  const UploadMusicScreen({super.key});

  @override
  State<UploadMusicScreen> createState() => _UploadMusicScreenState();
}

class _UploadMusicScreenState extends State<UploadMusicScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String? _selectedGenre;
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  
  File? _audioFile;
  File? _coverFile;
  
  final MusicRepository _musicRepository = MusicRepository();
  final UserRepository _userRepository = UserRepository();
  
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
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handlePickAudio() async {
    try {
      FilePickerResult? result;
      
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac', 'wma', 'webm'],
          allowMultiple: false,
        );
      } catch (e) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
        );
      }

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = filePath.split('/').last.toLowerCase();
        final extension = fileName.contains('.') 
            ? fileName.split('.').last 
            : '';
        
        final allowedExts = ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac', 'wma', 'webm'];
        if (extension.isEmpty || !allowedExts.contains(extension)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vui lòng chọn file audio (mp3, wav, m4a, aac, ogg, flac, wma, webm)'),
              ),
            );
          }
          return;
        }

        setState(() {
          _audioFile = File(filePath);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn file audio: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handlePickCover() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _coverFile = File(pickedFile.path);
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

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGenre == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thể loại')),
      );
      return;
    }

    if (_audioFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn file nhạc')),
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
      _uploadProgress = 0.0;
    });

    try {
      final uid = user.uid;
      final userInfo = await _userRepository.getUser(uid);
      String ownerName = userInfo?.displayName ?? user.displayName ?? 'Unknown';
      final ownerAvatarUrl = userInfo?.avatarUrl;

      if (ownerName.length > 50) {
        ownerName = ownerName.substring(0, 50);
      }

      final title = _titleController.text.trim();
      if (title.length > 120) {
        throw Exception('Tiêu đề không được quá 120 ký tự');
      }

      if (_selectedGenre!.length > 30) {
        throw Exception('Thể loại không được quá 30 ký tự');
      }

      setState(() {
        _uploadProgress = 0.3;
      });

      // Upload music
      await _musicRepository.createMusic(
        uid: uid,
        ownerName: ownerName,
        ownerAvatarUrl: ownerAvatarUrl,
        title: title,
        genre: _selectedGenre!,
        audioFile: _audioFile!,
        coverFile: _coverFile,
      );

      setState(() {
        _uploadProgress = 1.0;
        _isLoading = false;
      });

      if (mounted) {
        // Reset form
        _titleController.clear();
        setState(() {
          _selectedGenre = null;
          _audioFile = null;
          _coverFile = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload nhạc thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadProgress = 0.0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi upload nhạc: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Nhạc'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handlePickAudio,
                icon: const Icon(Icons.audio_file),
                label: Text(_audioFile != null
                    ? 'Audio: ${_audioFile!.path.split('/').last}'
                    : 'Pick Audio *'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handlePickCover,
                icon: const Icon(Icons.image),
                label: Text(_coverFile != null
                    ? 'Cover: ${_coverFile!.path.split('/').last}'
                    : 'Pick Cover Image (Optional)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(value: _uploadProgress),
                const SizedBox(height: 8),
                Text(
                  'Đang upload... ${(_uploadProgress * 100).toInt()}%',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleUpload,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Upload Nhạc'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

