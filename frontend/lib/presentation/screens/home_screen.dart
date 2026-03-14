import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../data/providers/hostel_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/location_service.dart';
import 'booking_screen.dart';
import 'hostel_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  Position? _currentPosition;
  bool _isLoadingLocation = true;

  List<dynamic> _allHostels = [];
  List<dynamic> _filteredHostels = [];
  bool _isLoadingHostels = false;

  // Area search
  bool _isGeocoding = false;
  List<dynamic> _geocodeResults = [];
  bool _showGeoResults = false;
  double? _searchLat;
  double? _searchLng;
  String _searchAreaLabel = '';

  String _selectedType = 'Any Share';
  final List<String> _types = ['Any Share', 'Men & Boys', 'Girls & Women', 'coed'];

  @override
  void initState() {
    super.initState();
    _initAll();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _initAll() async {
    await _fetchLocation();
    await _fetchHostels();
  }

  Future<void> _fetchLocation() async {
    try {
      await _locationService.checkAndRequestPermission();
      final pos = await _locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _isLoadingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _fetchHostels() async {
    setState(() => _isLoadingHostels = true);

    try {
      final provider = Provider.of<HostelProvider>(context, listen: false);

      if (_searchLat != null && _searchLng != null) {
        // Fetch for searched area
        await provider.fetchHostelsForArea(_searchLat!, _searchLng!, radiusKm: 10);
        _buildHostelListFrom(provider, lat: _searchLat!, lng: _searchLng!);
      } else if (_currentPosition != null) {
        // Fetch for current location
        await provider.fetchHostelsForArea(
            _currentPosition!.latitude, _currentPosition!.longitude, radiusKm: 10);
        _buildHostelListFrom(provider,
            lat: _currentPosition!.latitude, lng: _currentPosition!.longitude);
      } else {
        await provider.fetchHostels();
        _buildHostelListFrom(provider);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHostels = false);
    }
  }

  void _buildHostelListFrom(HostelProvider provider,
      {double? lat, double? lng}) {
    List<dynamic> combined;
    debugPrint('DEBUG _buildHostelListFrom: lat=$lat, lng=$lng');
    
    if (lat != null && lng != null) {
      combined = provider.getNearbyHostels(lat, lng);
    } else {
      // Combine all available hostels when no location specified
      final allDb = provider.hostels;
      final allOsm = provider.osmHostels;
      combined = [...allDb, ...allOsm];
      debugPrint('DEBUG: Combined ${allDb.length} DB + ${allOsm.length} OSM = ${combined.length} total');
    }

    if (mounted) {
      setState(() {
        _allHostels = combined;
        _isLoadingHostels = false;
      });
      debugPrint('DEBUG: _allHostels set to ${_allHostels.length} hostels');
      _applyFilters();
    }
  }

  // ────────────────────── SEARCH / GEOCODE ──────────────────────

  void _onSearchChanged() {
    final q = _searchController.text.trim();
    if (q.isEmpty) {
      setState(() {
        _geocodeResults = [];
        _showGeoResults = false;
      });
      _applyFilters(); // filter existing list
    } else {
      _applyFilters(); // local filter while typing
      // Start geocoding after short delay
      Future.delayed(const Duration(milliseconds: 600), () {
        if (_searchController.text.trim() == q && mounted) {
          _geocodeSearch(q);
        }
      });
    }
  }

  Future<void> _geocodeSearch(String query) async {
    if (query.length < 3) return;
    setState(() => _isGeocoding = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&limit=6&addressdetails=1',
      );
      final resp = await http.get(uri, headers: {'User-Agent': 'HostelHubApp/1.0'})
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200 && mounted) {
        final results = json.decode(resp.body) as List;
        setState(() {
          _geocodeResults = results;
          _showGeoResults = results.isNotEmpty;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isGeocoding = false);
  }

  Future<void> _selectArea(dynamic place) async {
    final lat = double.parse(place['lat'].toString());
    final lng = double.parse(place['lon'].toString());
    final name =
        place['display_name']?.toString().split(',').first ?? 'Unknown';

    _searchController.text = name;
    _searchFocus.unfocus();
    setState(() {
      _showGeoResults = false;
      _geocodeResults = [];
      _searchLat = lat;
      _searchLng = lng;
      _searchAreaLabel = name;
      _isLoadingHostels = true;
    });

    // Fetch all hostels in this area
    final provider = Provider.of<HostelProvider>(context, listen: false);
    await provider.fetchHostelsForArea(lat, lng, radiusKm: 10);
    _buildHostelListFrom(provider, lat: lat, lng: lng);
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocus.unfocus();
    setState(() {
      _geocodeResults = [];
      _showGeoResults = false;
      _searchLat = null;
      _searchLng = null;
      _searchAreaLabel = '';
    });
    _fetchHostels(); // Reset to current location results
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredHostels = _allHostels.where((h) {
        // If we have a geocoded area selected, skip text filtering (area already applied)
        bool matchesSearch = true;
        if (_searchLat == null) {
          final name = (h['name'] ?? '').toString().toLowerCase();
          final city = (h['city'] ?? '').toString().toLowerCase();
          final address = (h['address'] ?? '').toString().toLowerCase();
          matchesSearch = query.isEmpty ||
              name.contains(query) ||
              city.contains(query) ||
              address.contains(query);
        }

        final type = (h['type'] ?? '').toString().toLowerCase();
        bool matchesType = true;
        if (_selectedType == 'Men & Boys') {
          matchesType = type == 'boys' || type == 'men' || type == 'mens';
        } else if (_selectedType == 'Girls & Women') {
          matchesType =
              type == 'girls' || type == 'women' || type == 'womens';
        } else if (_selectedType != 'Any Share') {
          matchesType = type == _selectedType.toLowerCase();
        }

        bool matchesDistance = true;
        // Enforce 10km filter only on OSM hostels. Database hostels bypass this.
        final source = h['source']?.toString() ?? '';
        final isOsm = source == 'osm' || (h['_id']?.toString().startsWith('osm_') == true);
        if (isOsm) {
          final dist = h['distance'] as double?;
          if (dist != null && dist > 10.0) {
            matchesDistance = false;
          }
        }

        return matchesSearch && matchesType && matchesDistance;
      }).toList();
    });
  }

  String _distanceLabel(dynamic hostel) {
    final d = hostel['distance'];
    if (d == null || d == 9999.0) return '';
    if ((d as double) < 1.0) return '${(d * 1000).toStringAsFixed(0)} m away';
    return '${d.toStringAsFixed(1)} km away';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                _buildFilters(),
                // Area badge
                if (_searchAreaLabel.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFACC15).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFFFACC15).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_city,
                            color: Color(0xFFFACC15), size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Showing hostels in: $_searchAreaLabel',
                            style: const TextStyle(
                                color: Color(0xFFFACC15), fontSize: 12),
                          ),
                        ),
                        GestureDetector(
                          onTap: _clearSearch,
                          child: const Icon(Icons.close,
                              color: Colors.grey, size: 16),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        _searchAreaLabel.isNotEmpty
                            ? 'HOSTELS IN AREA (${_filteredHostels.length})'
                            : 'NEARBY HOSTELS (${_filteredHostels.length})',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5),
                      ),
                      const Spacer(),
                      if (_isLoadingHostels || _isGeocoding)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFFFACC15)),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoadingHostels && _filteredHostels.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                  color: Color(0xFFFACC15)),
                              SizedBox(height: 16),
                              Text('Fetching real-time hostels...',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        )
                      : _filteredHostels.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              onRefresh: _fetchHostels,
                              color: const Color(0xFFFACC15),
                              backgroundColor: const Color(0xFF1E293B),
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 80),
                                itemCount: _filteredHostels.length,
                                itemBuilder: (_, i) =>
                                    _buildHostelCard(
                                        _filteredHostels[i], i + 1),
                              ),
                            ),
                ),
              ],
            ),
            // Geocode results dropdown
            if (_showGeoResults)
              Positioned(
                top: 130,
                left: 16,
                right: 16,
                child: _buildGeoDropdown(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeoDropdown() {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 260),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0xFFFACC15).withOpacity(0.3)),
          boxShadow: const [
            BoxShadow(
                color: Colors.black45,
                blurRadius: 16,
                offset: Offset(0, 6))
          ],
        ),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: _geocodeResults.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.white.withOpacity(0.05)),
          itemBuilder: (_, i) {
            final place = _geocodeResults[i];
            final name = place['display_name']?.toString() ?? '';
            final parts = name.split(',');
            return ListTile(
              dense: true,
              leading:
                  const Icon(Icons.place, color: Color(0xFFFACC15), size: 20),
              title: Text(
                parts.first.trim(),
                style:
                    const TextStyle(color: Colors.white, fontSize: 13),
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
              onTap: () => _selectArea(place),
            );
          },
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFACC15).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.hotel,
                    color: Color(0xFFFACC15), size: 22),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find Hostels',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  if (_currentPosition != null && _searchAreaLabel.isEmpty)
                    const Text(
                      'Real-time • From your location',
                      style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 11),
                    ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.my_location,
                    color: Color(0xFFFACC15)),
                tooltip: 'Back to my location',
                onPressed: () {
                  _clearSearch();
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white54),
                onPressed: _fetchHostels,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.search,
                      color: Color(0xFFFACC15), size: 20),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search city, area or hostel name...',
                      hintStyle:
                          TextStyle(color: Colors.grey, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 14),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty && _geocodeResults.isNotEmpty) {
                        _selectArea(_geocodeResults.first);
                      }
                    },
                  ),
                ),
                if (_isGeocoding)
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
                    icon: const Icon(Icons.close,
                        color: Colors.grey, size: 20),
                    onPressed: _clearSearch,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t = _types[i];
          final isSelected = t == _selectedType;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedType = t);
              _applyFilters();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFACC15)
                    : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFACC15)
                      : Colors.white12,
                ),
              ),
              child: Text(
                t.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, color: Colors.grey, size: 56),
          const SizedBox(height: 12),
          const Text('No hostels found in this area.',
              style: TextStyle(color: Colors.grey, fontSize: 15)),
          const SizedBox(height: 8),
          const Text('Try a different area or expand the search.',
              style: TextStyle(color: Colors.white30, fontSize: 12)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFACC15),
                  foregroundColor: Colors.black,
                ),
                onPressed: _fetchHostels,
              ),
              const SizedBox(width: 12),
              if (_searchAreaLabel.isNotEmpty)
                OutlinedButton.icon(
                  icon: const Icon(Icons.my_location, size: 16),
                  label: const Text('Use My Location'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFACC15),
                    side: const BorderSide(color: Color(0xFFFACC15)),
                  ),
                  onPressed: _clearSearch,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHostelCard(dynamic hostel, int rank) {
    final name = hostel['name']?.toString() ?? 'Unknown';
    final address = hostel['address']?.toString() ?? '';
    final city = hostel['city']?.toString() ?? '';
    final locationStr =
        [address, city].where((s) => s.isNotEmpty).join(', ');
    final rent = hostel['rentPerMonth'];
    final ratings = (hostel['ratings'] ?? 0).toDouble();
    final facilities = List<String>.from(hostel['facilities'] ?? []);
    final type = hostel['type']?.toString() ?? '';
    final distLabel = _distanceLabel(hostel);
    final isOsm = (hostel['source'] ?? '') == 'osm';
    final phone = hostel['phone']?.toString() ?? '';

    Color rankColor;
    if (rank == 1) rankColor = const Color(0xFF10B981);
    else if (rank == 2) rankColor = Colors.blueAccent;
    else rankColor = Colors.white54;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isOsm
                ? Colors.blueAccent.withOpacity(0.2)
                : Colors.white.withOpacity(0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFACC15).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isOsm ? Icons.place : Icons.home,
                    color: isOsm ? Colors.blueAccent : const Color(0xFFFACC15),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: rankColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: rankColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              '#$rank NEARBY',
                              style: TextStyle(
                                  color: rankColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (isOsm)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'REAL-TIME',
                                style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 3),
                        Text(
                          ratings.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ],
                    ),
                    if (type.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _typeColor(type).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          type.toUpperCase(),
                          style: TextStyle(
                              color: _typeColor(type),
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (locationStr.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.location_on,
                      color: Colors.redAccent, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      locationStr,
                      style: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.blueAccent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

            if (distLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.directions_walk,
                      color: Color(0xFFFACC15), size: 14),
                  const SizedBox(width: 4),
                  Text(distLabel,
                      style: const TextStyle(
                          color: Color(0xFFFACC15), fontSize: 12)),
                ],
              ),
            ],

            if (phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.green, size: 14),
                  const SizedBox(width: 4),
                  Text(phone,
                      style: const TextStyle(
                          color: Colors.green, fontSize: 12)),
                ],
              ),
            ],

            const SizedBox(height: 8),

            if (rent != null && rent != 0)
              Text(
                'From ₹$rent/mo',
                style: const TextStyle(
                    color: Color(0xFFFACC15),
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              )
            else if (isOsm)
              const Text(
                'Price on enquiry',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),

            const SizedBox(height: 10),

            if (facilities.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: facilities.take(5).map((f) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(f.toLowerCase(),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                  );
                }).toList(),
              ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.info_outline, size: 14),
                    label: const Text('Details',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
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
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_month, size: 14),
                    label: const Text('Book Visit',
                        style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOsm
                          ? Colors.blueAccent
                          : const Color(0xFFFACC15),
                      foregroundColor:
                          isOsm ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () {
                      // Only allow booking for backend hostels
                      if (!isOsm) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookingScreen(hostel: hostel),
                          ),
                        );
                      } else {
                        // For OSM hostels, show info dialog
                        _showOsmBookingInfo(hostel);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOsmBookingInfo(dynamic hostel) {
    final phone = hostel['phone']?.toString() ?? '';
    final email = hostel['email']?.toString() ?? '';
    final website = hostel['website']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          hostel['name']?.toString() ?? 'Hostel',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blueAccent, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is a real-time hostel found via OpenStreetMap. Contact them directly to book.',
                      style:
                          TextStyle(color: Colors.blueAccent, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 12),
              _contactRow(Icons.phone, 'Call', phone),
            ],
            if (email.isNotEmpty) ...[
              const SizedBox(height: 8),
              _contactRow(Icons.email, 'Email', email),
            ],
            if (website.isNotEmpty) ...[
              const SizedBox(height: 8),
              _contactRow(Icons.language, 'Website', website),
            ],
            if (phone.isEmpty && email.isEmpty && website.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'No contact info available. Visit the hostel directly.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
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
  }

  Widget _contactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFACC15), size: 16),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'boys': return Colors.blueAccent;
      case 'girls': return Colors.pinkAccent;
      case 'coed': return const Color(0xFFFACC15);
      default: return Colors.white70;
    }
  }
}
