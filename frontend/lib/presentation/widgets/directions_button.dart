import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../screens/routing_map_screen.dart';

class GetDirectionsButton extends StatelessWidget {
  final LatLng hostelLocation;
  final String hostelName;
  final String? hostelAddress;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final bool isCompact;

  const GetDirectionsButton({
    Key? key,
    required this.hostelLocation,
    required this.hostelName,
    this.hostelAddress,
    this.onPressed,
    this.style,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isCompact
        ? _buildCompactButton(context)
        : _buildFullButton(context);
  }

  Widget _buildCompactButton(BuildContext context) {
    return Tooltip(
      message: 'Get Directions',
      child: FloatingActionButton.extended(
        onPressed: onPressed ?? () => _navigateToRoute(context),
        icon: const Icon(Icons.directions),
        label: const Text('Directions'),
        backgroundColor: const Color(0xFFFACC15),
        foregroundColor: const Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildFullButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed ?? () => _navigateToRoute(context),
      icon: const Icon(Icons.directions),
      label: const Text('Get Directions'),
      style: style ??
          ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFACC15),
            foregroundColor: const Color(0xFF0F172A),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
    );
  }

  void _navigateToRoute(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoutingMapScreen(
          hostelLocation: hostelLocation,
          hostelName: hostelName,
          hostelAddress: hostelAddress,
        ),
      ),
    );
  }
}

/// Quick access widget for adding directions to any hostel card
class DirectionsChip extends StatelessWidget {
  final LatLng hostelLocation;
  final String hostelName;
  final String? hostelAddress;

  const DirectionsChip({
    Key? key,
    required this.hostelLocation,
    required this.hostelName,
    this.hostelAddress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Chip(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RoutingMapScreen(
              hostelLocation: hostelLocation,
              hostelName: hostelName,
              hostelAddress: hostelAddress,
            ),
          ),
        );
      },
      icon: const Icon(Icons.directions),
      label: const Text('Directions'),
      backgroundColor: const Color(0xFFFACC15).withOpacity(0.2),
      labelStyle: const TextStyle(
        color: Color(0xFFFACC15),
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
