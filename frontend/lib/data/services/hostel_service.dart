import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HostelService {
  /// Fetch real hostels from OpenStreetMap using the Overpass API
  /// Searches for tourism=hostel, tourism=guest_house, amenity=dormitory
  /// within a configurable radius (default 5km)
  Future<List<dynamic>> fetchNearbyOSMHostels(
    double lat,
    double lng, {
    int radiusMeters = 5000,
  }) async {
    const String overpassUrl = "https://overpass-api.de/api/interpreter";

    // More comprehensive query: hostels, guest houses, dormitories, PGs
    final String query = """
      [out:json][timeout:20];
      (
        node["tourism"="hostel"](around:$radiusMeters, $lat, $lng);
        node["tourism"="guest_house"](around:$radiusMeters, $lat, $lng);
        node["amenity"="dormitory"](around:$radiusMeters, $lat, $lng);
        node["building"="dormitory"](around:$radiusMeters, $lat, $lng);
        way["tourism"="hostel"](around:$radiusMeters, $lat, $lng);
        way["tourism"="guest_house"](around:$radiusMeters, $lat, $lng);
      );
      out center body;
    """;

    try {
      final response = await http
          .post(
            Uri.parse(overpassUrl),
            body: query,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> osmNodes = data['elements'] ?? [];

        // De-duplicate by name + approximate location
        final seen = <String>{};
        final List<dynamic> result = [];

        for (final node in osmNodes) {
          // For ways, use center coordinates
          double? nodeLat, nodeLng;
          if (node['type'] == 'way' && node['center'] != null) {
            nodeLat = (node['center']['lat'] as num).toDouble();
            nodeLng = (node['center']['lon'] as num).toDouble();
          } else if (node['lat'] != null) {
            nodeLat = (node['lat'] as num).toDouble();
            nodeLng = (node['lon'] as num).toDouble();
          }

          if (nodeLat == null || nodeLng == null) continue;

          final tags = node['tags'] ?? {};
          final name = (tags['name'] ?? tags['brand'] ?? 'Hostel/PG').toString();

          // Deduplicate by name + rounded coords
          final key =
              '${name}_${nodeLat.toStringAsFixed(3)}_${nodeLng.toStringAsFixed(3)}';
          if (seen.contains(key)) continue;
          seen.add(key);

          // Build address
          String address = '';
          if (tags['addr:full'] != null) {
            address = tags['addr:full'].toString();
          } else {
            final parts = <String>[];
            if (tags['addr:housenumber'] != null)
              parts.add(tags['addr:housenumber'].toString());
            if (tags['addr:street'] != null)
              parts.add(tags['addr:street'].toString());
            if (tags['addr:city'] != null)
              parts.add(tags['addr:city'].toString());
            address =
                parts.isNotEmpty ? parts.join(', ') : 'OpenStreetMap Location';
          }

          // Try to extract rent/price info
          num? rent;
          if (tags['price'] != null) {
            try {
              rent = num.parse(
                  tags['price'].toString().replaceAll(RegExp(r'[^0-9.]'), ''));
            } catch (_) {}
          }

          final category = tags['tourism'] ?? tags['amenity'] ?? 'hostel';

          result.add({
            "_id": "osm_${node['id']}",
            "name": name,
            "address": address,
            "city": tags['addr:city'] ?? tags['addr:state'] ?? '',
            "phone": tags['phone'] ?? tags['contact:phone'] ?? '',
            "email": tags['email'] ?? tags['contact:email'] ?? '',
            "website": tags['website'] ?? tags['contact:website'] ?? '',
            "rentPerMonth": rent ?? 0,
            "ratings": 4.0,
            "numReviews": 0,
            "availableRooms": 1,
            "description":
                tags['description'] ?? 'Real hostel/PG from OpenStreetMap.',
            "facilities": _parseFacilities(tags),
            "images": [
              "https://images.unsplash.com/photo-1555854877-bab0e564b8d5"
            ],
            "location": {"lat": nodeLat, "lng": nodeLng},
            "source": "osm",
            "category": category,
            "openingHours": tags['opening_hours'] ?? '',
            "type": _inferType(tags),
          });
        }

        debugPrint('OSM hostels found: ${result.length} within ${radiusMeters}m of ($lat,$lng)');
        return result;
      } else {
        debugPrint("Overpass API Error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error fetching OSM hostels: $e");
      return [];
    }
  }

  List<String> _parseFacilities(Map<String, dynamic> tags) {
    final List<String> facilities = [];
    if (tags['internet_access'] != null && tags['internet_access'] != 'no') {
      facilities.add('WiFi');
    }
    if (tags['shower'] != null && tags['shower'] != 'no') {
      facilities.add('Hot Water');
    }
    if (tags['kitchen'] != null && tags['kitchen'] != 'no') {
      facilities.add('Kitchen');
    }
    if (tags['parking'] != null && tags['parking'] != 'no') {
      facilities.add('Parking');
    }
    if (tags['laundry'] != null && tags['laundry'] != 'no') {
      facilities.add('Laundry');
    }
    if (tags['air_conditioning'] != null &&
        tags['air_conditioning'] != 'no') {
      facilities.add('AC');
    }
    if (facilities.isEmpty) facilities.add('Basic Amenities');
    return facilities;
  }

  String _inferType(Map<String, dynamic> tags) {
    final name = (tags['name'] ?? '').toString().toLowerCase();
    if (name.contains('girl') || name.contains('women') || name.contains('ladies')) {
      return 'girls';
    }
    if (name.contains('boy') || name.contains('men') || name.contains('male') ||
        name.contains('gents')) {
      return 'boys';
    }
    return 'coed';
  }
}
