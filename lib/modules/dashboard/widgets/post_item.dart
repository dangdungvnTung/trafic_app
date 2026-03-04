import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../data/models/traffic_post_model.dart';
import '../../../widgets/loading_widget.dart';
import 'like_icon.dart';

class PostItem extends StatelessWidget {
  final TrafficPostModel post;
  final VoidCallback onLike;
  final VoidCallback onReport;
  final VoidCallback onFollow;
  final int? currentUserId;

  const PostItem({
    super.key,
    required this.post,
    required this.onLike,
    required this.onReport,
    required this.onFollow,
    this.currentUserId,
  });

  /// Hiện badge "+" khi:
  /// 1. API trả về follow == false
  /// 2. Không phải bài viết của chính mình
  bool get _showFollowBadge {
    if (post.userFollow == true) return false;
    final postUserId = int.tryParse(post.userId ?? '');
    if (postUserId != null && postUserId == currentUserId) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF04060F).withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 60,
          ),
        ],
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image/Map Area
          Container(
            height: 180.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child:
                  post.fullImageUrls != null && post.fullImageUrls!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: post.fullImageUrls!.first,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: LoadingWidget()),
                      errorWidget: (context, url, error) => Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 48.w,
                          color: Colors.grey[400],
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.location_on,
                        size: 48.w,
                        color: Colors.grey[400],
                      ),
                    ),
            ),
          ),
          SizedBox(height: 12.h),
          // User Info
          Row(
            children: [
              GestureDetector(
                onTap: _showFollowBadge ? onFollow : null,
                child: SizedBox(
                  width: 46.w,
                  height: 46.w,
                  child: Stack(
                    children: [
                      ClipOval(
                        child: post.fullAvatarUrl != null
                            ? CachedNetworkImage(
                                imageUrl: post.fullAvatarUrl!,
                                width: 40.w,
                                height: 40.w,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 40.w,
                                  height: 40.w,
                                  color: Colors.grey[300],
                                  child: LoadingWidget(
                                    width: 40.w,
                                    height: 40.w,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 40.w,
                                  height: 40.w,
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.person,
                                    size: 24.w,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              )
                            : Container(
                                width: 40.w,
                                height: 40.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[300],
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 24.w,
                                  color: Colors.grey[600],
                                ),
                              ),
                      ),
                      // "+" badge – chỉ hiện khi chưa follow và không phải bài của mình
                      if (_showFollowBadge)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 24.w,
                            height: 24.w,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4D5DFA),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 18.sp,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                post.userName ?? 'Người dùng',
                style: TextStyle(
                  fontSize: 15.2.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C1C1E),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // Content
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF616161),
                height: 1.4,
              ),
              children: [
                TextSpan(text: "${post.content} "),
                if (post.hashtags?.isNotEmpty ?? false)
                  TextSpan(
                    text: " #${post.hashtags?.join(" #") ?? ''}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4D5DFA),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onLike,
                child: Row(
                  children: [
                    LikeIcon(isLiked: post.isLiked ?? false),
                    SizedBox(width: 8.w),
                    Text(
                      (post.likes ?? 0).toString(),
                      style: TextStyle(
                        fontSize: 14.4.sp,
                        fontWeight: FontWeight.w600,
                        color: (post.isLiked ?? false)
                            ? const Color(0xFF4D5DFA)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onReport,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: const Color(0xFFF75555)),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    "Báo cáo".tr,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF75555),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
