import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/route_model.dart';
import '../../data/providers/routing_provider.dart';
import '../../data/services/routing_service.dart';
import '../../data/services/location_service.dart';
import '../widgets/route_info_widget.dart';

class RouteDisplayScreen extends StatefulWidget {
  final LatLng hostelLocation;
  final String hostelName;
  final String? hostelAddress;
  final Position? userLocation; // Optional: if not provided, will fetch current location

  const RouteDisplayScreen({
    Key? key,
    required this.hostelLocation,
    required this.hostelName,
    this.hostelAddress,
    this.userLocation,
  }) : super(key: key);

  @override
  State<RouteDisplayScreen> createState() => _RouteDisplayScreenState();
}

class _RouteDisplayScreenState extends State<RouteDisplayScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  
  Position? _userPosition;
  bool _isInitializing = true;
  String? _error;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _initializeAndCalculateRoute();
  }

  Future<void> _initializeAndCalculateRoute() async {
    try {
      // Get user location if not provided
      Position? userPos = widget.userLocation;
      if (userPos == null) {
        // Check and request permission
        String? permissionError =
            await _locationService.checkAndRequestPermission();
        if (permissionError != null) {
          if (mounted) {
            setState(() {
              _error = permissionError;
              _isInitializing = false;
            });
          }
          return;
        }

        // Get current location
        userPos = await _locationService.getCurrentLocation();
        if (userPos == null) {
          if (mounted) {
            setState(() {
              _error = 'Could not fetch current location';
              _isInitializing = false;
            });
          }
          return;
        }
      }

      if (mounted) {
        setState(() => _userPosition = userPos);

        // Set up routing provider
        final routingProvider =
            Provider.of<RoutingProvider>(context, listen: false);
        routingProvider.setStartPoint(
            LatLng(userPos!.latitude, userPos.longitude));
        routingProvider.setEndPoint(widget.hostelLocation);

        // Calculate route
        await routingProvider.calculateRoute();

        // Fit map to show both points
        _fitMapToRoute(
          LatLng(userPos.latitude, userPos.longitude),
          widget.hostelLocation,
        );

        setState(() => _isInitializing = false);
      }
    } catch (e) {
      debugPrint('Error initializing route: $e');
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _isInitializing = false;
        });
      }
    }
  }

  void _fitMapToRoute(LatLng start, LatLng end) {
    final bounds = LatLngBounds(start, end);
    _mapController.fitBounds(
      bounds,
      options: const FitBoundsOptions(
        padding: EdgeInsets.all(100),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Provider.of<RoutingProvider>(context, listen: false).reset();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.hostelName),
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Provider.of<RoutingProvider>(context, listen: false).reset();
              Navigator.pop(context);
            },
          ),
        ),
        body: _isInitializing
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFACC15),
                ),
              )
            : _error != null
                ? _buildErrorWidget()
                : _buildRouteMap(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[400],
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[400],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
                _isInitializing = true;
              });
              _initializeAndCalculateRoute();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFACC15),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteMap() {
    return Consumer<RoutingProvider>(
      builder: (context, routingProvider, _) {
        final route = routingProvider.currentRoute;
        final hasRoute = route != null && route.polylinePoints.isNotEmpty;

        return Stack(
          children: [
            // Map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: widget.hostelLocation,
                zoom: 15,
                maxZoom: 19,
                minZoom: 12,
              ),
              children: [
                // Map tiles
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  maxZoom: 19,
                ),

                // Route polyline
                if (hasRoute)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: route.polylinePoints,
                        strokeWidth: 4,
                        color: const Color(0xFF3B82F6),
                        borderStrokeWidth: 2,
                        borderColor: const Color(0xFFFACC15),
                      ),
                    ],
                  ),

                // Markers
                MarkerLayer(
                  markers: [
                    // Start point (user location)
                    if (_userPosition != null)
                      Marker(
                        point: LatLng(
                          _userPosition!.latitude,
                          _userPosition!.longitude,
                        ),
                        child: _buildMarker(
                          icon: Icons.my_location,
                          label: 'You',
                          color: const Color(0xFF10B981),
                        ),
                      ),

                    // End point (hostel)
                    Marker(
                      point: widget.hostelLocation,
                      child: _buildMarker(
                        icon: Icons.location_on,
                        label: 'Hostel',
                        color: const Color(0xFFFACC15),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Controls and info panels
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                children: [
                  // Profile selector
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFACC15).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildProfileButton('car', '🚗 Car',
                            routingProvider),
                        _buildDivider(),
                        _buildProfileButton('bike', '🚴 Bike',
                            routingProvider),
                        _buildDivider(),
                        _buildProfileButton('foot', '🚶 Walk',
                            routingProvider),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Recenter button
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFACC15).withOpacity(0.3),
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.my_location),
                      color: const Color(0xFFFACC15),
                      onPressed: () {
                        if (_userPosition != null) {
                          _fitMapToRoute(
                            LatLng(
                              _userPosition!.latitude,
                              _userPosition!.longitude,
                            ),
                            widget.hostelLocation,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Bottom route info
            if (hasRoute || routingProvider.isLoadingRoute)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: routingProvider.isLoadingRoute
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            border: Border.all(
                              color: const Color(0xFFFACC15).withOpacity(0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFFACC15),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Calculating route...',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RouteInfoWidget(
                        route: route,
                        expanded: _showDetails,
                        onClose: () {
                          setState(() => _showDetails = false);
                        },
                      ),
              ),

            // Expand details button
            if (hasRoute && !_showDetails)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  onPressed: () {
                    setState(() => _showDetails = true);
                  },
                  backgroundColor: const Color(0xFFFACC15),
                  child: const Icon(
                    Icons.expand_less,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMarker({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color == const Color(0xFFFACC15)
                  ? const Color(0xFF0F172A)
                  : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: color == const Color(0xFFFACC15)
                ? const Color(0xFF0F172A)
                : Colors.white,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileButton(
    String profile,
    String label,
    RoutingProvider provider,
  ) {
    final isSelected = provider.selectedProfile == profile;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          provider.setProfile(profile);
          await provider.calculateRoute();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFFFACC15)
                  : Colors.grey[400],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: const Color(0xFFFACC15).withOpacity(0.2),
      indent: 8,
      endIndent: 8,
    );
  }
}
