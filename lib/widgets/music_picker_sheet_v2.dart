import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/music_model.dart';
import '../repositories/music_repository.dart';
import '../providers/audio_player_provider.dart';
import 'package:provider/provider.dart';

class MusicPickerSheet extends StatefulWidget {
  final Function(MusicModel) onSelect;

  const MusicPickerSheet({
    super.key,
    required this.onSelect,
  });

  @override
  State<MusicPickerSheet> createState() => _MusicPickerSheetState();
}

class _MusicPickerSheetState extends State<MusicPickerSheet> with SingleTickerProviderStateMixin {
  final MusicRepository _musicRepository = MusicRepository();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _playingMusicId;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(
          child: Text('Vui lòng đăng nhập', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[900]!,
            Colors.black,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.library_music, color: Colors.purpleAccent, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Chọn nhạc',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bài nhạc...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.purpleAccent),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // Music list
          Expanded(
            child: StreamBuilder<List<MusicModel>>(
              stream: _musicRepository.streamAllMusics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
                  );
                }

                final musics = snapshot.data ?? [];
                final filteredMusics = musics.where((music) {
                  if (_searchQuery.isEmpty) return true;
                  return music.title.toLowerCase().contains(_searchQuery) ||
                      music.ownerName.toLowerCase().contains(_searchQuery) ||
                      music.genre.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredMusics.isEmpty) {
                  return const Center(
                    child: Text('Không tìm thấy bài nhạc', style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredMusics.length,
                  itemBuilder: (context, index) {
                    final music = filteredMusics[index];
                    final isPlaying = _playingMusicId == music.musicId;

                    return _buildMusicCard(music, isPlaying);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicCard(MusicModel music, bool isPlaying) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isPlaying
              ? [Colors.purple.withOpacity(0.4), Colors.deepPurple.withOpacity(0.3)]
              : [Colors.grey[900]!, Colors.grey[850]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.6),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => widget.onSelect(music),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _buildAlbumArt(music, isPlaying),
                const SizedBox(width: 16),
                Expanded(child: _buildMusicInfo(music, isPlaying)),
                _buildActionButtons(music, isPlaying),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt(MusicModel music, bool isPlaying) {
    return AnimatedScale(
      scale: isPlaying ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Stack(
        children: [
          // Glow
          if (isPlaying)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purpleAccent.withOpacity(0.5 + (_pulseController.value * 0.3)),
                        blurRadius: 20 + (_pulseController.value * 10),
                        spreadRadius: 3 + (_pulseController.value * 3),
                      ),
                    ],
                  ),
                );
              },
            ),
          // Cover
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: music.coverUrl != null
                ? CachedNetworkImage(
                    imageUrl: music.coverUrl!,
                    width: 75,
                    height: 75,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildPlaceholder(),
                    errorWidget: (context, url, error) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          // Playing indicator
          if (isPlaying)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withOpacity(0.4),
                      Colors.deepPurple.withOpacity(0.6),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 36),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 75,
      height: 75,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.music_note, color: Colors.grey, size: 36),
    );
  }

  Widget _buildMusicInfo(MusicModel music, bool isPlaying) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          music.title,
          style: TextStyle(
            color: isPlaying ? Colors.purpleAccent : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          '${music.ownerName} • ${music.genre}',
          style: TextStyle(
            color: isPlaying ? Colors.purpleAccent.withOpacity(0.8) : Colors.grey[400],
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (isPlaying) ...[
          const SizedBox(height: 10),
          _buildSoundWave(),
        ],
      ],
    );
  }

  Widget _buildSoundWave() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Row(
          children: List.generate(25, (i) {
            final height = 4.0 + (i % 4) * 3.0 + (_pulseController.value * 6);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                width: 2.5,
                height: height,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purpleAccent, Colors.purple],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildActionButtons(MusicModel music, bool isPlaying) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Preview button
        AnimatedScale(
          scale: isPlaying ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isPlaying
                  ? const LinearGradient(colors: [Colors.purple, Colors.deepPurple])
                  : null,
              color: isPlaying ? null : Colors.grey[800],
            ),
            child: IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isPlaying ? Colors.white : Colors.grey[400],
              ),
              onPressed: () => _togglePreview(music, isPlaying),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Select button
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
            onPressed: () {
              if (isPlaying) {
                Provider.of<AudioPlayerProvider>(context, listen: false).stop();
              }
              widget.onSelect(music);
            },
          ),
        ),
      ],
    );
  }

  void _togglePreview(MusicModel music, bool isPlaying) {
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    
    if (isPlaying) {
      audioProvider.stop();
      setState(() => _playingMusicId = null);
    } else {
      audioProvider.playUrl(music.audioUrl);
      setState(() => _playingMusicId = music.musicId);
    }
  }
}
