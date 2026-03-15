// Example: How to integrate route planning into Hostel Details Screen

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'route_display_screen.dart';
import '../widgets/directions_button.dart';

class HostelDetailsWithDirectionsExample extends StatelessWidget {
  final Map<String, dynamic> hostel;

  const HostelDetailsWithDirectionsExample({
    Key? key,
    required this.hostel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract hostel coordinates
    final lat = hostel['location']?['lat'] ?? 0.0;
    final lng = hostel['location']?['lng'] ?? 0.0;
    final hostelLocation = LatLng(lat, lng);

    return Scaffold(
      appBar: AppBar(
        title: Text(hostel['name'] ?? 'Hostel Details'),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ... Existing hostel info widgets ...
            
            // Add Get Directions button
            Padding(
              padding: const EdgeInsets.all(16),
              child: GetDirectionsButton(
                hostelLocation: hostelLocation,
                hostelName: hostel['name'] ?? 'Hostel',
                hostelAddress: hostel['address'],
              ),
            ),
            
            const Divider(),
            
            // Quick access chips
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  DirectionsChip(
                    hostelLocation: hostelLocation,
                    hostelName: hostel['name'] ?? 'Hostel',
                    hostelAddress: hostel['address'],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Call hostel
                      print('Calling: ${hostel['phone']}');
                    },
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Share hostel
                      print('Sharing: ${hostel['name']}');
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Example: Hostel Card with Directions
class HostelCardWithDirections extends StatelessWidget {
  final Map<String, dynamic> hostel;
  final VoidCallback? onTap;

  const HostelCardWithDirections({
    Key? key,
    required this.hostel,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lat = hostel['location']?['lat'] ?? 0.0;
    final lng = hostel['location']?['lng'] ?? 0.0;
    final hostelLocation = LatLng(lat, lng);

    return Card(
      color: const Color(0xFF1E293B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hostel image
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[800],
            ),
            // Add image here
          ),
          
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hostel['name'] ?? 'Unknown Hostel',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hostel['address'] ?? 'No address',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFFACC15).withOpacity(0.2),
                        ),
                        child: const Text(
                          'Details',
                          style: TextStyle(
                            color: Color(0xFFFACC15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RouteDisplayScreen(
                                hostelLocation: hostelLocation,
                                hostelName: hostel['name'] ?? 'Hostel',
                                hostelAddress: hostel['address'],
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.directions, size: 16),
                        label: const Text('Route'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFACC15),
                          foregroundColor: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Example: Quick action in hostel list
class HostelListItemWithDirections extends StatelessWidget {
  final Map<String, dynamic> hostel;
  final VoidCallback? onViewDetails;

  const HostelListItemWithDirections({
    Key? key,
    required this.hostel,
    this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lat = hostel['location']?['lat'] ?? 0.0;
    final lng = hostel['location']?['lng'] ?? 0.0;
    final hostelLocation = LatLng(lat, lng);

    return ListTile(
      title: Text(hostel['name'] ?? 'Unknown'),
      subtitle: Text(hostel['address'] ?? 'No address'),
      trailing: PopupMenuButton(
        itemBuilder: (BuildContext context) => [
          PopupMenuItem(
            child: const Text('View Details'),
            onTap: onViewDetails,
          ),
          PopupMenuItem(
            child: const Row(
              children: [
                Icon(Icons.directions),
                SizedBox(width: 8),
                Text('Get Directions'),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RouteDisplayScreen(
                    hostelLocation: hostelLocation,
                    hostelName: hostel['name'] ?? 'Hostel',
                    hostelAddress: hostel['address'],
                  ),
                ),
              );
            },
          ),
          PopupMenuItem(
            child: const Text('Call'),
            onTap: () {
              print('Calling: ${hostel['phone']}');
            },
          ),
        ],
      ),
    );
  }
}
