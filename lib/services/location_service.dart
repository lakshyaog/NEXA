import 'package:geolocator/geolocator.dart';

/// Why a location request could not be fulfilled. Each case maps to a
/// distinct, actionable message in the UI rather than a generic failure.
enum LocationProblem {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

class LocationFailure implements Exception {
  const LocationFailure(this.problem, this.message);
  final LocationProblem problem;
  final String message;

  @override
  String toString() => message;
}

class LocationService {
  const LocationService();

  /// Requests permission if needed, then returns the current position.
  ///
  /// Throws [LocationFailure] instead of letting platform exceptions escape,
  /// so callers can present a specific reason and a matching remedy.
  Future<Position> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure(
        LocationProblem.serviceDisabled,
        'Location services are turned off. Enable GPS and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        LocationProblem.permissionDenied,
        'Location permission was denied. Attendance check-in needs your '
        'location to verify you are inside the branch geofence.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        LocationProblem.permissionDeniedForever,
        'Location permission is permanently denied. Enable it for this app '
        'in system settings to use check-in.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw const LocationFailure(
          LocationProblem.timeout,
          'Could not get a GPS fix in time. Move to an open area and retry.',
        );
      }
      throw LocationFailure(
        LocationProblem.unknown,
        'Could not read your location: $e',
      );
    }
  }

  /// Great-circle distance in metres between two coordinates.
  double distanceBetween({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) =>
      Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng);

  Future<void> openAppSettings() => Geolocator.openAppSettings();
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
