# Route Planning Feature - Architecture & Data Flow

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      HOSTEL FINDER APP                          │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    PRESENTATION LAYER                    │  │
│  │                                                          │  │
│  │  ┌─────────────────┐    ┌──────────────────────────┐   │  │
│  │  │ Hostel Details  │───→│  Route Display Screen    │   │  │
│  │  │    Screen       │    │  (Interactive Map)      │   │  │
│  │  └─────────────────┘    └──────────────────────────┘   │  │
│  │         ↓                 ↙  ↑  ↖                       │  │
│  │  ┌─────────────────┐    ┌─────────────────┐            │  │
│  │  │    Widgets      │───→│ Route Info Widget           │  │
│  │  │ - GetDirections │    │ - Distance Display         │  │
│  │  │ - DirectionsChip│    │ - Time Display             │  │
│  │  └─────────────────┘    │ - Steps Instructions       │  │
│  │                         └─────────────────┘            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                             ↑                                  │
│                    Calls & Consumes Data                       │
│                             ↓                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                   STATE LAYER (Provider)                 │  │
│  │                                                          │  │
│  │  ┌──────────────────────────────────────────────────┐   │  │
│  │  │         RoutingProvider                          │   │  │
│  │  │  - currentRoute: RouteInfo?                     │   │  │
│  │  │  - startPoint: LatLng?                          │   │  │
│  │  │  - endPoint: LatLng?                            │   │  │
│  │  │  - selectedProfile: String                      │   │  │
│  │  │  - isLoadingRoute: bool                         │   │  │
│  │  │                                                  │   │  │
│  │  │  Methods:                                        │   │  │
│  │  │  + setStartPoint()                              │   │  │
│  │  │  + setEndPoint()                                │   │  │
│  │  │  + setProfile()                                 │   │  │
│  │  │  + calculateRoute()                             │   │  │
│  │  │  + recalculateRoute()                           │   │  │
│  │  └──────────────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                             ↑                                  │
│                        Fetch Route Data                        │
│                             ↓                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                   SERVICE LAYER                          │  │
│  │                                                          │  │
│  │  ┌──────────────────────────────────────────────────┐   │  │
│  │  │         RoutingService (OSRM)                   │   │  │
│  │  │  + getRouteOsrm()     [Free, No API Key]        │   │  │
│  │  │  + calculateDistance() [Haversine Formula]      │   │  │
│  │  │  + estimateTravelTime()                         │   │  │
│  │  │  + simplifyPolyline()  [Performance]            │   │  │
│  │  └──────────────────────────────────────────────────┘   │  │
│  │                                                          │  │
│  │  ┌──────────────────────────────────────────────────┐   │  │
│  │  │         LocationService (geolocator)            │   │  │
│  │  │  + getCurrentLocation()                         │   │  │
│  │  │  + checkAndRequestPermission()                 │   │  │
│  │  │  + getLocationStream()                          │   │  │
│  │  └──────────────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                             ↑                                  │
│                        HTTP Requests                           │
│                             ↓                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                   EXTERNAL APIs                          │  │
│  │                                                          │  │
│  │  • OSRM Router API                                      │  │
│  │    https://router.project-osrm.org/route/v1            │  │
│  │                                                          │  │
│  │  • OpenStreetMap Tiles                                 │  │
│  │    https://tile.openstreetmap.org/{z}/{x}/{y}.png      │  │
│  │                                                          │  │
│  │  • Device Location Services                             │  │
│  │    GPS / Android Location Manager                      │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow Diagram

```
USER INTERACTION
       ↓
┌─────────────────────────────────────────┐
│ 1. User Opens Hostel Details            │
│    - Hostel with location (lat, lng)    │
└─────────────────────────────────────────┘
       ↓
┌─────────────────────────────────────────┐
│ 2. User Taps "Get Directions" Button    │
│    - GetDirectionsButton widget         │
└─────────────────────────────────────────┘
       ↓
┌─────────────────────────────────────────┐
│ 3. Navigate to RouteDisplayScreen       │
│    - Pass hostel coordinates            │
└─────────────────────────────────────────┘
       ↓
┌─────────────────────────────────────────┐
│ 4. Request User Location                │
│    - LocationService.getCurrentLocation │
│    - Check permissions first            │
└─────────────────────────────────────────┘
       ↓
┌─────────────────────────────────────────┐
│ 5. Set Routing Points                   │
│    - RoutingProvider.setStartPoint()    │
│    - RoutingProvider.setEndPoint()      │
└─────────────────────────────────────────┘
       ↓
┌─────────────────────────────────────────┐
│ 6. Calculate Route via OSRM             │
│    - RoutingProvider.calculateRoute()   │
│    - Call RoutingService.getRouteOsrm() │
└─────────────────────────────────────────┘
       ↓
┌─────────────────────────────────────────┐
│ 7. OSRM API Request                     │
│    POST to:                             │
│    router.project-osrm.org/route/v1/... │
│    - Start coordinates [lng, lat]       │
│    - End coordinates [lng, lat]         │
│    - Profile (car/bike/foot)            │
│    - Request polyline + steps           │
└─────────────────────────────────────────┘
       ↓
┌─────────────────────────────────────────┐
│ 8. Parse OSRM Response                  │
│    RouteInfo created with:              │
│    - polylinePoints (List<LatLng>)      │
│    - distance (km)                      │
│    - duration (seconds)                 │
│    - steps (turn instructions)          │
└─────────────────────────────────────────┘
       ↓
┌─────────────────────────────────────────┐
│ 9. Update Routing Provider              │
│    - _currentRoute = RouteInfo          │
│    - _isLoadingRoute = false            │
│    - notifyListeners()                  │
└─────────────────────────────────────────┘
       ↓
┌─────────────────────────────────────────┐
│ 10. UI Updates (via Consumer)           │
│     - Draw map with OpenStreetMap tiles │
│     - Display route polyline            │
│     - Show markers (start & end)        │
│     - Display distance & time           │
│     - Show step instructions            │
└─────────────────────────────────────────┘
       ↓
┌─────────────────────────────────────────┐
│ 11. User Interactions                   │
│     - Change transport mode             │
│         → Recalculate route             │
│     - Pan/Zoom map                      │
│     - Tap expand for step details       │
│     - Tap recenter button               │
└─────────────────────────────────────────┘
```

## Component Interaction Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                    RouteDisplayScreen                            │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Stack Layout                                               │ │
│  │                                                            │ │
│  │  ┌──────────────────────────────────────────────────┐     │ │
│  │  │ FlutterMap (Center)                              │     │ │
│  │  │ ├─ TileLayer (OpenStreetMap)                     │     │ │
│  │  │ ├─ PolylineLayer (Route)                         │     │ │
│  │  │ │  └─ Polyline (Blue line with yellow border)   │     │ │
│  │  │ └─ MarkerLayer                                  │     │ │
│  │  │    ├─ User Location (Green circle)              │     │ │
│  │  │    └─ Hostel Location (Yellow marker)           │     │ │
│  │  └──────────────────────────────────────────────────┘     │ │
│  │                                                            │ │
│  │  ┌──────────────────────────────────────────────────┐     │ │
│  │  │ Top-Right Controls (Positioned)                 │     │ │
│  │  │ ├─ Transport Mode Buttons (Car/Bike/Walk)      │     │ │
│  │  │ └─ Recenter Button                              │     │ │
│  │  └──────────────────────────────────────────────────┘     │ │
│  │                                                            │ │
│  │  ┌──────────────────────────────────────────────────┐     │ │
│  │  │ Bottom Panel (Positioned)                        │     │ │
│  │  │ ├─ RouteInfoWidget                              │     │ │
│  │  │ │  ├─ Distance (5.2km)                           │     │ │
│  │  │ │  ├─ Time (15m)                                 │     │ │
│  │  │ │  ├─ Avg Speed (20.8 km/h)                      │     │ │
│  │  │ │  └─ Steps (expandable)                         │     │ │
│  │  │ └─ Expand Button (FAB)                           │     │ │
│  │  └──────────────────────────────────────────────────┘     │ │
│  │                                                            │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Consumer<RoutingProvider>                                      │
│  └─ Listening to route updates                                 │
└──────────────────────────────────────────────────────────────────┘
```

## State Management Flow

```
RoutingProvider State Changes
│
├─ setStartPoint(LatLng)
│  └─ _startPoint = point
│     └─ notifyListeners() → UI updates
│
├─ setEndPoint(LatLng)
│  └─ _endPoint = point
│     └─ notifyListeners() → UI updates
│
├─ setProfile(String)
│  └─ _selectedProfile = profile  ('car' | 'bike' | 'foot')
│     └─ notifyListeners() → Button UI updates
│
├─ calculateRoute()  [Async]
│  ├─ _isLoadingRoute = true
│  ├─ _routeError = null
│  ├─ notifyListeners() → Show loading spinner
│  ├─ RoutingService.getRouteOsrm(...)
│  │  ├─ Make HTTP request to OSRM
│  │  ├─ Parse response → RouteInfo
│  │  └─ Return RouteInfo or null
│  ├─ if (route != null)
│  │  ├─ _currentRoute = route
│  │  └─ _routeError = null
│  ├─ else
│  │  ├─ _currentRoute = null
│  │  └─ _routeError = "Failed to calculate route"
│  ├─ _isLoadingRoute = false
│  └─ notifyListeners() → Show route on map
│
└─ reset()
   ├─ Clear all state
   ├─ _startPoint = null
   ├─ _endPoint = null
   ├─ _currentRoute = null
   ├─ _routeError = null
   ├─ _isLoadingRoute = false
   ├─ _selectedProfile = 'car'
   └─ notifyListeners()
```

## API Request/Response

```
┌─────────────────────────────────────┐
│  OSRM Route Request                 │
├─────────────────────────────────────┤
│                                     │
│  GET /route/v1/car/77.2,28.6;77.1,2│
│  8.7                                │
│                                     │
│  Query Parameters:                  │
│  - overview=full                    │
│  - steps=true                       │
│  - geometries=geojson               │
│  - alternatives=false               │
│                                     │
└─────────────────────────────────────┘
              ↓ HTTP
┌─────────────────────────────────────┐
│  OSRM Route Response                │
├─────────────────────────────────────┤
│                                     │
│  {                                  │
│    "code": "Ok",                    │
│    "routes": [{                     │
│      "geometry": {                  │
│        "coordinates": [             │
│          [77.2090, 28.6139],        │
│          [77.2095, 28.6145],        │
│          ...                        │
│        ]                            │
│      },                             │
│      "legs": [{                     │
│        "distance": 15000,           │
│        "duration": 600,             │
│        "steps": [{                  │
│          "name": "Continue",        │
│          "distance": 100,           │
│          "duration": 5              │
│        }, ...]                      │
│      }]                             │
│    }]                               │
│  }                                  │
│                                     │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  RouteInfo Object Created           │
├─────────────────────────────────────┤
│                                     │
│  polylinePoints: [                  │
│    LatLng(28.6139, 77.2090),        │
│    LatLng(28.6145, 77.2095),        │
│    ...                              │
│  ]                                  │
│                                     │
│  distance: 15.0  (km)               │
│  duration: 600   (seconds)          │
│                                     │
│  Formatted:                         │
│  - formattedDistance = "15.0km"     │
│  - formattedDuration = "10m"        │
│  - durationInHours = 0.167          │
│                                     │
└─────────────────────────────────────┘
```

## Error Handling Flow

```
calculateRoute()
│
├─ START
│
├─ Check: startPoint != null AND endPoint != null
│  ├─ NO → Set error, return false
│  └─ YES → Continue
│
├─ Set isLoadingRoute = true, clear error
│
├─ Call RoutingService.getRouteOsrm()
│  ├─ HTTP Request
│  │
│  ├─ Try/Catch Block
│  │  ├─ Timeout (15s) → Error
│  │  ├─ Network Error → Error
│  │  ├─ JSON Parse Error → Error
│  │  ├─ Invalid Response → Error
│  │  └─ Success → Continue
│  │
│  ├─ Check statusCode == 200
│  │  ├─ NO → Error
│  │  └─ YES → Parse response
│  │
│  └─ Return RouteInfo or null
│
├─ Check: route != null
│  ├─ NO → Set error message
│  └─ YES → Update currentRoute
│
├─ Set isLoadingRoute = false
│
├─ notifyListeners()
│
├─ UI Updates
│  ├─ If error → Show error dialog/snack
│  ├─ If loading → Show spinner
│  └─ If success → Show map with route
│
└─ END
```

## Module Responsibilities

### RouteInfo Model
- Data structure for route information
- Formatting utilities (distance, duration)
- Polyline decoding (if encoded format)

### RoutingService
- OSRM API integration
- Distance/time calculations
- Polyline simplification
- Error handling

### RoutingProvider
- State management
- Route calculation orchestration
- Profile/mode management
- Listener notification

### UI Widgets
- RouteInfoWidget: Display route summary
- GetDirectionsButton: Navigation entry point
- DirectionsChip: Quick access alternative

### RouteDisplayScreen
- Map visualization
- Marker management
- Polyline rendering
- Control UI (zoom, pan, mode select)
- Route information display

## Performance Considerations

```
┌──────────────────────────────────────────────┐
│ Performance Optimizations                    │
├──────────────────────────────────────────────┤
│                                              │
│ 1. Polyline Simplification                   │
│    - Reduce points for faster rendering     │
│    - Use Douglas-Peucker algorithm          │
│                                              │
│ 2. Lazy Load Details                         │
│    - Load step instructions on demand       │
│    - Show first 5 steps initially            │
│                                              │
│ 3. Async Route Calculation                   │
│    - Don't block UI thread                  │
│    - Show loading indicator                 │
│                                              │
│ 4. Map Tile Caching                          │
│    - flutter_map caches tiles               │
│    - Faster loading on revisits             │
│                                              │
│ 5. Marker Optimization                       │
│    - Use only necessary markers             │
│    - Avoid 100+ markers on map              │
│                                              │
└──────────────────────────────────────────────┘
```

---

**This architecture ensures:**
- ✅ Clean separation of concerns
- ✅ Reusable components
- ✅ Efficient state management
- ✅ Responsive user experience
- ✅ Easy maintenance and testing
