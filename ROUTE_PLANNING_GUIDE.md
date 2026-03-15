# Route Planning Feature - Implementation Guide

## Overview

This feature enables users to calculate the best route and estimated travel time from their current location to a selected hostel using OpenStreetMap and OSRM (Open Source Routing Machine).

## Features

- ✅ Get user's current GPS location
- ✅ Display hostel location on map
- ✅ Calculate best route (car, bike, foot)
- ✅ Show distance and estimated travel time
- ✅ Draw route polyline on map
- ✅ Support multiple routing profiles
- ✅ Step-by-step turn directions
- ✅ No API key required (uses free OSRM)

## Technology Stack

| Technology | Purpose |
|-----------|---------|
| **flutter_map** | OpenStreetMap visualization |
| **latlong2** | GPS coordinate handling |
| **geolocator** | User location retrieval |
| **http** | API requests to OSRM |
| **provider** | State management |

## Components

### 1. Models (`lib/data/models/route_model.dart`)

```dart
class RouteInfo {
  final List<LatLng> polylinePoints;      // Route coordinates
  final double distance;                   // Distance in kilometers
  final int duration;                      // Duration in seconds
  final List<Map<String, dynamic>> steps;  // Turn-by-turn directions
}

class RoutingRequest {
  // Encapsulates routing request parameters
}
```

**Key Methods:**
- `formattedDistance` - Returns formatted distance string (e.g., "5.2km", "250m")
- `formattedDuration` - Returns formatted time string (e.g., "15m", "1h 30m")
- `durationInHours` - Returns duration as decimal hours

### 2. Service (`lib/data/services/routing_service.dart`)

The `RoutingService` handles all routing calculations:

```dart
// Get route using free OSRM
RouteInfo? route = await RoutingService.getRouteOsrm(
  startLat: 28.6139,
  startLng: 77.2090,
  endLat: 28.7041,
  endLng: 77.1025,
  profile: 'car',  // 'car', 'bike', or 'foot'
);

// Calculate straight-line distance
double distance = RoutingService.calculateDistance(
  LatLng(28.6139, 77.2090),
  LatLng(28.7041, 77.1025),
);

// Estimate travel time
int seconds = RoutingService.estimateTravelTime(
  5.2,      // distance in km
  mode: 'car',
);
```

### 3. Provider (`lib/data/providers/routing_provider.dart`)

Manages routing state using Provider pattern:

```dart
class RoutingProvider with ChangeNotifier {
  // Getters
  RouteInfo? get currentRoute;
  LatLng? get startPoint;
  LatLng? get endPoint;
  bool get isLoadingRoute;
  String? get routeError;
  
  // Methods
  void setStartPoint(LatLng point);
  void setEndPoint(LatLng point);
  void setProfile(String profile);  // 'car', 'bike', 'foot'
  Future<bool> calculateRoute();
  void clearRoute();
  void reset();
}
```

### 4. Widgets

#### RouteInfoWidget
Displays route summary with distance, time, and step-by-step directions:

```dart
RouteInfoWidget(
  route: routeInfo,
  expanded: false,
  onClose: () { },
)
```

Features:
- Animated expand/collapse
- Distance and estimated time display
- Average speed calculation
- Turn-by-turn directions (first 5 steps)

### 5. Screen (`lib/presentation/screens/route_display_screen.dart`)

Full-featured route display screen with:
- Interactive OpenStreetMap display
- Route polyline visualization
- Start and end point markers
- Transportation mode selector (Car/Bike/Walk)
- Real-time route calculations
- Recenter and fit-to-bounds controls
- Step-by-step navigation instructions

## Usage Examples

### Example 1: Basic Route Calculation

```dart
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'data/providers/routing_provider.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<RoutingProvider>(
      builder: (context, routingProvider, _) {
        return ElevatedButton(
          onPressed: () async {
            // Set points
            routingProvider.setStartPoint(
              LatLng(userLat, userLng),
            );
            routingProvider.setEndPoint(
              LatLng(hostelLat, hostelLng),
            );
            
            // Calculate route
            bool success = await routingProvider.calculateRoute();
            
            if (success) {
              final route = routingProvider.currentRoute;
              print('Distance: ${route.formattedDistance}');
              print('Time: ${route.formattedDuration}');
            }
          },
          child: Text('Get Directions'),
        );
      },
    );
  }
}
```

### Example 2: Navigate to Route Display Screen

```dart
import 'presentation/screens/route_display_screen.dart';

// From hostel details screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => RouteDisplayScreen(
      hostelLocation: LatLng(28.7041, 77.1025),
      hostelName: 'My Awesome Hostel',
      hostelAddress: '123 Main St',
    ),
  ),
);
```

### Example 3: Adding Get Directions Button to Hostel Card

```dart
// In your hostel details widget
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteDisplayScreen(
          hostelLocation: LatLng(
            hostel['location']['lat'],
            hostel['location']['lng'],
          ),
          hostelName: hostel['name'],
          hostelAddress: hostel['address'],
        ),
      ),
    );
  },
  icon: const Icon(Icons.directions),
  label: const Text('Get Directions'),
)
```

### Example 4: Multiple Transport Modes

```dart
final routingProvider = 
    Provider.of<RoutingProvider>(context, listen: false);

// Set transport mode before calculating
routingProvider.setProfile('bike'); // or 'car', 'foot'
await routingProvider.calculateRoute();

// Switch modes dynamically
routingProvider.setProfile('car');
await routingProvider.calculateRoute();
```

## Integration with Hostel Details Screen

To add the "Get Directions" feature to your hostel details screen:

```dart
class HostelDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> hostel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ... existing hostel info widgets ...
          
          // Add this button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RouteDisplayScreen(
                      hostelLocation: LatLng(
                        hostel['location']['lat'],
                        hostel['location']['lng'],
                      ),
                      hostelName: hostel['name'],
                      hostelAddress: hostel['address'],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.directions),
              label: const Text('Get Directions to Hostel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFACC15),
                foregroundColor: const Color(0xFF0F172A),
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

## API Endpoints Used

### OSRM (Free, No Key Required)

**Base URL:** `https://router.project-osrm.org/route/v1`

**Endpoint:** `/v1/{profile}/{coordinates}`

**Parameters:**
| Parameter | Values | Default |
|-----------|--------|---------|
| profile | `car`, `bike`, `foot` | `car` |
| coordinates | `lng,lat;lng,lat` | - |
| overview | `full`, `simplified`, `false` | `full` |
| geometries | `geojson`, `polyline` | `geojson` |
| steps | `true`, `false` | `false` |

**Example Request:**
```
GET https://router.project-osrm.org/route/v1/car/77.2090,28.6139;77.1025,28.7041?overview=full&steps=true&geometries=geojson
```

**Response:**
```json
{
  "routes": [{
    "geometry": { "coordinates": [...], "type": "LineString" },
    "legs": [{
      "distance": 15000,
      "duration": 600,
      "steps": [...]
    }]
  }]
}
```

## Response Handling

The service automatically decodes polyline responses and extracts:
- **Distance** (converted from meters to kilometers)
- **Duration** (in seconds)
- **Route coordinates** (as LatLng list)
- **Turn instructions** (if available)

## Error Handling

```dart
final route = await RoutingService.getRouteOsrm(...);

if (route == null) {
  // Handle error - show error message to user
  print('Failed to calculate route');
}

// Or use RoutingProvider:
bool success = await routingProvider.calculateRoute();
if (!success) {
  print(routingProvider.routeError); // Get error message
}
```

## Performance Tips

1. **Simplify Polylines** - Use `RoutingService.simplifyPolyline()` for better performance with many points
2. **Cache Routes** - Store calculated routes in local storage if the same route is requested frequently
3. **Debounce Calculations** - Avoid recalculating routes too frequently when parameters change
4. **Lazy Load** - Load route details only when needed

## Customization

### Custom Map Styling

You can customize the map appearance in `FlutterMap`:

```dart
TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  // For different map styles, use other tile providers:
  // Dark mode: 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}.png'
  // Satellite: 'https://mt0.google.com/vt/lyrs=s&hl=en&x={x}&y={y}&z={z}'
)
```

### Custom Marker Icons

Replace the `_buildMarker` method in `RouteDisplayScreen` to customize marker appearance.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Location permission denied | Ensure location permissions are granted in app settings |
| Route not calculating | Check internet connection; verify coordinates are valid |
| No polyline showing | Ensure OSRM API is accessible; check response format |
| Marker not appearing | Check coordinate format (LatLng expects lat, lng) |
| Map not centering | Call `_fitMapToRoute()` after route is calculated |

## License & Attribution

- **OSRM:** Open Source Routing Machine (open source)
- **OpenStreetMap:** © OpenStreetMap contributors
- **flutter_map:** MIT License

## Future Enhancements

- [ ] Add support for intermediate waypoints
- [ ] Implement offline routing with pre-downloaded maps
- [ ] Add real-time traffic information
- [ ] Integration with navigation apps (Google Maps, Apple Maps)
- [ ] Route history storage
- [ ] Voice turn-by-turn navigation
- [ ] Multiple route alternatives
- [ ] Cost estimation for taxi/ride-share
