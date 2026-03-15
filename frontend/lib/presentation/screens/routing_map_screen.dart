import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class RoutingMapScreen extends StatefulWidget {
  final LatLng hostelLocation;
  final String? hostelName;
  final String? hostelAddress;

  const RoutingMapScreen({
    Key? key, 
    required this.hostelLocation,
    this.hostelName,
    this.hostelAddress,
  }) : super(key: key);

  @override
  _RoutingMapScreenState createState() => _RoutingMapScreenState();
}

class _RoutingMapScreenState extends State<RoutingMapScreen> {
  LatLng? _currentLocation;
  List<LatLng> _routePoints = [];
  String _distance = "";
  String _duration = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initRoute();
  }

  Future<void> _initRoute() async {
    await _getUserLocation();
    if (_currentLocation != null) {
      await _getRoute();
    }
  }

  // 1. Get User's Current Location
  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLoading = false);
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLoading = false);
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _isLoading = false);
      return Future.error('Location permissions are permanently denied.');
    }

    // Capture the location
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
        
    if (mounted) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    }
  }

  // 2. Call the Routing API (OSRM)
  Future<void> _getRoute() async {
    if (_currentLocation == null) return;

    final start = _currentLocation!;
    final end = widget.hostelLocation;

    // OSRM API expects longitude,latitude format
    // Notice: geometries=geojson is critical for easy parsing on Flutter
    final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson&overview=full');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'];
        
        if (routes != null && routes.isNotEmpty) {
          final route = routes[0];
          final geometry = route['geometry']['coordinates'] as List;
          
          final distanceMeters = route['distance'];
          final durationSeconds = route['duration'];

          if (mounted) {
            setState(() {
              // Convert GeoJSON coords [longitude, latitude] to LatLng(latitude, longitude)
              _routePoints = geometry.map((coord) => LatLng(coord[1], coord[0])).toList();
              
              // Format distance & time
              _distance = (distanceMeters / 1000).toStringAsFixed(1) + " km";
              _duration = _formatDuration(durationSeconds);
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching route: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper method to format seconds into minutes/hours
  String _formatDuration(dynamic seconds) {
    int minutes = (seconds / 60).round();
    if (minutes < 60) return "$minutes min";
    int hours = minutes ~/ 60;
    int remainingMinutes = minutes % 60;
    return "${hours}h ${remainingMinutes}m";
  }

  // 3 & 4. Display Route on Map & Example UI showing distance and time
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hostelName ?? 'Route to Hostel'),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          if (widget.hostelAddress != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFF1E293B),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.hostelName ?? 'Hostel Details',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFFFACC15), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.hostelAddress!,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15)))
        : Stack(
            children: [
              // 3. Render the Map and the Polyline
              FlutterMap(
                options: MapOptions(
                  initialCenter: _currentLocation ?? widget.hostelLocation,
                  initialZoom: 13.0,
                ),
                children: [
                   TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.hostel_management_app', 
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 5.0,
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      if (_currentLocation != null)
                        Marker(
                          point: _currentLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                        ),
                      Marker(
                        point: widget.hostelLocation,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                      ),
                    ],
                  ),
                ],
              ),
              
              // 4. Floating UI Card showing Distance and Time
              if (_routePoints.isNotEmpty)
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: Card(
                    color: const Color(0xFF1E293B),
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.directions_car, color: Colors.blue, size: 30),
                              const SizedBox(height: 8),
                              Text(_duration, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                              Text('Est. Time', style: TextStyle(color: Colors.grey.shade400)),
                            ],
                          ),
                          Container(width: 1, height: 50, color: Colors.grey.shade700),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.route, color: Colors.red, size: 30),
                              const SizedBox(height: 8),
                              Text(_distance, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                              Text('Distance', style: TextStyle(color: Colors.grey.shade400)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
    );
  }
}
