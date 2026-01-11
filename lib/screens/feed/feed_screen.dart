import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/post_model.dart';
import '../../repositories/post_repository.dart';
import '../../providers/audio_player_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/feed/feed_item.dart';
import '../post_detail/post_detail_screen.dart';

/// FEED SCREEN - TikTok Style
/// 
/// Hiển thị danh sách bài nhạc theo dạng FULL SCREEN, vuốt dọc để chuyển bài.
/// Tự động phát nhạc khi scroll đến bài mới.
/// 
/// Kỹ thuật sử dụng:
/// - PageView.builder: để hiển thị từng item full screen
/// - PageController: để quản lý trang hiện tại
/// - AudioPlayerProvider: để phát/dừng nhạc tự động
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  // Repository để lấy danh sách posts
  final _postRepository = PostRepository();

  // Controller quản lý PageView (để biết đang ở trang nào)
  final PageController _pageController = PageController();

  // Trang hiện tại (index của post đang hiển thị)
  int _currentPageIndex = 0;

  // Danh sách posts (lưu lại để không bị mất khi rebuild)
  List<PostModel>? _cachedPosts;

  // Flag để biết đã auto-play bài đầu tiên chưa
  bool _hasPlayedFirstPost = false;
  
  // Store provider reference for safe dispose
  AudioPlayerProvider? _audioProvider;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Store provider reference
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();

    // Use stored reference instead of Provider.of
    _audioProvider?.stop();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Stop audio khi app vào background
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive) {
      final audioProvider =
          Provider.of<AudioPlayerProvider>(context, listen: false);
      audioProvider.stop();
    }
  }

  /// HÀM XỬ LÝ KHI NGƯỜI DÙNG SCROLL SANG TRANG MỚI
  /// 
  /// Logic autoplay:
  /// 1. Dừng nhạc của bài cũ
  /// 2. Phát nhạc của bài mới
  /// 3. Cập nhật _currentPageIndex
  void _onPageChanged(int page, List<PostModel> posts) {
    // Nếu page không đổi thì không làm gì
    if (_currentPageIndex == page) return;

    print('📄 Scroll sang trang $page (bài: ${posts[page].musicTitle})');

    // Lấy AudioPlayerProvider (không listen để tránh rebuild)
    final audioProvider =
        Provider.of<AudioPlayerProvider>(context, listen: false);

    // BƯỚC 1: Dừng nhạc hiện tại
    audioProvider.stop();

    // BƯỚC 2: Chờ 300ms (để mượt hơn), rồi phát nhạc mới
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        // Kiểm tra mounted để tránh lỗi khi đã dispose
        final post = posts[page];
        audioProvider.playPost(post);
        print('▶️ Auto-play: ${post.musicTitle}');
      }
    });

    // BƯỚC 3: Cập nhật current page
    setState(() {
      _currentPageIndex = page;
    });
  }

  /// HÀM AUTO-PLAY BÀI ĐẦU TIÊN (khi vừa mở Feed)
  /// 
  /// Gọi sau khi StreamBuilder đã load xong danh sách posts
  void _autoPlayFirstPost(List<PostModel> posts) {
    // Chỉ play 1 lần duy nhất khi mới vào màn hình
    if (_hasPlayedFirstPost || posts.isEmpty) return;

    // Đánh dấu đã play rồi
    _hasPlayedFirstPost = true;

    print('🎵 Auto-play bài đầu tiên: ${posts[0].musicTitle}');

    // Chờ 500ms (để UI render xong), rồi phát nhạc
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final audioProvider =
            Provider.of<AudioPlayerProvider>(context, listen: false);
        audioProvider.playPost(posts[0]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // CRITICAL: Keep state alive between tab switches
    
    return Scaffold(
      // KHÔNG CÓ AppBar (để full screen như TikTok)
      // Nếu muốn có AppBar, bỏ comment dòng dưới:
      // appBar: AppBar(title: const Text('Feed')),

      body: StreamBuilder<List<PostModel>>(
        stream: _postRepository.streamPosts(),
        builder: (context, snapshot) {
          // ===== TRẠNG THÁI: ĐANG LOADING =====
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          // ===== TRẠNG THÁI: LỖI =====
          if (snapshot.hasError) {
            return ErrorStateWidget(
              message: 'Lỗi: ${snapshot.error}',
              onRetry: () {
                // Stream sẽ tự động reload
                setState(() {});
              },
            );
          }

          // ===== LẤY DANH SÁCH POSTS =====
          final posts = snapshot.data ?? [];

          // Cache lại để không mất khi rebuild
          if (posts.isNotEmpty) {
            _cachedPosts = posts;
          }

          // ===== TRẠNG THÁI: KHÔNG CÓ BÀI ĐĂNG =====
          if (posts.isEmpty) {
            return const EmptyStateWidget(
              message: 'Chưa có bài đăng',
              icon: Icons.music_note_outlined,
            );
          }

          // ===== AUTO-PLAY BÀI ĐẦU TIÊN =====
          // (Chỉ chạy 1 lần khi mới vào màn hình)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _autoPlayFirstPost(posts);
          });

          // ===== HIỂN thị PAGEVIEW (FULL SCREEN) =====
          // Tách ra widget riêng để tránh rebuild
          return _FeedPageView(
            posts: posts,
            initialPage: _currentPageIndex,
            onPageChanged: (page) => _onPageChanged(page, posts),
          );
        },
      ),
    );
  }
}

/// Widget riêng cho PageView để tránh rebuild từ parent
class _FeedPageView extends StatefulWidget {
  final List<PostModel> posts;
  final int initialPage;
  final Function(int) onPageChanged;

  const _FeedPageView({
    required this.posts,
    required this.initialPage,
    required this.onPageChanged,
  });

  @override
  State<_FeedPageView> createState() => _FeedPageViewState();
}

class _FeedPageViewState extends State<_FeedPageView> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      onPageChanged: (page) {
        setState(() => _currentPage = page);
        widget.onPageChanged(page);
      },
      itemCount: widget.posts.length,
      itemBuilder: (context, index) {
        final post = widget.posts[index];

        return Consumer<AudioPlayerProvider>(
          builder: (context, audioProvider, child) {
            final isCurrentPostPlaying = _currentPage == index &&
                audioProvider.currentPost?.postId == post.postId &&
                audioProvider.isPlaying;

            return FeedItem(
              post: post,
            );
          },
        );
      },
    );
  }
}
