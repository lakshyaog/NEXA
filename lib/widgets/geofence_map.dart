import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/app_colors.dart';

/// OpenStreetMap view showing a branch marker and its geofence radius.
///
/// Uses flutter_map rather than Google Maps so the project needs no billed
/// Maps API key; tiles come from the public OSM tile server.
class GeofenceMap extends StatelessWidget {
  const GeofenceMap({
    super.key,
    required this.center,
    required this.radiusMeters,
    this.userPosition,
    this.onTap,
    this.mapController,
  });

  final LatLng center;
  final double radiusMeters;
  final LatLng? userPosition;
  final void Function(LatLng point)? onTap;
  final MapController? mapController;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 16,
        onTap: onTap == null ? null : (_, point) => onTap!(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.nexa_admin_lite',
        ),
        CircleLayer(
          circles: [
            CircleMarker(
              point: center,
              radius: radiusMeters,
              useRadiusInMeter: true,
              color: AppColors.lavenderAccent.withValues(alpha: 0.18),
              borderColor: AppColors.lavenderAccent,
              borderStrokeWidth: 2,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 44,
              height: 44,
              child: const Icon(Icons.location_on,
                  size: 44, color: AppColors.pinkAccent),
            ),
            if (userPosition != null)
              Marker(
                point: userPosition!,
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
