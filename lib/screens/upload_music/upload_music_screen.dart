import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  bool _isUploading = false;
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

    setState(() {
      _isUploading = true;
    });


    try {
      final user = Provider.of<app_auth.AuthProvider>(context, listen: false).user; // Using app_auth.AuthProvider
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Check Firebase Auth current user
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('Firebase Authentication required. Please logout and login again.');
      }

      // 1. Upload audio to storage
      final audioFileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.${_audioFile!.path.split('.').last}';
      final audioStorageRef = FirebaseStorage.instance.ref().child('music/$audioFileName');
      
      await audioStorageRef.putFile(_audioFile!);
      final audioUrl = await audioStorageRef.getDownloadURL();

      // 2. Upload cover if selected
      String? coverUrl;
      String? coverPath;
      if (_coverFile != null) {
        final coverFileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.${_coverFile!.path.split('.').last}';
        final coverStorageRef = FirebaseStorage.instance.ref().child('covers/$coverFileName');
        await coverStorageRef.putFile(_coverFile!);
        coverUrl = await coverStorageRef.getDownloadURL();
        coverPath = 'covers/$coverFileName';
      }

      // 3. Save music to database (NOT creating a post)
      final musicData = {
        'uid': user.uid,
        'ownerName': user.displayName ?? 'Unknown',
        'ownerAvatarUrl': user.photoURL,
        'title': _titleController.text.trim(),
        'genre': _selectedGenre,
        'audioUrl': audioUrl,
        'audioPath': 'music/$audioFileName',
        'coverUrl': coverUrl,
        'coverPath': coverPath,
        'createdAt': ServerValue.timestamp,
      };

      // Save to musics collection
      await FirebaseDatabase.instance.ref('musics').push().set(musicData);

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
            content: Text('Tải nhạc lên thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Navigator.pop(context); // Removed as per original behavior, just resets form
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
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
                onPressed: _isUploading ? null : _handlePickAudio,
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
                onPressed: _isUploading ? null : _handlePickCover,
                icon: const Icon(Icons.image),
                label: Text(_coverFile != null
                    ? 'Cover: ${_coverFile!.path.split('/').last}'
                    : 'Pick Cover Image (Optional)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (_isUploading) ...[ 
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  'Đang upload...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isUploading ? null : _handleUpload,
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
