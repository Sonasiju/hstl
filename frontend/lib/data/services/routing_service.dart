import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';

class RoutingService {
  static const String _osrmBaseUrl = 'https://router.project-osrm.org';
  static const String _openRouteServiceUrl = 'https://api.openrouteservice.org';

  /// Get route using OSRM (free, no API key required)
  /// profile can be: 'car', 'bike', 'foot'
  static Future<RouteInfo?> getRouteOsrm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String profile = 'car',
    bool alternatives = false,
  }) async {
    try {
      // OSRM uses [lng, lat] format
      final url =
          '$_osrmBaseUrl/route/v1/$profile/$startLng,$startLat;$endLng,$endLat'
          '?overview=full&steps=true&geometries=geojson&alternatives=$alternatives';

      debugPrint('📍 Routing request: $url');

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✓ Route fetched successfully');
        return RouteInfo.fromJson(data);
      } else {
        debugPrint('✗ Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
      return null;
    }
  }

  /// Get route using OpenRouteService (requires API key)
  /// You need to set the API key in environment or config
  static Future<RouteInfo?> getRouteOpenRouteService({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String profile = 'driving-car',
    String? apiKey,
  }) async {
    try {
      if (apiKey == null) {
        debugPrint('⚠️ OpenRouteService API key not provided');
        return null;
      }

      final body = {
        'coordinates': [
          [startLng, startLat],
          [endLng, endLat],
        ],
        'profile': profile,
        'format': 'geojson',
      };

      final response = await http.post(
        Uri.parse('$_openRouteServiceUrl/v2/directions/$profile'),
        headers: {
          'Accept': 'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
          'Authorization': apiKey,
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RouteInfo.fromJson(data);
      } else {
        debugPrint('✗ Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching route from OpenRouteService: $e');
      return null;
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  static double calculateDistance(LatLng start, LatLng end) {
    const double earthRadiusKm = 6371.0;

    double lat1 = start.latitude * pi / 180;
    double lat2 = end.latitude * pi / 180;
    double deltaLat = (end.latitude - start.latitude) * pi / 180;
    double deltaLng = (end.longitude - start.longitude) * pi / 180;

    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLng / 2) * sin(deltaLng / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Get estimated travel time based on distance and average speed
  /// Returns time in seconds
  static int estimateTravelTime(double distanceKm, {String? mode = 'car'}) {
    // Average speeds (km/h)
    final speeds = {
      'car': 60,
      'bike': 20,
      'foot': 5,
      'default': 60,
    };

    final speed = speeds[mode] ?? speeds['default']!;
    return ((distanceKm / speed) * 3600).toInt();
  }

  /// Format coordinates for display
  static String formatCoordinates(double lat, double lng) {
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  /// Simplify polyline by removing points (useful for performance)
  static List<LatLng> simplifyPolyline(
    List<LatLng> polyline, {
    double tolerance = 0.00001,
  }) {
    if (polyline.length < 3) return polyline;

    List<LatLng> simplified = [polyline.first];

    for (int i = 1; i < polyline.length - 1; i++) {
      double distance = _perpendicularDistance(
        polyline[i],
        polyline[simplified.length - 1],
        polyline[i + 1],
      );

      if (distance > tolerance) {
        simplified.add(polyline[i]);
      }
    }

    simplified.add(polyline.last);
    return simplified;
  }

  static double _perpendicularDistance(
    LatLng point,
    LatLng lineStart,
    LatLng lineEnd,
  ) {
    double x = point.latitude;
    double y = point.longitude;
    double x1 = lineStart.latitude;
    double y1 = lineStart.longitude;
    double x2 = lineEnd.latitude;
    double y2 = lineEnd.longitude;

    double A = x - x1;
    double B = y - y1;
    double C = x2 - x1;
    double D = y2 - y1;

    double dot = A * C + B * D;
    double lenSq = C * C + D * D;

    double param = (lenSq != 0) ? dot / lenSq : -1;

    double xx, yy;

    if (param < 0) {
      xx = x1;
      yy = y1;
    } else if (param > 1) {
      xx = x2;
      yy = y2;
    } else {
      xx = x1 + param * C;
      yy = y1 + param * D;
    }

    double dx = x - xx;
    double dy = y - yy;
    return sqrt(dx * dx + dy * dy);
  }
}
