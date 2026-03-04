import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:traffic_app/widgets/custom_text_field.dart';

import '../controllers/camera_controller.dart';
import '../widgets/camera_buttons_row.dart';
import '../widgets/camera_hashtag_section.dart';
import '../widgets/camera_image_section.dart';
import '../widgets/camera_info_chips.dart';

class CameraView extends GetView<CameraController> {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CameraImageSection(),
                  const CameraButtonsRow(),
                  CustomTextField(
                    controller: controller.contentController,
                    hintText: 'camera_content_placeholder'.tr,
                    height: 108.h,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                  ),
                  SizedBox(height: 24.h),
                  const CameraHashtagSection(),
                  SizedBox(height: 24.h),
                  const CameraInfoChips(),
                  SizedBox(height: 70.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
