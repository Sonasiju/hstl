import 'package:latlong2/latlong.dart';

class RouteInfo {
  final List<LatLng> polylinePoints;
  final double distance; // in kilometers
  final int duration; // in seconds
  final List<Map<String, dynamic>> steps;

  RouteInfo({
    required this.polylinePoints,
    required this.distance,
    required this.duration,
    required this.steps,
  });

  /// Get formatted distance string
  String get formattedDistance {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)}m';
    }
    return '${distance.toStringAsFixed(2)}km';
  }

  /// Get formatted duration string
  String get formattedDuration {
    if (duration < 60) {
      return '${duration}s';
    }
    int minutes = (duration / 60).floor();
    if (minutes < 60) {
      return '${minutes}m';
    }
    int hours = (minutes / 60).floor();
    int remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${remainingMinutes}m';
  }

  /// Get duration in hours (for decimal representation)
  double get durationInHours {
    return duration / 3600;
  }

  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    List<LatLng> points = [];

    // Handle OSRM response format
    if (json['routes'] != null && json['routes'].isNotEmpty) {
      var geometry = json['routes'][0]['geometry'];

      if (geometry is String) {
        // Decode polyline string if it's encoded
        points = _decodePolyline(geometry);
      } else if (geometry is Map && geometry['coordinates'] != null) {
        // Handle coordinate list format
        for (var coord in geometry['coordinates']) {
          points.add(LatLng(coord[1], coord[0])); // [lng, lat] -> LatLng
        }
      }

      var leg = json['routes'][0]['legs'] != null && json['routes'][0]['legs'].isNotEmpty
          ? json['routes'][0]['legs'][0]
          : null;

      double distanceKm = 0;
      int durationSeconds = 0;
      List<Map<String, dynamic>> stepsData = [];

      if (leg != null) {
        distanceKm = (leg['distance'] ?? 0) / 1000;
        durationSeconds = ((leg['duration'] ?? 0) as num).toInt();

        if (leg['steps'] != null) {
          stepsData = List<Map<String, dynamic>>.from(leg['steps'] ?? []);
        }
      }

      return RouteInfo(
        polylinePoints: points.isNotEmpty ? points : [LatLng(0, 0)],
        distance: distanceKm,
        duration: durationSeconds,
        steps: stepsData,
      );
    }

    // Fallback for empty response
    return RouteInfo(
      polylinePoints: [LatLng(0, 0)],
      distance: 0,
      duration: 0,
      steps: [],
    );
  }

  /// Decode polyline string (Google polyline encoding)
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int result = 0;
      int shift = 0;
      int b;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lat += dlat;

      result = 0;
      shift = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}

class RoutingRequest {
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final String profile; // 'car', 'foot', 'bike'

  RoutingRequest({
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    this.profile = 'car',
  });

  String toOsrmUrl() {
    return 'https://router.project-osrm.org/route/v1/$profile/$startLng,$startLat;$endLng,$endLat'
        '?overview=full&steps=true&geometries=geojson';
  }
}
