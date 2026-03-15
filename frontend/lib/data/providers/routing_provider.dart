import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import '../services/routing_service.dart';

class RoutingProvider with ChangeNotifier {
  RouteInfo? _currentRoute;
  LatLng? _startPoint;
  LatLng? _endPoint;
  bool _isLoadingRoute = false;
  String? _routeError;
  String _selectedProfile = 'car'; // 'car', 'bike', 'foot'

  // Getters
  RouteInfo? get currentRoute => _currentRoute;
  LatLng? get startPoint => _startPoint;
  LatLng? get endPoint => _endPoint;
  bool get isLoadingRoute => _isLoadingRoute;
  String? get routeError => _routeError;
  String get selectedProfile => _selectedProfile;

  bool get hasRoute => _currentRoute != null;
  bool get canCalculateRoute =>
      _startPoint != null && _endPoint != null && !_isLoadingRoute;

  /// Set start point (usually user's current location)
  void setStartPoint(LatLng point) {
    _startPoint = point;
    notifyListeners();
  }

  /// Set end point (hostel location)
  void setEndPoint(LatLng point) {
    _endPoint = point;
    notifyListeners();
  }

  /// Change routing profile
  void setProfile(String profile) {
    if (['car', 'bike', 'foot'].contains(profile)) {
      _selectedProfile = profile;
      notifyListeners();
    }
  }

  /// Calculate route from start to end point
  Future<bool> calculateRoute() async {
    if (_startPoint == null || _endPoint == null) {
      _routeError = 'Start and end points must be set';
      notifyListeners();
      return false;
    }

    _isLoadingRoute = true;
    _routeError = null;
    notifyListeners();

    try {
      final route = await RoutingService.getRouteOsrm(
        startLat: _startPoint!.latitude,
        startLng: _startPoint!.longitude,
        endLat: _endPoint!.latitude,
        endLng: _endPoint!.longitude,
        profile: _selectedProfile,
      );

      if (route != null && route.polylinePoints.isNotEmpty) {
        _currentRoute = route;
        _routeError = null;
        debugPrint(
            '✓ Route calculated: ${route.formattedDistance}, ${route.formattedDuration}');
      } else {
        _currentRoute = null;
        _routeError = 'Failed to calculate route. Please try again.';
      }
    } catch (e) {
      _currentRoute = null;
      _routeError = 'Error: ${e.toString()}';
      debugPrint('Route calculation error: $e');
    } finally {
      _isLoadingRoute = false;
      notifyListeners();
    }

    return _currentRoute != null;
  }

  /// Clear the current route
  void clearRoute() {
    _currentRoute = null;
    _routeError = null;
    notifyListeners();
  }

  /// Clear all points and route
  void reset() {
    _startPoint = null;
    _endPoint = null;
    _currentRoute = null;
    _routeError = null;
    _isLoadingRoute = false;
    _selectedProfile = 'car';
    notifyListeners();
  }

  /// Recalculate route with current points and profile
  Future<bool> recalculateRoute() async {
    if (!canCalculateRoute) return false;
    return calculateRoute();
  }

  /// Get route summary as string
  String getRouteSummary() {
    if (_currentRoute == null) return 'No route calculated';

    return '${_currentRoute!.formattedDistance} • ${_currentRoute!.formattedDuration}';
  }
}
