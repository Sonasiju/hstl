import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../core/api_config.dart';
import '../services/location_service.dart';
import '../services/hostel_service.dart';

class HostelProvider with ChangeNotifier {
  List<Map<String, dynamic>> _hostels = [];
  List<Map<String, dynamic>> _osmHostels = [];

  bool _isLoading = false;
  String? _lastError;

  final LocationService _locationService = LocationService();
  final HostelService _hostelService = HostelService();

  List<Map<String, dynamic>> get hostels => _hostels;
  List<Map<String, dynamic>> get osmHostels => _osmHostels;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  String get _baseUrl => ApiConfig.getConfiguredUrl();

  /// FETCH HOSTELS FROM BACKEND (all or near a location)
  Future<void> fetchHostels({double? lat, double? lng, int radiusKm = 10}) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      String url = '$_baseUrl/api/hostels';
      if (lat != null && lng != null) {
        url += '?lat=$lat&lng=$lng&maxDistance=$radiusKm&limit=50';
      } else {
        url += '?limit=50';
      }

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _hostels = List<Map<String, dynamic>>.from(data);
        debugPrint('Backend hostels fetched: ${_hostels.length}');
      } else {
        debugPrint('Backend hostels error: ${response.statusCode}');
        if (_hostels.isEmpty) _hostels = _getSampleHostels();
      }
    } catch (e) {
      debugPrint('Error fetching hostels: $e');
      _lastError = e.toString();
      if (_hostels.isEmpty) _hostels = _getSampleHostels();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// SEARCH BACKEND HOSTELS BY TEXT (city name, hostel name, etc.)
  Future<void> fetchHostelsByText(String searchText) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final url = '$_baseUrl/api/hostels?search=${Uri.encodeComponent(searchText)}&limit=50';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _hostels = List<Map<String, dynamic>>.from(data);
        debugPrint('Text search hostels fetched: ${_hostels.length}');
      } else {
        debugPrint('Text search error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in text search: $e');
      _lastError = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// FETCH REAL HOSTELS FROM OPENSTREETMAP around a given location
  Future<void> findNearbyOSMHostels(double lat, double lng, {int radiusMeters = 5000}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _hostelService.fetchNearbyOSMHostels(
        lat, lng, radiusMeters: radiusMeters,
      );
      _osmHostels = List<Map<String, dynamic>>.from(result);
      debugPrint('OSM hostels set: ${_osmHostels.length}');
    } catch (e) {
      debugPrint('Error fetching OSM hostels: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// FETCH BOTH backend & OSM hostels for an area simultaneously
  Future<void> fetchHostelsForArea(double lat, double lng, {int radiusKm = 10}) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // Run both in parallel
      await Future.wait([
        fetchHostels(lat: lat, lng: lng, radiusKm: radiusKm)
            .catchError((e) => debugPrint('Backend area fetch error: $e')),
        findNearbyOSMHostels(lat, lng, radiusMeters: radiusKm * 1000)
            .catchError((e) => debugPrint('OSM area fetch error: $e')),
      ]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ADMIN CREATE HOSTEL
  Future<bool> createHostel(Map<String, dynamic> hostelData, String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/hostels'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(hostelData),
      );

      if (response.statusCode == 201) {
        await fetchHostels();
        return true;
      } else {
        debugPrint('Create hostel failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error creating hostel: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// GET NEARBY HOSTELS sorted by distance - combines backend + OSM
  /// Returns all unique hostels with distance calculated
  List<Map<String, dynamic>> getNearbyHostels(double userLat, double userLng) {
    final combined = <Map<String, dynamic>>[];
    final seen = <String>{};

    // Add backend hostels first (bookable)
    for (final h in _hostels) {
      final id = h['_id']?.toString() ?? '';
      if (id.isNotEmpty && !seen.contains(id)) {
        seen.add(id);
        if (h['location'] != null) {
          final lat = (h['location']['lat'] as num).toDouble();
          final lng = (h['location']['lng'] as num).toDouble();
          final dist = _locationService.calculateDistance(userLat, userLng, lat, lng);
          combined.add({...h, 'distance': dist});
        } else {
          combined.add({...h, 'distance': 9999.0});
        }
      }
    }

    // Add OSM hostels
    for (final h in _osmHostels) {
      final id = h['_id']?.toString() ?? '';
      if (id.isNotEmpty && !seen.contains(id)) {
        seen.add(id);
        if (h['location'] != null) {
          final lat = (h['location']['lat'] as num).toDouble();
          final lng = (h['location']['lng'] as num).toDouble();
          final dist = _locationService.calculateDistance(userLat, userLng, lat, lng);
          combined.add({...h, 'distance': dist});
        }
      }
    }

    combined.sort((a, b) =>
        (a['distance'] as double).compareTo(b['distance'] as double));
    return combined;
  }

  /// Get only backend hostels (bookable) sorted by distance
  List<Map<String, dynamic>> getBookableNearbyHostels(double userLat, double userLng) {
    final sorted = _hostels.where((h) => h['location'] != null).map((h) {
      final lat = (h['location']['lat'] as num).toDouble();
      final lng = (h['location']['lng'] as num).toDouble();
      final dist = _locationService.calculateDistance(userLat, userLng, lat, lng);
      return {...h, 'distance': dist};
    }).toList();
    sorted.sort((a, b) =>
        (a['distance'] as double).compareTo(b['distance'] as double));
    return sorted;
  }

  /// GET PROVIDED HOSTELS FOR NEARBY DISPLAY (includes OSM for reference)
  List<Map<String, dynamic>> getProvidedHostels(double userLat, double userLng) {
    return getNearbyHostels(userLat, userLng);
  }

  /// SAMPLE HOSTELS (FALLBACK)
  List<Map<String, dynamic>> _getSampleHostels() {
    return [
      {
        "_id": "1",
        "name": "Sunrise Boys Hostel",
        "rentPerMonth": 5000,
        "address": "123 University St, Tech City",
        "city": "Tech City",
        "ratings": 4.5,
        "numReviews": 120,
        "availableRooms": 20,
        "description": "Modern boys hostel with WiFi, food and laundry services.",
        "facilities": ["WiFi", "Food", "Laundry", "Gym"],
        "images": ["https://images.unsplash.com/photo-1555854877-bab0e564b8d5"],
        "location": {"lat": 12.9715987, "lng": 77.5945627},
        "type": "boys",
      },
      {
        "_id": "2",
        "name": "Harmony Girls PG",
        "rentPerMonth": 6500,
        "address": "456 Rose Garden, Tech City",
        "city": "Tech City",
        "ratings": 4.8,
        "numReviews": 85,
        "availableRooms": 5,
        "description": "Safe and secure living space for girls near tech parks.",
        "facilities": ["AC", "WiFi", "Food", "Security"],
        "images": ["https://images.unsplash.com/photo-1522771731478-4ea767a14a24"],
        "location": {"lat": 12.9352733, "lng": 77.6244546},
        "type": "girls",
      }
    ];
  }
}