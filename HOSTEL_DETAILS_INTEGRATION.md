# Integration Guide: Add Directions to Hostel Details Screen

## Overview
This guide shows exactly how to add the "Get Directions" button to your existing `hostel_details_screen.dart` file.

## Step 1: Add Imports

At the top of `hostel_details_screen.dart`, add these imports:

```dart
import 'package:latlong2/latlong.dart';
import '../../presentation/widgets/directions_button.dart';     // Add this
import '../../presentation/screens/route_display_screen.dart';  // Add this (optional)
```

## Step 2: Add Directions Handler (Optional)

If you want custom handling before opening the route, add this method to `_HostelDetailsScreenState`:

```dart
void _handleGetDirections() {
  final lat = widget.hostel['location']?['lat'] ?? 0.0;
  final lng = widget.hostel['location']?['lng'] ?? 0.0;
  
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

  // Show some feedback
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Opening directions...'),
      behavior: SnackBarBehavior.floating,
    ),
  );

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => RouteDisplayScreen(
        hostelLocation: LatLng(lat, lng),
        hostelName: widget.hostel['name'] ?? 'Hostel',
        hostelAddress: widget.hostel['address'],
      ),
    ),
  );
}
```

## Step 3: Add Button to UI

### Option A: Add Above the Book Button (RECOMMENDED)

Find this section in the `build` method (around line 475-525):

```dart
// Book Now button (only for non-OSM, non-admin users)
if (!isOsm)
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
        ElevatedButton(
          // ... rest of button code
```

**Replace it with:**

```dart
// Directions and Book buttons
if (!isOsm)
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
        // NEW: Get Directions Button
        GetDirectionsButton(
          hostelLocation: LatLng(lat, lng),
          hostelName: hostel['name'] ?? 'Hostel',
          hostelAddress: hostel['address'],
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
  ),
```

### Option B: Add as Side-by-Side Buttons

If you want both buttons on the same row, use this instead:

```dart
// Directions and Book buttons
if (!isOsm)
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
        // Side-by-side buttons
        Row(
          children: [
            // Get Directions button (40% width)
            Expanded(
              flex: 40,
              child: ElevatedButton.icon(
                onPressed: () {
                  final lat = hostel['location']?['lat'] ?? 0.0;
                  final lng = hostel['location']?['lng'] ?? 0.0;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RouteDisplayScreen(
                        hostelLocation: LatLng(lat, lng),
                        hostelName: hostel['name'] ?? 'Hostel',
                        hostelAddress: hostel['address'],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.directions, size: 18),
                label: const Text('Directions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: const Color(0xFFFACC15),
                  side: const BorderSide(color: Color(0xFFFACC15)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Book Now button (60% width)
            Expanded(
              flex: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAdmin ? Colors.grey : const Color(0xFFFACC15),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: (isAdmin || _isBooking) ? null : _handleBooking,
                child: _isBooking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        isAdmin ? 'Booking Disabled for Admins' : 'Book Now',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
```

### Option C: Add as a Quick Chip Above the Button

If you want a minimal addition, use this approach:

```dart
// Add before the existing button code
if (!isOsm && !isAdmin)
  Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DirectionsChip(
      hostelLocation: LatLng(lat, lng),
      hostelName: hostel['name'] ?? 'Hostel',
      hostelAddress: hostel['address'],
    ),
  ),
```

## Step 4: Add Latitude/Longitude Variables Extraction

Before your existing button code, add this at the top of the button section:

```dart
final lat = hostel['location']?['lat'] ?? 0.0;
final lng = hostel['location']?['lng'] ?? 0.0;
```

## Step 5: Don't Forget to Declare Variables

Make sure you have `lat` and `lng` variables in the build method. If not already present, add them with the hostel variable declarations (around line 105-110):

```dart
@override
Widget build(BuildContext context) {
  final hostel = widget.hostel;
  final auth = Provider.of<AuthProvider>(context, listen: false);

  // ... existing code ...
  
  final List<String> images = (hostel['images'] != null &&
          (hostel['images'] as List).isNotEmpty)
      ? List<String>.from(hostel['images'])
      : ['https://images.unsplash.com/photo-1555854877-bab0e564b8d5'];

  // ADD THESE:
  final double lat = (hostel['location']?['lat'] as num?)?.toDouble() ?? 0.0;
  final double lng = (hostel['location']?['lng'] as num?)?.toDouble() ?? 0.0;
  
  // ... rest of build method ...
}
```

## Complete Example

Here's a complete code snippet showing the modification:

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';                        // ADD THIS
import '../../core/api_config.dart';
import '../../data/providers/auth_provider.dart';
import '../../presentation/widgets/directions_button.dart';   // ADD THIS
import '../../presentation/screens/route_display_screen.dart'; // ADD THIS
import 'booking_screen.dart';

// ... rest of code from line 12 onwards ...

@override
Widget build(BuildContext context) {
  final hostel = widget.hostel;
  final auth = Provider.of<AuthProvider>(context, listen: false);

  final isOsm = (hostel['source'] ?? '').toString() == 'osm' || 
                (hostel['_id'] ?? '').toString().startsWith('osm_');
  final isAdmin = auth.userRole == 'admin';

  // Extract coordinates
  final double lat = (hostel['location']?['lat'] as num?)?.toDouble() ?? 0.0;
  final double lng = (hostel['location']?['lng'] as num?)?.toDouble() ?? 0.0;
  final LatLng hostelLocation = LatLng(lat, lng);

  // ... rest of build method ...

  // In the bottom navigation bar section, replace the book button code with:
  if (!isOsm)
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
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Get Directions Button - NEW!
          GetDirectionsButton(
            hostelLocation: hostelLocation,
            hostelName: hostel['name'] ?? 'Hostel',
            hostelAddress: hostel['address'],
          ),
          const SizedBox(height: 12),
          // Book Now button - EXISTING
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isAdmin ? Colors.grey : const Color(0xFFFACC15),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: (isAdmin || _isBooking) ? null : _handleBooking,
            child: _isBooking
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : Text(
                    isAdmin ? 'Booking Disabled for Admins' : 'Book Now',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    ),
}
```

## Testing the Integration

1. Run your app: `flutter run`  
2. Navigate to a hostel details screen
3. Scroll to the bottom - you should see:
   - "Get Directions" button above the "Book Now" button
4. Tap "Get Directions"
5. The route display screen opens with:
   - Map showing the route
   - Route polyline from your location to hostel
   - Distance and travel time information
   - Transport mode selector (Car/Bike/Walk)

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Import errors | Make sure all dependencies are in pubspec.yaml and you ran `flutter pub get` |
| Button not appearing | Check that `!isOsm` condition is true |
| Route not calculating | Ensure hostel has valid lat/lng coordinates |
| App crashes on tap | Check that RoutingProvider is added to main.dart |
| Location permission error | Check app permissions in device settings |

## Next Steps

- Customize button appearance in `directions_button.dart`
- Add route information caching
- Integrate with other hostel screens
- Add favorites/saved locations
