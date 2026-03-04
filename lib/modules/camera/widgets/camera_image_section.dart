import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/camera_controller.dart';

class CameraImageSection extends GetView<CameraController> {
  const CameraImageSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!controller.hasImage.value) {
          controller.pickImageFromGallery();
        }
      },
      child: Container(
        height: 370.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(32.r),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32.r),
          child: Obx(() {
            if (controller.hasImage.value && controller.imageFile != null) {
              return Image.file(controller.imageFile!, fit: BoxFit.cover);
            }
            return Container(
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 64.sp, color: Colors.white54),
                  SizedBox(height: 12.h),
                  Text(
                    'camera_capture_or_pick'.tr,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
