import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HostelProvider with ChangeNotifier {
  List<dynamic> _hostels = [];
  bool _isLoading = false;

  List<dynamic> get hostels => _hostels;
  bool get isLoading => _isLoading;

  // -----------------------------------------------------------------------
  // IMPORTANT: Set this to your computer's local IP address when testing
  // on a real phone (e.g., 'http://192.168.1.5:5000').
  // Use 'http://10.0.2.2:5000' ONLY for Android emulator.
  // Use 'http://localhost:5000' only for iOS simulator.
  // For production, use your actual deployed server URL.
  // -----------------------------------------------------------------------
  static const String _baseUrl = 'http://10.223.111.90:5000';

  Future<void> fetchHostels() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/hostels'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        _hostels = json.decode(response.body);
      } else {
        // Fallback to sample data if server returns an error
        _hostels = _getSampleHostels();
      }
    } catch (error) {
      // Fallback to sample data if server isn't reachable
      // (expected on real phone when backend is not deployed)
      _hostels = _getSampleHostels();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<dynamic> _getSampleHostels() {
    return [
      {
        "_id": "1",
        "name": "Sunrise Boys Hostel",
        "rentPerMonth": 5000,
        "address": "123 University St, Tech City",
        "ratings": 4.5,
        "numReviews": 120,
        "availableRooms": 20,
        "description": "Modern boys hostel with all basic amenities including fast WiFi.",
        "facilities": ["WiFi", "Food", "Laundry", "Gym"],
        "images": ["https://images.unsplash.com/photo-1555854877-bab0e564b8d5"],
        "location": {"lat": 12.9715987, "lng": 77.5945627}
      },
      {
        "_id": "2",
        "name": "Harmony Girls PG",
        "rentPerMonth": 6500,
        "address": "456 Rose Garden, Tech City",
        "ratings": 4.8,
        "numReviews": 85,
        "availableRooms": 5,
        "description": "Safe and secure living space for girls. Near to primary tech parks.",
        "facilities": ["AC", "WiFi", "Food", "Security"],
        "images": ["https://images.unsplash.com/photo-1522771731478-4ea767a14a24"],
        "location": {"lat": 12.9352733, "lng": 77.6244546}
      }
    ];
  }
}
