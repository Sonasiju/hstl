import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/providers/hostel_provider.dart';
import 'hostel_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(12.9715987, 77.5945627); // Bangalore fallback
  bool _locationLoaded = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _locationLoaded = true;
      });
      _mapController.move(_currentPosition, 14.0);
    } catch (e) {
      // GPS unavailable — keep fallback position, no crash
      debugPrint('Location error (non-fatal): $e');
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hostels Near Me'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'My Location',
            onPressed: () {
              _mapController.move(_currentPosition, 14.0);
            },
          ),
        ],
      ),
      body: Consumer<HostelProvider>(
        builder: (context, provider, child) {
          final hostelMarkers = _buildHostelMarkers(provider, context);

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 12.0,
              minZoom: 4.0,
              maxZoom: 18.0,
            ),
            children: [
              // OpenStreetMap tile layer — completely free, no API key needed
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hostel.management.app',
                maxZoom: 18,
              ),
              // Hostel markers
              MarkerLayer(markers: hostelMarkers),
              // Current location marker
              if (_locationLoaded)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              // OSM Attribution (required by OSM license)
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  List<Marker> _buildHostelMarkers(HostelProvider provider, BuildContext context) {
    final List<Marker> markers = [];

    for (var hostel in provider.hostels) {
      if (hostel['location'] == null) continue;
      final lat = hostel['location']['lat'];
      final lng = hostel['location']['lng'];
      if (lat == null || lng == null) continue;

      final point = LatLng((lat as num).toDouble(), (lng as num).toDouble());

      markers.add(
        Marker(
          point: point,
          width: 180,
          height: 68,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HostelDetailsScreen(hostel: hostel),
                ),
              );
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Text(
                    '₹${hostel['rentPerMonth']}/mo',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB), size: 20),
              ],
            ),
          ),
        ),
      );
    }
    return markers;
  }
}
