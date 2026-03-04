import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../controllers/map_controller.dart';

class MapView extends GetView<MapController> {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Google Map
        Obx(
          () => GoogleMap(
            onMapCreated: controller.onMapCreated,
            initialCameraPosition: CameraPosition(
              target: controller.center,
              zoom: 14.0,
            ),
            mapType: controller.currentMapType.value,
            trafficEnabled: controller.isTrafficEnabled.value,
            markers: Set<Marker>.of(controller.markers),
            polylines: Set<Polyline>.of(controller.polylines),
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // We use custom button
            zoomControlsEnabled: true, // We use custom buttons or gestures
          ),
        ),

        // Search Bar with Suggestions
        Positioned(
          top: 50,
          left: 20,
          right: 20,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: TextField(
                    controller: controller.searchController,
                    decoration: const InputDecoration(
                      hintText: 'Tìm kiếm địa điểm...',
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.grey),
                    ),
                    onChanged: (value) {
                      controller.fetchSuggestions(value);
                    },
                    onSubmitted: (value) {
                      controller.searchLocation(value);
                    },
                  ),
                ),
              ),
              Obx(
                () => controller.placeSuggestions.isNotEmpty
                    ? Container(
                        margin: const EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: controller.placeSuggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion =
                                controller.placeSuggestions[index];
                            return ListTile(
                              title: Text(suggestion['description']),
                              leading: const Icon(
                                Icons.location_on,
                                color: Colors.grey,
                              ),
                              onTap: () {
                                controller.selectSuggestion(suggestion);
                                FocusScope.of(context).unfocus();
                              },
                            );
                          },
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        // Control Buttons
        Positioned(
          right: 10,
          bottom: 90,
          child: Column(
            children: [
              // Map Type Toggle
              FloatingActionButton(
                heroTag: 'map_type',
                onPressed: controller.toggleMapType,
                backgroundColor: Colors.white,
                child: const Icon(Icons.layers, color: Colors.black87),
              ),
              const SizedBox(height: 10),

              // Traffic Toggle
              Obx(
                () => FloatingActionButton(
                  heroTag: 'traffic',
                  onPressed: controller.toggleTraffic,
                  backgroundColor: controller.isTrafficEnabled.value
                      ? Colors.blue
                      : Colors.white,
                  child: Icon(
                    Icons.traffic,
                    color: controller.isTrafficEnabled.value
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // My Location
              FloatingActionButton(
                heroTag: 'my_location',
                onPressed: controller.goToMyLocation,
                backgroundColor: Colors.white,
                child: Obx(
                  () => controller.isLoading.value
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Icon(Icons.my_location, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
