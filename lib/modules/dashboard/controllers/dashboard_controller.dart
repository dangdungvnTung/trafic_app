import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:traffic_app/widgets/custom_alert.dart';

import '../../../data/models/traffic_post_model.dart';
import '../../../data/repositories/follow_repository.dart';
import '../../../data/repositories/traffic_post_repository.dart';
import '../../../services/storage_service.dart';
import '../widgets/report_bottom_sheet.dart';

class DashboardController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final TrafficPostRepository _postRepository = TrafficPostRepository();
  final FollowRepository _followRepository = FollowRepository();
  final StorageService _storageService = Get.find<StorageService>();

  /// ID của user hiện tại (dùng để ẩn nút follow trên bài viết của chính mình)
  int? get currentUserId => _storageService.getUserId();

  final refreshController = RefreshController(initialRefresh: false);
  final ScrollController scrollController = ScrollController();

  // State management
  final posts = <TrafficPostModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final errorMessage = ''.obs;

  // Animation: id của bài viết mới nhất vừa được prepend
  final newPostId = RxnString();

  // Pagination
  int currentPage = 0;
  final int pageSize = 10;
  String currentLocation = '';

  void scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    searchController.dispose();
    refreshController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    _initializeLocation();
  }

  /// Khởi tạo location từ storage và load posts
  void _initializeLocation() async {
    // Lấy province từ user profile hoặc default
    final prefs = _storageService;
    currentLocation = prefs.getString('userProvince') ?? 'Hà Nội';

    // Load posts lần đầu
    await loadPosts(refresh: true);
  }

  /// Load danh sách bài viết
  /// [refresh]: true nếu muốn load lại từ đầu (pull to refresh)
  Future<void> loadPosts({bool refresh = false}) async {
    if (refresh) {
      currentPage = 0;
      hasMore.value = true;
      errorMessage.value = '';
    }

    if (!hasMore.value) return;

    // Set loading state
    if (refresh) {
      isLoading.value = true;
      posts.clear();
    } else {
      isLoadingMore.value = true;
    }

    try {
      final newPosts = await _postRepository.getPosts(
        location: currentLocation,
        page: currentPage,
        size: pageSize,
      );

      if (newPosts.isEmpty) {
        hasMore.value = false;
        if (refresh) {
          refreshController.refreshCompleted();
        } else {
          refreshController.loadNoData();
        }
      } else {
        if (refresh) {
          posts.value = newPosts;
          refreshController.refreshCompleted();
        } else {
          posts.addAll(newPosts);
          refreshController.loadComplete();
        }
        currentPage++;
      }

      errorMessage.value = '';
    } catch (e) {
      errorMessage.value = e.toString();
      if (refresh) {
        refreshController.refreshFailed();
        CustomAlert.showError(e.toString());
      } else {
        refreshController.loadFailed();
      }
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Load more khi scroll đến cuối danh sách
  Future<void> loadMore() async {
    if (!isLoadingMore.value && hasMore.value) {
      await loadPosts(refresh: false);
    } else if (!hasMore.value) {
      refreshController.loadNoData();
    }
  }

  /// Refresh toàn bộ danh sách
  @override
  Future<void> refresh() async {
    refreshController.resetNoData();
    await loadPosts(refresh: true);
  }

  /// Thay đổi location và load lại posts
  void changeLocation(String location) {
    if (location != currentLocation) {
      currentLocation = location;
      // Save to storage
      _storageService.setString('userProvince', location);
      loadPosts(refresh: true);
    }
  }

  /// Thêm bài viết mới lên đầu danh sách (không rebuild toàn trang)
  void prependPost(TrafficPostModel post) {
    newPostId.value = post.id;
    posts.insert(0, post);
  }

  /// Xóa newPostId sau khi animation kết thúc
  void clearNewPostId() {
    newPostId.value = null;
  }

  /// Toggle like/unlike post với Optimistic Update
  /// - Cập nhật UI ngay lập tức (không chờ API)
  /// - Gọi API ở nền
  /// - Nếu API lỗi: rollback lại trạng thái cũ
  Future<void> toggleLike(TrafficPostModel post) async {
    final index = posts.indexWhere((p) => p.id == post.id);
    if (index == -1 || post.id == null) return;

    final currentIsLiked = post.isLiked ?? false;
    final currentLikes = post.likes ?? 0;

    // Optimistic update: cập nhật UI ngay
    posts[index] = post.copyWith(
      isLiked: !currentIsLiked,
      likes: currentIsLiked ? currentLikes - 1 : currentLikes + 1,
    );

    try {
      await _postRepository.likePost(post.id!);
    } catch (_) {
      // Rollback nếu API thất bại
      if (index < posts.length) {
        posts[index] = post.copyWith(
          isLiked: currentIsLiked,
          likes: currentLikes,
        );
      }
    }
  }

  /// Toggle follow/unfollow user với Optimistic Update
  Future<void> toggleFollow(TrafficPostModel post) async {
    final index = posts.indexWhere((p) => p.id == post.id);
    if (index == -1 || post.userId == null) return;

    final userId = int.tryParse(post.userId!);
    if (userId == null) return;

    final currentFollow = post.userFollow ?? false;

    // Optimistic update: cập nhật UI ngay
    posts[index] = post.copyWith(userFollow: !currentFollow);

    try {
      await _followRepository.followUser(userId);
    } catch (_) {
      // Rollback nếu API thất bại
      if (index < posts.length) {
        posts[index] = post.copyWith(userFollow: currentFollow);
      }
    }
  }

  /// Report post
  void reportPost(TrafficPostModel post) {
    if (post.id == null) return;

    Get.bottomSheet(
      ReportBottomSheet(
        onReport: (reason) async {
          try {
            await _postRepository.reportPost(postId: post.id!, reason: reason);

            Get.back();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              CustomAlert.showSuccess('dashboard_report_success'.tr);
            });
          } catch (e) {
            Get.back();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              CustomAlert.showError(e.toString());
            });
          }
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
