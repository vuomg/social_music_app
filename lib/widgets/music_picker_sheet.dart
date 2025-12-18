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

class _MusicPickerSheetState extends State<MusicPickerSheet> {
  final MusicRepository _musicRepository = MusicRepository();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _playingMusicId;

  @override
  void dispose() {
    _searchController.dispose();
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
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Chọn nhạc',
                  style: TextStyle(
                    fontSize: 20,
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bài nhạc...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          // Musics list
          Expanded(
            child: StreamBuilder<List<MusicModel>>(
              stream: _musicRepository.streamAllMusics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Lỗi: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
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
                    child: Text(
                      'Không tìm thấy bài nhạc',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredMusics.length,
                  itemBuilder: (context, index) {
                    final music = filteredMusics[index];
                    final isPlaying = _playingMusicId == music.musicId;

                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: music.coverUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: music.coverUrl!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                        title: Text(
                          music.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${music.ownerName} • ${music.genre}',
                          style: TextStyle(color: Colors.grey[400]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Preview play/pause button
                            IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: () {
                                final audioProvider =
                                    Provider.of<AudioPlayerProvider>(
                                  context,
                                  listen: false,
                                );
                                if (isPlaying && audioProvider.currentPost?.audioUrl == music.audioUrl) {
                                  // Đang phát music này, pause
                                  audioProvider.togglePlayPause();
                                  setState(() {
                                    _playingMusicId = null;
                                  });
                                } else {
                                  // Phát music mới
                                  audioProvider.playUrl(
                                    music.audioUrl,
                                    title: music.title,
                                    author: music.ownerName,
                                    coverUrl: music.coverUrl,
                                  );
                                  setState(() {
                                    _playingMusicId = music.musicId;
                                  });
                                }
                              },
                            ),
                            // Select button
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              onPressed: () {
                                widget.onSelect(music);
                                if (mounted) {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

