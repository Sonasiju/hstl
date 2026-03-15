import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../data/services/location_service.dart';
import '../../data/providers/hostel_provider.dart';
import 'hostel_details_screen.dart';
import 'booking_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  Position? _currentPosition;
  bool _isLoadingLoc = true;
  bool _isSearching = false;
  String? _error;
  List<dynamic> _searchResults = [];
  bool _showSearchResults = false;
  dynamic _selectedHostel; // hostel shown in bottom panel
  LatLng? _lastSearchCenter;
  bool _showSearchThisArea = false;

  String _selectedType = 'Any Share';
  final List<String> _types = ['Any Share', 'Men & Boys', 'Girls & Women', 'coed'];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ──────────────────────────── LOCATION ────────────────────────────

  Future<void> _initLocation() async {
    setState(() {
      _isLoadingLoc = true;
      _error = null;
    });

    String? permissionError =
        await _locationService.checkAndRequestPermission();
    if (permissionError != null) {
      if (mounted) {
        setState(() {
          _error = permissionError;
          _isLoadingLoc = false;
        });
      }
      return;
    }

    Position? pos = await _locationService.getCurrentLocation();
    if (pos != null) {
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _isLoadingLoc = false;
        });
        _mapController.move(
            LatLng(pos.latitude, pos.longitude), 15);
        _lastSearchCenter = LatLng(pos.latitude, pos.longitude);
        _refreshNearbyHostels();
      }
    } else {
      if (mounted) {
        setState(() {
          _error =
              "Could not fetch current location. Please check if GPS is on.";
          _isLoadingLoc = false;
        });
      }
    }

    _locationService.getLocationStream().listen((pos) {
      if (mounted) {
        setState(() => _currentPosition = pos);
      }
    });
  }

  Future<void> _refreshNearbyHostels() async {
    if (_currentPosition == null) return;
    final hostelProvider =
        Provider.of<HostelProvider>(context, listen: false);
    
    debugPrint('MAP: Refreshing hostels at ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
    
    // Fetch both backend and OSM hostels in parallel
    await hostelProvider.fetchHostelsForArea(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      radiusKm: 10,
    );
    
    if (mounted) {
      debugPrint('MAP: Refresh complete. DB=${hostelProvider.hostels.length}, OSM=${hostelProvider.osmHostels.length}');
      setState(() {}); // Trigger UI rebuild
    }
  }

  void _goToMyLocation() {
    if (_currentPosition != null) {
      _mapController.move(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15);
    }
  }

  // ──────────────────────────── PLACE SEARCH ────────────────────────────

  Future<void> _searchPlace(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=8&addressdetails=1',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'HostelHubApp/1.0',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final results = json.decode(response.body) as List;
        setState(() {
          _searchResults = results;
          _showSearchResults = results.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Place search error: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectPlace(dynamic place) {
    final double lat = double.parse(place['lat'].toString());
    final double lon = double.parse(place['lon'].toString());
    _mapController.move(LatLng(lat, lon), 14);
    _searchController.text = place['display_name']?.toString().split(',').first ?? '';
    _searchFocus.unfocus();
    setState(() {
      _showSearchResults = false;
      _searchResults = [];
    });
    // Fetch BOTH backend and OSM hostels around searched location
    final hostelProvider =
        Provider.of<HostelProvider>(context, listen: false);
    _lastSearchCenter = LatLng(lat, lon);
    setState(() => _showSearchThisArea = false);
    hostelProvider.fetchHostelsForArea(lat, lon, radiusKm: 10);
  }

  Future<void> _searchThisArea() async {
    final center = _mapController.camera.center;
    _lastSearchCenter = center;
    setState(() => _showSearchThisArea = false);

    final hostelProvider =
        Provider.of<HostelProvider>(context, listen: false);
    await hostelProvider.fetchHostelsForArea(
      center.latitude,
      center.longitude,
      radiusKm: 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hostelProvider = Provider.of<HostelProvider>(context);
    final List<dynamic> nearbyHostels = _currentPosition != null
        ? hostelProvider.getNearbyHostels(
            _currentPosition!.latitude, _currentPosition!.longitude)
        : [...hostelProvider.hostels, ...hostelProvider.osmHostels];

    debugPrint('MAP BUILD: Total hostels = ${nearbyHostels.length} (DB=${hostelProvider.hostels.length}, OSM=${hostelProvider.osmHostels.length})');

    // Apply type filter
    final filteredHostels = nearbyHostels.where((h) {
      final type = (h['type'] ?? '').toString().toLowerCase();
      bool typeMatch = true;
      if (_selectedType == 'Men & Boys') {
        typeMatch = type == 'boys' || type == 'men' || type == 'mens' || type == 'gents';
      } else if (_selectedType == 'Girls & Women') {
        typeMatch = type == 'girls' || type == 'women' || type == 'womens' || type == 'ladies';
      } else if (_selectedType != 'Any Share') {
        typeMatch = type == _selectedType.toLowerCase();
      }
      
      // Enforce the 10km distance filter only on OSM hostels. Database hostels are always shown.
      bool distMatch = true;
      final source = h['source']?.toString() ?? '';
      final isOsm = source == 'osm' || (h['_id']?.toString().startsWith('osm_') == true);
      if (isOsm) {
        final dist = h['distance'] as double?;
        if (dist != null && dist > 10.0) {
          distMatch = false; // Exclude distant OSM hostels
        }
      }
      
      return typeMatch && distMatch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // ── MAP ──
          _buildMap(filteredHostels),

          // ── TOP BAR (Search + back-compatible appbar) ──
          SafeArea(
            child: Column(
              children: [
                _buildSearchBar(),
                _buildFilters(),
                if (_showSearchResults) _buildSearchDropdown(),
                const SizedBox(height: 10),
                if (_showSearchThisArea)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFACC15),
                      foregroundColor: Colors.black,
                      elevation: 8,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Search this area', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: _searchThisArea,
                  ),
              ],
            ),
          ),

          // ── LOADING INDICATOR ──
          if (hostelProvider.isLoading || _isLoadingLoc)
            Positioned(
              top: 110,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFFFACC15)),
                      ),
                      SizedBox(width: 10),
                      Text("Finding nearby hostels...",
                          style:
                              TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),

          // ── ERROR ──
          if (_error != null) _buildErrorOverlay(),

          // ── FABs ──
          Positioned(
            right: 16,
            bottom: _selectedHostel != null ? 260 : 30,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'refresh',
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: const Color(0xFFFACC15),
                  onPressed: _refreshNearbyHostels,
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'myloc',
                  backgroundColor: const Color(0xFFFACC15),
                  foregroundColor: Colors.black,
                  onPressed: _goToMyLocation,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),

          // ── SELECTED HOSTEL BOTTOM SHEET ──
          if (_selectedHostel != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildSelectedHostelPanel(_selectedHostel!),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────── SEARCH BAR ────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search, color: Color(0xFFFACC15)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search a city or place...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: _searchPlace,
              textInputAction: TextInputAction.search,
              onSubmitted: _searchPlace,
            ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFFFACC15)),
              ),
            )
          else if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey, size: 20),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchResults = [];
                  _showSearchResults = false;
                });
                _searchFocus.unfocus();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _types.map((type) {
          final isSelected = _selectedType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedType = type;
                    _selectedHostel = null; // hide panel if filtered out
                  });
                }
              },
              selectedColor: const Color(0xFFFACC15),
              backgroundColor: const Color(0xFF1E293B),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: isSelected ? const Color(0xFFFACC15) : Colors.grey[800]!),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border.all(color: const Color(0xFFFACC15).withOpacity(0.2)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.white.withOpacity(0.05)),
        itemBuilder: (context, index) {
          final place = _searchResults[index];
          final name =
              place['display_name']?.toString() ?? 'Unknown Place';
          final parts = name.split(',');
          return ListTile(
            dense: true,
            leading:
                const Icon(Icons.place, color: Color(0xFFFACC15), size: 20),
            title: Text(
              parts.first.trim(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: parts.length > 1
                ? Text(
                    parts.sublist(1).join(', ').trim(),
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            onTap: () => _selectPlace(place),
          );
        },
      ),
    );
  }

  // ──────────────────────────── MAP ────────────────────────────

  Widget _buildMap(List<dynamic> nearbyHostels) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition != null
            ? LatLng(
                _currentPosition!.latitude, _currentPosition!.longitude)
            : const LatLng(12.9716, 77.5946),
        initialZoom: 14,
        onTap: (_, __) {
          // Dismiss search results on map tap
          _searchFocus.unfocus();
          setState(() {
            _showSearchResults = false;
            _selectedHostel = null;
          });
        },
        onPositionChanged: (pos, hasGesture) {
          if (hasGesture && _lastSearchCenter != null && pos.center != null) {
            final dist = _locationService.calculateDistance(
              _lastSearchCenter!.latitude,
              _lastSearchCenter!.longitude,
              pos.center!.latitude,
              pos.center!.longitude,
            );
            if (dist > 1.5 && !_showSearchThisArea) {
              setState(() => _showSearchThisArea = true);
            }
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.hstl.hostel_management_app',
        ),
        MarkerLayer(
          markers: [
            // ── USER LOCATION ──
            if (_currentPosition != null)
              Marker(
                point: LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude),
                width: 55,
                height: 55,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.blue.withOpacity(0.5), width: 2),
                      ),
                    ),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.blueAccent,
                              blurRadius: 8,
                              spreadRadius: 2)
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // ── HOSTEL MARKERS ──
            ...nearbyHostels.map((hostel) {
              final loc = hostel['location'];
              if (loc == null) return null;
              final isSelected = _selectedHostel != null &&
                  (_selectedHostel!['_id'] == hostel['_id'] ||
                      _selectedHostel!['id'] == hostel['id']);
              
              // Determine marker color based on source
              final source = hostel['source']?.toString() ?? '';
              final isDatabase = source == 'database' || (hostel['_id']?.toString().startsWith('osm_') != true);
              final markerColor = isDatabase 
                  ? const Color(0xFF10B981)  // Green for database hostels
                  : const Color(0xFF3B82F6); // Blue for OSM hostels

              return Marker(
                point: LatLng(
                    (loc['lat'] as num).toDouble(),
                    (loc['lng'] as num).toDouble()),
                width: isSelected ? 140 : 120,
                height: isSelected ? 60 : 50,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedHostel = hostel);
                    _mapController.move(
                      LatLng((loc['lat'] as num).toDouble(),
                          (loc['lng'] as num).toDouble()),
                      15,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? markerColor
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: markerColor,
                          width: isSelected ? 0 : 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: markerColor
                              .withOpacity(isSelected ? 0.5 : 0.2),
                          blurRadius: isSelected ? 12 : 4,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isDatabase ? Icons.location_city : Icons.map,
                            color: isSelected
                                ? Colors.white
                                : markerColor,
                            size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            hostel['name']?.toString() ?? 'Hostel',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).whereType<Marker>().toList(),
          ],
        ),
      ],
    );
  }

  // ──────────────────────────── SELECTED HOSTEL PANEL ────────────────────────────

  Widget _buildSelectedHostelPanel(dynamic hostel) {
    final phone = hostel['phone']?.toString();
    final email = hostel['email']?.toString();
    final type = hostel['type']?.toString();
    final city = hostel['city']?.toString() ?? hostel['address']?.toString() ?? '';
    
    // Determine if this is a database or OSM hostel
    final source = hostel['source']?.toString() ?? '';
    final isDatabase = source == 'database' || (hostel['_id']?.toString().startsWith('osm_') != true);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, -4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Source badge
                if (!isDatabase)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map, color: Colors.blueAccent, size: 12),
                        SizedBox(width: 4),
                        Text('OpenStreetMap', style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: Colors.green, size: 12),
                        SizedBox(width: 4),
                        Text('Registered Hostel', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hostel['name']?.toString() ?? 'Hostel',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: Colors.grey, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  city,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Close button
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () =>
                          setState(() => _selectedHostel = null),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Stats row
                Row(
                  children: [
                    if (isDatabase && hostel['rentPerMonth'] != null)
                      _buildChip(
                          '₹${hostel['rentPerMonth']}/mo',
                          const Color(0xFF10B981),
                          Colors.white),
                    if (isDatabase) const SizedBox(width: 8),
                    if (type != null)
                      _buildChip(type.toUpperCase(), Colors.blueAccent, Colors.white),
                    const SizedBox(width: 8),
                    if (hostel['ratings'] != null)
                      _buildChip(
                          '⭐ ${hostel['ratings']}',
                          const Color(0xFF1E293B),
                          Colors.white),
                    const SizedBox(width: 8),
                    if (hostel['distance'] != null)
                      _buildChip(
                          '${(hostel['distance'] as double).toStringAsFixed(1)} km',
                          Colors.green.withOpacity(0.2),
                          Colors.green),
                  ],
                ),
                // Contact info
                if (phone != null || email != null) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.contact_phone,
                          color: Color(0xFFFACC15), size: 16),
                      const SizedBox(width: 6),
                      const Text('Contact',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (phone != null)
                    _buildContactRow(Icons.phone, phone, 'tel:$phone'),
                  if (email != null)
                    _buildContactRow(Icons.email, email, 'mailto:$email'),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: isDatabase
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BookingScreen(hostel: hostel),
                              ),
                            );
                          },
                          child: const Text('Book Visit',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        )
                      : ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: const Text('View Details',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    HostelDetailsScreen(hostel: hostel),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String url) {
    return GestureDetector(
      onTap: () async {
        try {
          final uri = Uri.parse(url);
          // Use url_launcher via platform channel would be ideal but
          // to keep it simple we display a dialog
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Text('Contact',
                  style: TextStyle(color: Colors.white)),
              content: Row(
                children: [
                  Icon(icon, color: const Color(0xFFFACC15)),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(label,
                        style: const TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close',
                      style: TextStyle(color: Color(0xFFFACC15))),
                ),
              ],
            ),
          );
        } catch (_) {}
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFACC15), size: 16),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFFFACC15))),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────── ERROR OVERLAY ────────────────────────────

  Widget _buildErrorOverlay() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_error!.contains("Settings"))
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: OutlinedButton(
                      onPressed: () => _locationService.openSettings(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Open Settings'),
                    ),
                  ),
                ElevatedButton(
                  onPressed: _initLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFACC15),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Try Again',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
