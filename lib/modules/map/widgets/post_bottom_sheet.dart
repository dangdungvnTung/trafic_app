import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../data/models/traffic_post_model.dart';
import '../../../widgets/primary_button.dart';
import '../../dashboard/widgets/post_item.dart';

class PostBottomSheet {
  static void show({
    required TrafficPostModel post,
    required int? currentUserId,
    required Future<void> Function(Rx<TrafficPostModel>) onLike,
    required Future<void> Function(Rx<TrafficPostModel>) onFollow,
    required void Function(TrafficPostModel) onReport,
  }) {
    final postRx = post.obs;

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 8.h),
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
              child: Obx(
                () => Column(
                  children: [
                    PostItem(
                      post: postRx.value,
                      currentUserId: currentUserId,
                      onLike: () => onLike(postRx),
                      onReport: () {
                        Get.back();
                        onReport(postRx.value);
                      },
                      onFollow: () => onFollow(postRx),
                    ),
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        onPressed: () => Get.back(),
                        text: 'map_close'.tr,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
