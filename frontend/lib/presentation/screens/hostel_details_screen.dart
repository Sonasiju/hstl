import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../core/api_config.dart';
import '../../data/providers/auth_provider.dart';
import 'booking_screen.dart';
import 'routing_map_screen.dart';

class HostelDetailsScreen extends StatefulWidget {
  final dynamic hostel;

  const HostelDetailsScreen({Key? key, required this.hostel})
      : super(key: key);

  @override
  State<HostelDetailsScreen> createState() => _HostelDetailsScreenState();
}

class _HostelDetailsScreenState extends State<HostelDetailsScreen> {
  int _currentImageIndex = 0;
  bool _isBooking = false;

  // ──────────────────────────── HELPERS ────────────────────────────

  String _safeString(dynamic val, [String fallback = '-']) {
    if (val == null) return fallback;
    final s = val.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  String _safePrice(dynamic val) {
    if (val == null) return '-';
    try {
      final num v = num.parse(val.toString());
      return '₹${v.toStringAsFixed(0)}';
    } catch (_) {
      return '₹${val.toString()}';
    }
  }

  /// Check if ID is a valid MongoDB ObjectId (24 hex characters)
  bool _isValidMongoObjectId(String id) {
    // MongoDB ObjectIds are 24 hexadecimal characters
    final mongoIdRegex = RegExp(r'^[a-f0-9]{24}$', caseSensitive: false);
    return mongoIdRegex.hasMatch(id);
  }

  // ──────────────────────────── BOOKING ────────────────────────────

  Future<void> _handleBooking() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      _showSnack('Please log in to book a hostel.', isError: true);
      return;
    }

    final hostelId = widget.hostel['_id']?.toString();
    if (hostelId == null) {
      _showSnack('Cannot book: hostel ID is missing.', isError: true);
      return;
    }

    // Check if this is an OSM hostel (fake ID starting with "osm_")
    if (hostelId.startsWith('osm_')) {
      _showSnack(
        'This location is from OpenStreetMap and cannot be booked through the app. '
        'Please contact the hostel directly.',
        isError: true
      );
      return;
    }

    // Check if this is a sample hostel (simple numeric ID - not a real MongoDB ObjectId)
    // Real MongoDB ObjectIds are 24 hex characters
    if (!_isValidMongoObjectId(hostelId)) {
      _showSnack(
        'This is a demonstration hostel. Please refresh the app to load real hostels from the database.',
        isError: true
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingScreen(hostel: widget.hostel),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ──────────────────────────── BUILD ────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hostel = widget.hostel;
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final isOsm = (hostel['source'] ?? '').toString() == 'osm' || 
                  (hostel['_id'] ?? '').toString().startsWith('osm_');
    final isAdmin = auth.userRole == 'admin';

    final List<String> images = (hostel['images'] != null &&
            (hostel['images'] as List).isNotEmpty)
        ? List<String>.from(hostel['images'])
        : ['https://images.unsplash.com/photo-1555854877-bab0e564b8d5'];

    final String phone = _safeString(hostel['phone']);
    final String email = _safeString(hostel['email']);
    final String website = _safeString(hostel['website']);
    final String type = _safeString(hostel['type']);
    final String city = _safeString(hostel['city']);
    final String address = _safeString(hostel['address']);
    final String description =
        _safeString(hostel['description'], 'No description available.');
    final List<dynamic> facilities =
        (hostel['facilities'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.share, color: Colors.white, size: 20),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share link copied!')),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── EXPANDED SCROLLABLE BODY ──
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── IMAGE CAROUSEL ──
                  Stack(
                    children: [
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 320.0,
                          viewportFraction: 1.0,
                          enableInfiniteScroll: images.length > 1,
                          autoPlay: images.length > 1,
                          autoPlayInterval: const Duration(seconds: 4),
                          onPageChanged: (index, _) =>
                              setState(() => _currentImageIndex = index),
                        ),
                        items: images.map((img) {
                          return CachedNetworkImage(
                            imageUrl: img,
                            fit: BoxFit.cover,
                            width: MediaQuery.of(context).size.width,
                            placeholder: (_, __) => Container(
                              color: const Color(0xFF1E293B),
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFFFACC15)),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: const Color(0xFF1E293B),
                              child: const Icon(Icons.image_not_supported,
                                  color: Colors.grey, size: 60),
                            ),
                          );
                        }).toList(),
                      ),
                      // Image dots
                      if (images.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: images.asMap().entries.map((e) {
                              return Container(
                                width: _currentImageIndex == e.key ? 16 : 6,
                                height: 6,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == e.key
                                      ? const Color(0xFFFACC15)
                                      : Colors.white38,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),

                  if (isOsm)
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Unregistered Hostel',
                                    style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                SizedBox(height: 2),
                                Text(
                                  'This hostel is not registered on the platform. Please contact them directly to enquire or visit.',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── NAME + TYPE BADGE ──
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _safeString(hostel['name'], 'Unknown Hostel'),
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (type != '-')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _typeColor(type).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: _typeColor(type), width: 1),
                                ),
                                child: Text(
                                  type.toUpperCase(),
                                  style: TextStyle(
                                      color: _typeColor(type),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // ── ADDRESS ──
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Colors.grey, size: 15),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                address != '-' ? '$address${city != '-' ? ', $city' : ''}' : city,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── STATS ROW ──
                        Row(
                          children: [
                             _buildStatCard(
                               isOsm ? 'Contact for' : _safePrice(hostel['rentPerMonth']),
                               isOsm ? 'pricing' : 'per month',
                               Icons.currency_rupee,
                               const Color(0xFFFACC15),
                             ),
                             const SizedBox(width: 10),
                             _buildStatCard(
                               isOsm ? 'Verified' : (_safeString(hostel['availableRooms'], '0') + ' rooms'),
                               isOsm ? 'on Map' : 'available',
                               isOsm ? Icons.verified : Icons.meeting_room,
                               const Color(0xFF10B981),
                             ),
                             const SizedBox(width: 10),
                             _buildStatCard(
                               isOsm ? '4.0' : '${hostel['ratings'] ?? 0}★',
                               isOsm ? 'OSM Score' : '${hostel['numReviews'] ?? 0} reviews',
                               Icons.star,
                               Colors.amber,
                             ),
                           ],
                         ),

                        const SizedBox(height: 24),

                        // ── CONTACT DETAILS ──
                        _buildSectionTitle('Contact Details'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              if (phone != '-')
                                _buildContactTile(
                                  icon: Icons.phone,
                                  title: 'Phone',
                                  value: phone,
                                  color: Colors.green,
                                  onTap: () => _showContactDialog(
                                      Icons.phone, 'Phone', phone),
                                ),
                              if (phone != '-' && email != '-')
                                Divider(
                                    height: 1,
                                    color: Colors.white.withOpacity(0.05)),
                              if (email != '-')
                                _buildContactTile(
                                  icon: Icons.email,
                                  title: 'Email',
                                  value: email,
                                  color: Colors.blueAccent,
                                  onTap: () => _showContactDialog(
                                      Icons.email, 'Email', email),
                                ),
                              if ((phone != '-' || email != '-') &&
                                  website != '-')
                                Divider(
                                    height: 1,
                                    color: Colors.white.withOpacity(0.05)),
                              if (website != '-')
                                _buildContactTile(
                                  icon: Icons.language,
                                  title: 'Website',
                                  value: website,
                                  color: Colors.purpleAccent,
                                  onTap: () => _showContactDialog(
                                      Icons.language, 'Website', website),
                                ),
                              if (phone == '-' &&
                                  email == '-' &&
                                  website == '-')
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'No contact details provided.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── ABOUT ──
                        _buildSectionTitle('About'),
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 14, height: 1.7),
                        ),

                        const SizedBox(height: 24),

                        // ── FACILITIES ──
                        if (facilities.isNotEmpty) ...[
                          _buildSectionTitle('Facilities'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: facilities.map((f) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFFFACC15)
                                          .withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_facilityIcon(f.toString()),
                                        color: const Color(0xFFFACC15),
                                        size: 14),
                                    const SizedBox(width: 6),
                                    Text(f.toString(),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── BOTTOM BOOK BAR ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black38,
                    blurRadius: 12,
                    offset: Offset(0, -4))
              ],
            ),
            child: Row(
              children: [
                // Price info or Direct Contact text
                if (!isOsm)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _safePrice(hostel['rentPerMonth']),
                        style: const TextStyle(
                          color: Color(0xFFFACC15),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('per month',
                          style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  )
                else
                  const Expanded(
                    child: Text(
                      'Direct Contact Only',
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (!isOsm) const SizedBox(width: 20),
                
                // Action buttons
                if (!isOsm)
                  // For registered hostels: Book Now button
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Admin accounts cannot book hostels.',
                                    style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Get Directions button
                        ElevatedButton.icon(
                          onPressed: () {
                            final double lat = (hostel['location']?['lat'] as num?)?.toDouble() ?? 0.0;
                            final double lng = (hostel['location']?['lng'] as num?)?.toDouble() ?? 0.0;
                            
                            if (lat == 0.0 && lng == 0.0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Hostel location not available'),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RoutingMapScreen(
                                  hostelLocation: LatLng(lat, lng),
                                  hostelName: hostel['name'],
                                  hostelAddress: hostel['address'],
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: const Color(0xFFFACC15),
                            side: const BorderSide(color: Color(0xFFFACC15), width: 1),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.directions, size: 18),
                          label: const Text(
                            'Get Directions',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Book Now button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAdmin ? Colors.grey : const Color(0xFFFACC15),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: (isAdmin || _isBooking) ? null : _handleBooking,
                          child: _isBooking
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.black),
                                )
                              : Text(isAdmin ? 'Booking Disabled for Admins' : 'Book Now',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  )
                else
                  // For OSM hostels: Open in Maps button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final double lat = (hostel['location']?['lat'] as num?)?.toDouble() ?? 0.0;
                        final double lng = (hostel['location']?['lng'] as num?)?.toDouble() ?? 0.0;
                        
                        if (lat == 0.0 && lng == 0.0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Hostel location not available'),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoutingMapScreen(
                              hostelLocation: LatLng(lat, lng),
                              hostelName: hostel['name'],
                              hostelAddress: hostel['address'],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.map, size: 20),
                      label: const Text(
                        'Open in Maps',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────── WIDGETS ────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
                textAlign: TextAlign.center),
            Text(label,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(color: Colors.grey, fontSize: 11)),
      subtitle: Text(
        value,
        style: const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(Icons.chevron_right, color: color.withOpacity(0.6)),
      onTap: onTap,
    );
  }

  void _showContactDialog(IconData icon, String type, String value) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: const Color(0xFFFACC15)),
            const SizedBox(width: 10),
            Text(type,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SelectableText(
          value,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
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

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'boys':
        return Colors.blueAccent;
      case 'girls':
        return Colors.pinkAccent;
      case 'coed':
        return const Color(0xFFFACC15);
      default:
        return Colors.white70;
    }
  }

  IconData _facilityIcon(String facility) {
    final f = facility.toLowerCase();
    if (f.contains('wifi') || f.contains('internet')) return Icons.wifi;
    if (f.contains('food') || f.contains('meal')) return Icons.restaurant;
    if (f.contains('ac') || f.contains('air')) return Icons.ac_unit;
    if (f.contains('gym') || f.contains('fitness')) return Icons.fitness_center;
    if (f.contains('laundry') || f.contains('wash')) return Icons.local_laundry_service;
    if (f.contains('cctv') || f.contains('security') || f.contains('guard'))
      return Icons.security;
    if (f.contains('park')) return Icons.local_parking;
    if (f.contains('power') || f.contains('backup')) return Icons.power;
    if (f.contains('library') || f.contains('study')) return Icons.menu_book;
    if (f.contains('water')) return Icons.water_drop;
    return Icons.check_circle_outline;
  }
}
