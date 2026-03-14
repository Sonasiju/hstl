import 'package:flutter/material.dart';

class HostelMarkerWidget extends StatelessWidget {
  final String name;
  final double distance;
  final double rating;
  final VoidCallback onTap;

  const HostelMarkerWidget({
    Key? key,
    required this.name,
    required this.distance,
    required this.rating,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B), // Matches dark theme
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFACC15), width: 1),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${distance.toStringAsFixed(1)} km • ⭐ $rating',
                  style: const TextStyle(color: Color(0xFFFACC15), fontSize: 8),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.location_on,
            color: Color(0xFFFACC15), // Yellow for hostels
            size: 30,
          ),
        ],
      ),
    );
  }
}
