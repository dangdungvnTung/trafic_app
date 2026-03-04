import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:traffic_app/widgets/custom_alert.dart';

import '../../../data/models/traffic_post_model.dart';
import '../../../data/repositories/follow_repository.dart';
import '../../../data/repositories/traffic_post_repository.dart';
import '../../../services/storage_service.dart';
import '../widgets/post_bottom_sheet.dart';

/// Hashtags được đánh dấu trên bản đồ – đồng bộ với CameraController
const List<String> kMapHashtags = [
  'ketxe',
  'giaothong',
  'tainan',
  'ngaplutnuoc',
  'suachua',
];

class MapController extends GetxController {
  late GoogleMapController mapController;
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController searchController = TextEditingController();
  final Dio _dio = Dio();
  final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  final _postRepository = TrafficPostRepository();
  final _followRepository = FollowRepository();
  final _storageService = Get.find<StorageService>();

  int? get currentUserId => _storageService.getUserId();

  // Tagged posts (có hashtag khớp kMapHashtags)
  final taggedPosts = <TrafficPostModel>[].obs;

  final LatLng _center = const LatLng(
    21.028511,
    105.804817,
  ); // Hanoi coordinates
  LatLng get center => _center;

  // Observables for Map State
  var currentMapType = MapType.normal.obs;
  var isTrafficEnabled = false.obs;
  var markers = <Marker>{}.obs;
  var polylines = <Polyline>{}.obs;
  var isLoading = false.obs;
  var placeSuggestions = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadTaggedPosts();
    _addDummyPolyline();
    _checkLocationPermission();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void onMapCreated(GoogleMapController controller) {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
    }
    mapController = controller;
  }

  Future<void> fetchSuggestions(String input) async {
    if (input.isEmpty) {
      placeSuggestions.clear();
      return;
    }

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': input,
          'key': _apiKey,
          'components': 'country:vn', // Limit to Vietnam
        },
      );
      if (response.statusCode == 200) {
        final predictions = response.data['predictions'] as List;
        placeSuggestions.value = predictions.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
    }
  }

  Future<void> selectSuggestion(Map<String, dynamic> suggestion) async {
    searchController.text = suggestion['description'];
    placeSuggestions.clear();
    await searchLocation(suggestion['description']);
  }

  Future<void> searchLocation(String query) async {
    if (query.isEmpty) return;

    try {
      isLoading.value = true;
      List<Location> locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        Location location = locations.first;
        LatLng target = LatLng(location.latitude, location.longitude);

        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: target, zoom: 16.0),
          ),
        );

        markers.add(
          Marker(
            markerId: const MarkerId('search_result'),
            position: target,
            infoWindow: InfoWindow(title: query),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet,
            ),
          ),
        );
      } else {
        CustomAlert.showWarning('map_location_not_found'.tr);
      }
    } catch (e) {
      CustomAlert.showError('${'map_cannot_search'.tr}: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void toggleMapType() {
    final types = [
      MapType.normal,
      MapType.satellite,
      MapType.terrain,
      MapType.hybrid,
    ];
    final currentIndex = types.indexOf(currentMapType.value);
    currentMapType.value = types[(currentIndex + 1) % types.length];
  }

  void toggleTraffic() {
    isTrafficEnabled.value = !isTrafficEnabled.value;
  }

  Future<void> _checkLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.location.request();
    }
  }

  Future<void> goToMyLocation() async {
    try {
      isLoading.value = true;
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        CustomAlert.showError('map_location_service_disabled'.tr);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          CustomAlert.showError('map_location_permission_denied'.tr);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        CustomAlert.showError('map_location_permission_denied_forever'.tr);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15.0,
          ),
        ),
      );
    } catch (e) {
      CustomAlert.showError('${'cannot_get_location'.tr}: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load tất cả bài viết, lọc theo hashtag, tạo marker
  Future<void> loadTaggedPosts() async {
    try {
      final posts = await _postRepository.getPosts(
        location: '',
        page: 0,
        size: 50,
      );

      // Lọc bài có hashtag nằm trong kMapHashtags và có tọa độ hợp lệ
      final filtered = posts.where((p) {
        if (p.location == null) return false;
        final tags = p.hashtags?.map((t) => t.toLowerCase()).toList() ?? [];
        return tags.any((t) => kMapHashtags.contains(t));
      }).toList();

      taggedPosts.value = filtered;
      _buildPostMarkers();
    } catch (e) {
      debugPrint('MapController loadTaggedPosts error: $e');
    }
  }

  void _buildPostMarkers() {
    // Xóa marker bài viết cũ, giữ search_result nếu có
    markers.removeWhere((m) => m.markerId.value.startsWith('post_'));

    for (final post in taggedPosts) {
      final loc = post.location;
      if (loc == null) continue;

      // Màu marker theo hashtag đầu tiên khớp
      final matchingTags = (post.hashtags ?? [])
          .map((t) => t.toLowerCase())
          .where((t) => kMapHashtags.contains(t))
          .toList();
      final firstTag = matchingTags.isNotEmpty ? matchingTags.first : '';
      final displayTag = firstTag.isNotEmpty
          ? '#$firstTag'
          : ((post.hashtags?.isNotEmpty ?? false) ? post.hashtags!.first : '');

      markers.add(
        Marker(
          markerId: MarkerId('post_${post.id}'),
          position: LatLng(loc.lat, loc.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(_hueForTag(firstTag)),
          infoWindow: InfoWindow(
            title: displayTag,
            snippet: post.userName ?? '',
          ),
          onTap: () => _showPostBottomSheet(post),
        ),
      );
    }
  }

  double _hueForTag(String tag) {
    switch (tag) {
      case 'ketxe':
        return BitmapDescriptor.hueRed;
      case 'tainan':
        return BitmapDescriptor.hueOrange;
      case 'ngaplutnuoc':
        return BitmapDescriptor.hueCyan;
      case 'suachua':
        return BitmapDescriptor.hueYellow;
      case 'giaothong':
      default:
        return BitmapDescriptor.hueViolet;
    }
  }

  void _showPostBottomSheet(TrafficPostModel initialPost) {
    PostBottomSheet.show(
      post: initialPost,
      currentUserId: currentUserId,
      onLike: _toggleLike,
      onFollow: _toggleFollow,
      onReport: _reportPost,
    );
  }

  Future<void> _toggleLike(Rx<TrafficPostModel> postRx) async {
    final p = postRx.value;
    if (p.id == null) return;
    final wasLiked = p.isLiked ?? false;
    final prevLikes = p.likes ?? 0;
    postRx.value = p.copyWith(
      isLiked: !wasLiked,
      likes: wasLiked ? prevLikes - 1 : prevLikes + 1,
    );
    _syncToTaggedPosts(postRx.value);
    try {
      await _postRepository.likePost(p.id!);
    } catch (_) {
      postRx.value = p.copyWith(isLiked: wasLiked, likes: prevLikes);
      _syncToTaggedPosts(postRx.value);
    }
  }

  Future<void> _toggleFollow(Rx<TrafficPostModel> postRx) async {
    final p = postRx.value;
    final userId = int.tryParse(p.userId ?? '');
    if (userId == null) return;
    final wasFollowing = p.userFollow ?? false;
    postRx.value = p.copyWith(userFollow: !wasFollowing);
    _syncToTaggedPosts(postRx.value);
    try {
      await _followRepository.followUser(userId);
    } catch (_) {
      postRx.value = p.copyWith(userFollow: wasFollowing);
      _syncToTaggedPosts(postRx.value);
    }
  }

  void _reportPost(TrafficPostModel post) {
    if (post.id == null) return;
    _postRepository
        .reportPost(postId: post.id!, reason: 'Nội dung không phù hợp')
        .then((_) => CustomAlert.showSuccess('Đã báo cáo bài viết'))
        .catchError((e) => CustomAlert.showError(e.toString()));
  }

  /// Đồng bộ thay đổi bài viết vào danh sách taggedPosts
  void _syncToTaggedPosts(TrafficPostModel updated) {
    final idx = taggedPosts.indexWhere((p) => p.id == updated.id);
    if (idx != -1) taggedPosts[idx] = updated;
  }

  void _addDummyPolyline() {
    polylines.add(
      Polyline(
        polylineId: const PolylineId('route_1'),
        points: const [
          LatLng(21.028511, 105.804817),
          LatLng(21.029511, 105.805817),
          LatLng(21.030511, 105.806817),
          LatLng(21.031511, 105.807817),
        ],
        color: Colors.blue,
        width: 5,
      ),
    );
  }
}
