# Hostel Management App - Complete Section Breakdown

## 📱 FRONTEND (Flutter App)

### 1. **Login Screen** 
**File:** [login_screen.dart](../frontend/lib/presentation/screens/login_screen.dart)

**What it does:**
- User enters email and password
- Authenticates against backend
- Receives JWT token for session
- Routes user to MainLayout on success

**Key Features:**
- Email validation
- Password field with show/hide toggle
- Error messages for wrong credentials
- Remember me option (if implemented)
- Link to signup for new users

**Backend call:** `POST /auth/login`

---

### 2. **Signup Screen**
**File:** [signup_screen.dart](../frontend/lib/presentation/screens/signup_screen.dart)

**What it does:**
- New users can create account
- Validates email format and password strength
- Stores user credentials in MongoDB

**Key Features:**
- Email validation
- Password confirmation match
- Phone number field
- Terms & conditions checkbox
- Duplicate email detection

**Backend call:** `POST /auth/register`

---

### 3. **Main Layout (Bottom Navigation)**
**File:** [main_layout.dart](../frontend/lib/presentation/screens/main_layout.dart)

**What it does:**
- Central navigation hub with 4 tabs
- Each tab is an independent screen
- Uses State management to track selected tab

**Tab Structure:**
```
🏠 Home     → HomeScreen
🗺️ Map      → MapScreen  
📅 Bookings → BookingsScreen
👤 Profile  → ProfileScreen
```

**How it works:**
- Lazy loading - only builds screens when first opened
- Uses Offstage widget for performance
- Persists state between tab switches

---

### 4. **Home Screen**
**File:** [home_screen.dart](../frontend/lib/presentation/screens/home_screen.dart)

**What it does:**
- Dashboard showing recent hostels
- Quick access to browse/search
- Welcome message with user name
- Featured hostels section

**Key Components:**
- User greeting
- Search bar (local navigation to map)
- Hostel cards with quick info:
  - Hostel name
  - Location/city
  - Type (men's, women's, coed)
  - Quick view button

**Purpose:** Entry point - encourages exploration

---

### 5. **Map Screen** ⭐ (Most Important)
**File:** [map_screen.dart](../frontend/lib/presentation/screens/map_screen.dart)

**What it does:**
- Core feature: Interactive map showing hostels
- Displays user's current location
- Searches locations by city/place
- Filters hostels by type
- Shows hostel details in bottom panel

**Key Sections:**

#### a) **Search Bar**
- Autocomplete using OpenStreetMap Nominatim API
- Dropdown with place suggestions
- Tapping a place centers map and fetches hostels

#### b) **Filters**
- Type filters: Any Share, Men & Boys, Girls & Women, coed
- Only shows matching hostels

#### c) **Map Display**
- Uses FlutterMap library
- Dark CartoDB tiles for theme match
- Markers for:
  - **Blue dot** = User's location
  - **Green markers** = Database hostels (registered)
  - **Blue markers** = OSM hostels (from OpenStreetMap)

#### d) **Hostel Markers**
- Shows hostel name on marker
- Tap marker → shows details in bottom panel
- Different colors distinguish source

#### e) **Bottom Panel**
Shows selected hostel:
- Name, location, type
- Contact info (phone/email)
- Ratings and reviews
- "View Details" or "Book Now" button
- Source badge (Registered/OpenStreetMap)

#### f) **Floating Buttons**
- **My Location** (yellow) = Centers map on user
- **Refresh** (dark) = Reloads nearby hostels

#### g) **Search This Area Button**
- Appears when user pans >1.5km away
- Fetches new hostels for that area

**Key Features:**
- Real-time location tracking (Geolocator)
- Distance calculation
- Merges database + OSM hostels
- 10km radius filter for OSM hostels
- Permission handling for GPS

**Backend calls:**
- `GET /hostels/nearby?lat=X&lng=Y&radius=10`

**External APIs:**
- OpenStreetMap Nominatim (place search)
- CartoDB (map tiles)

---

### 6. **Hostel Details Screen**
**File:** [hostel_details_screen.dart](../frontend/lib/presentation/screens/hostel_details_screen.dart)

**What it does:**
- Full view of single hostel
- All information about the hostel
- Options to book or get directions
- Reviews and ratings

**Sections:**

#### a) **Image Carousel**
- Shows hostel photos
- Auto-scrolling or manual swipe
- Using CarouselSlider package

#### b) **Hostel Info Card**
- Name (large title)
- Location/address
- Type badge
- Rating stars
- Reviews count

#### c) **Details Section**
- Phone number (clickable - dials)
- Email (clickable - opens email)
- Address/city
- Amenities (if available)
- Price per bed
- Occupancy info

#### d) **Reviews Section**
- User reviews and ratings
- Scrollable list
- Average rating display
- Individual review cards with:
  - User name
  - Star rating
  - Review text
  - Date posted

#### e) **Action Buttons**
- **"Get Directions"** - Opens map with route
- **"Book Now"** - Opens booking screen
- **Validation checks:**
  - OSM hostels show "cannot book" message
  - Sample/demo hostels show warning

**Backend calls:**
- `GET /hostels/:id` (fetch details)
- `GET /hostels/:id/reviews` (fetch reviews)

---

### 7. **Booking Screen**
**File:** [booking_screen.dart](../frontend/lib/presentation/screens/booking_screen.dart)

**What it does:**
- Users can create a booking
- Select dates and bed type
- Calculate total price
- Submit booking to backend

**Booking Process:**

1. **Date Selection**
   - Check-in date picker
   - Check-out date picker
   - Duration calculation

2. **Bed Type Selection**
   - Dropdown or radio buttons
   - Different prices for different beds

3. **Price Calculation**
   - Base price × number of days
   - Display total cost

4. **Booking Confirmation**
   - Review all details
   - Submit button sends to backend

5. **Success Message**
   - Confirmation displayed
   - Booking ID shown
   - Navigate back to map

**Validations:**
- Check-out date must be after check-in
- Minimum 1 night stay
- Hostel must be from database (not OSM)

**Backend call:**
- `POST /bookings` - Create booking

**Response:**
```json
{
  "_id": "booking_id",
  "hostelId": "hostel_id",
  "userId": "user_id",
  "checkIn": "2026-03-20",
  "checkOut": "2026-03-25",
  "bedType": "6-bed dorm",
  "totalPrice": 2500,
  "status": "confirmed"
}
```

---

### 8. **Bookings Screen** (View Your Bookings)
**File:** [bookings_screen.dart](../frontend/lib/presentation/screens/bookings_screen.dart)

**What it does:**
- Shows all user's bookings
- Current and past bookings
- Status tracking
- Cancel/modify options

**Booking Cards Display:**
Each card shows:
- Hostel name and image
- Check-in & check-out dates
- Booking status (confirmed/pending/cancelled)
- Total price
- Tap to view details

**Sections:**
- Upcoming bookings (active)
- Past bookings (completed/cancelled)
- Filter by status
- Search functionality

**Backend call:**
- `GET /bookings/:userId` - Fetch all user's bookings

---

### 9. **Profile Screen**
**File:** [profile_screen.dart](../frontend/lib/presentation/screens/profile_screen.dart)

**What it does:**
- User account management
- View/edit personal info
- Logout
- Preferences settings

**Sections:**

#### a) **Profile Header**
- User avatar/profile picture
- User name
- Email address
- Phone number

#### b) **Account Info**
- Full name
- Email
- Phone
- Edit button

#### c) **Settings**
- Notification preferences
- Language selection
- Theme settings (dark/light)
- Location sharing toggle

#### d) **Actions**
- Edit Profile button
- Change Password option
- Saved Hostels/Wishlist
- Help & Support
- **Logout button**

**Backend calls:**
- `GET /users/:id` - Fetch profile
- `PATCH /users/:id` - Update profile
- `POST /auth/logout` - Logout

---

### 10. **Routing/Directions Map Screen**
**File:** [routing_map_screen.dart](../frontend/lib/presentation/screens/routing_map_screen.dart)

**What it does:**
- Shows route from user to hostel
- Calculates distance and duration
- Real-time navigation display

**How it works:**

1. **Get User Location**
   - Uses Geolocator to get current position
   - Requests GPS permissions

2. **Fetch Route**
   - Calls OSRM API (OpenStreetMap Routing Machine)
   - Gets route coordinates between user and hostel
   - Calculates total distance and time

3. **Display Route**
   - Draws route on map as polyline
   - Shows start (blue) and end (red) points
   - Displays distance and duration
   - Centers map to show entire route

4. **Navigation**
   - Can integrate with native maps (Google Maps, Apple Maps)
   - Guide user turn-by-turn

**Displayed Info:**
- Total distance in km
- Estimated time in minutes
- Current location marker
- Hostel destination marker
- Route path in yellow/blue polyline

**External API:**
- OSRM (OpenStreetMap Routing Machine) for routing

---

### 11. **Admin Screens**

#### a) **Admin Dashboard**
**File:** [admin_dashboard.dart](../frontend/lib/presentation/screens/admin_dashboard.dart)

**What it does:**
- Admin overview and statistics
- Quick access to admin functions
- Metrics display

**Shows:**
- Total users count
- Total bookings count
- Pending hostel applications
- Recent activity

#### b) **Hostel Applicants Screen**
**File:** [hostel_applicants_screen.dart](../frontend/lib/presentation/screens/hostel_applicants_screen.dart)

**What it does:**
- Admin reviews hostel applications
- Approve or reject new hostels
- View hostel details and location

**Process:**
1. Shows list of pending hostel registrations
2. Admin can review:
   - Hostel name, type, location
   - Contact details
   - Uploaded images
3. Admin can:
   - Click "Approve" → Hostel goes live
   - Click "Reject" → Notify applicant with reason

**Backend call:**
- `PUT /hostel-applications/:id/review` - Approve/reject

#### c) **Admin Hostel List**
**File:** [admin_hostel_list_screen.dart](../frontend/lib/presentation/screens/admin_hostel_list_screen.dart)

**What it does:**
- View all registered hostels
- Manage hostel listings
- Edit or remove hostels

#### d) **Create Hostel Screen**
**File:** [create_hostel_screen.dart](../frontend/lib/presentation/screens/create_hostel_screen.dart)

**What it does:**
- Submit new hostel to platform
- Fill all hostel details
- Upload images
- Set pricing

**Form Fields:**
- Hostel name
- Type (men's/women's/coed)
- Address/location
- Phone & email
- Price per bed
- Description
- Image upload (multiple)
- Amenities checkboxes

**Backend call:**
- `POST /hostels` - Submit hostel (status: pending)

---

## 🔌 BACKEND (Node.js/Express)

### **API Endpoints Overview**

#### 1. **Authentication Routes**
**File:** [authRoutes.js](../backend/src/routes/authRoutes.js)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | /auth/register | Create new user account |
| POST | /auth/login | User login with email/password |
| POST | /auth/logout | End session |
| POST | /auth/refresh-token | Get new JWT token |

**What happens:**
- User data validated
- Password hashed with bcrypt
- JWT token generated
- Token sent to frontend
- Token stored in frontend localStorage

---

#### 2. **Hostel Routes**
**File:** [hostelRoutes.js](../backend/src/routes/hostelRoutes.js)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | /hostels | Get all hostels |
| GET | /hostels/:id | Get specific hostel details |
| GET | /hostels/nearby | Get hostels near location |
| POST | /hostels | Create new hostel (submit for review) |
| PATCH | /hostels/:id | Update hostel |
| DELETE | /hostels/:id | Delete hostel |

**Pipeline:**
- New hostel → submitted → pending review
- Admin approves → visible to users
- Stored in MongoDB with location data

---

#### 3. **Booking Routes**
**File:** [bookingRoutes.js](../backend/src/routes/bookingRoutes.js)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | /bookings | Create new booking |
| GET | /bookings/:userId | Get user's bookings |
| GET | /bookings/:id | Get booking details |
| PATCH | /bookings/:id | Update booking (cancel/modify) |
| DELETE | /bookings/:id | Cancel booking |

**Booking Process:**
1. User submits booking request
2. Backend validates:
   - Dates available?
   - User authenticated?
   - Hostel exists?
3. Create booking record
4. Return confirmation with booking ID

---

#### 4. **Review Routes**
**File:** (implied in routes)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | /reviews | Create review for hostel |
| GET | /hostels/:id/reviews | Get reviews for hostel |
| DELETE | /reviews/:id | Delete review |

**Review Content:**
- Rating (1-5 stars)
- Text comment
- User who wrote it
- Timestamp

---

#### 5. **Hostel Application Routes**
**File:** [hostelApplicationRoutes.js](../backend/src/routes/hostelApplicationRoutes.js)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | /hostel-applications | Submit hostel for review |
| GET | /hostel-applications | Get pending applications |
| GET | /hostel-applications/:id | Get app details |
| PUT | /hostel-applications/:id/review | Approve/reject |

**Purpose:**
- Separate application process
- Admin review workflow
- Keeps submitted hostels separate until approved

---

#### 6. **Notification Routes**
**File:** [notificationRoutes.js](../backend/src/routes/notificationRoutes.js)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | /notifications/:userId | Get user notifications |
| POST | /notifications | Create notification |
| PATCH | /notifications/:id | Mark as read |

**Notification Types:**
- Booking confirmation
- Booking cancellation
- New review on hostel
- Admin application decision

---

## 🗄️ DATABASE (MongoDB)

### **User Collection**
```json
{
  "_id": ObjectId,
  "email": "user@example.com",
  "password": "hashed_password",
  "name": "John Doe",
  "phone": "+919876543210",
  "role": "user", // "user", "hostelOwner", "admin"
  "profilePic": "url",
  "createdAt": ISODate,
  "updatedAt": ISODate
}
```

**Purpose:** User accounts and authentication

---

### **Hostel Collection**
```json
{
  "_id": ObjectId,
  "name": "Sunset Hostel",
  "type": "coed", // "men", "women", "coed"
  "owner": ObjectId, // user._id
  "location": {
    "type": "Point",
    "coordinates": [77.5946, 12.9716] // [lng, lat]
  },
  "address": "123 Main St, Bangalore",
  "city": "Bangalore",
  "phone": "+919876543210",
  "email": "info@sunsethost.com",
  "pricePerBed": 500, // ₹
  "images": ["url1", "url2", ...],
  "amenities": ["WiFi", "AC", "Kitchen"],
  "description": "Great budget hostel...",
  "rating": 4.5,
  "reviewCount": 15,
  "status": "approved", // "pending", "approved", "rejected"
  "source": "database", // "database" or "osm"
  "createdAt": ISODate,
  "updatedAt": ISODate
}
```

**Purpose:** Hostel information and details

---

### **Booking Collection**
```json
{
  "_id": ObjectId,
  "userId": ObjectId,
  "hostelId": ObjectId,
  "checkIn": "2026-03-20",
  "checkOut": "2026-03-25",
  "bedType": "6-bed dorm",
  "numberOfBeds": 1,
  "pricePerBed": 500,
  "totalPrice": 2500,
  "status": "confirmed", // "pending", "confirmed", "cancelled"
  "paymentStatus": "paid",
  "createdAt": ISODate,
  "updatedAt": ISODate
}
```

**Purpose:** Track user bookings

---

### **Review Collection**
```json
{
  "_id": ObjectId,
  "userId": ObjectId,
  "hostelId": ObjectId,
  "rating": 4,
  "comment": "Great place, friendly staff!",
  "createdAt": ISODate,
  "updatedAt": ISODate
}
```

**Purpose:** User reviews and ratings

---

### **Notification Collection**
```json
{
  "_id": ObjectId,
  "userId": ObjectId,
  "type": "booking_confirmed", // "booking_confirmed", "review_posted", etc
  "message": "Your booking is confirmed!",
  "relatedId": ObjectId,
  "isRead": false,
  "createdAt": ISODate
}
```

**Purpose:** Notifications for users

---

### **Hostel Application Collection**
```json
{
  "_id": ObjectId,
  "hostelDetails": {...}, // Full hostel info
  "submittedBy": ObjectId, // user._id
  "status": "pending", // "pending", "approved", "rejected"
  "reviewedBy": ObjectId,
  "reviewNotes": "Approved after verification",
  "reviewedAt": ISODate,
  "createdAt": ISODate
}
```

**Purpose:** Hostel registration workflow

---

## 🔐 MIDDLEWARE

### **Authentication Middleware**
**File:** [authMiddleware.js](../backend/src/middlewares/authMiddleware.js)

**What it does:**
- Checks JWT token in request header
- Verifies token is valid
- Extracts user ID from token
- Blocks unauthorized requests

**How it works:**
```
User sends request with: Authorization: Bearer {token}
↓
Middleware checks if token is valid
↓
If valid: Allow request, attach user ID
If invalid: Return 401 Unauthorized error
```

---

## 🎮 CONTROLLERS (Business Logic)

### **Auth Controller**
**File:** [authController.js](../backend/src/controllers/authController.js)

**Functions:**
- `register()` - Create user, hash password, save to DB
- `login()` - Validate credentials, generate JWT
- `logout()` - Invalidate token

---

### **Hostel Controller**
**File:** [hostelController.js](../backend/src/controllers/hostelController.js)

**Functions:**
- `getAllHostels()` - Fetch all hostels with filters
- `getHostelById()` - Specific hostel details
- `getNearbyHostels()` - Find hostels within X km radius
- `createHostel()` - Submit new hostel
- `updateHostel()` - Edit hostel details
- `deleteHostel()` - Remove hostel

**Key Logic:**
- Distance calculation using MongoDB geospatial queries
- Filter by type
- Merge with OSM hostels

---

### **Booking Controller**
**File:** [bookingController.js](../backend/src/controllers/bookingController.js)

**Functions:**
- `createBooking()` - Process new booking
- `getUserBookings()` - Get user's booking history
- `getBookingDetails()` - Specific booking info
- `cancelBooking()` - Mark as cancelled
- `updateBooking()` - Modify dates/bed type

**Validations:**
- Check dates don't overlap with existing bookings
- Verify user is authenticated
- Ensure hostel exists

---

### **Review Controller**
**File:** (implied)

**Functions:**
- `createReview()` - Submit review
- `getHostelReviews()` - All reviews for hostel
- `deleteReview()` - Remove review
- `updateRating()` - Recalculate hostel rating

---

### **Notification Controller**
**File:** [notificationController.js](../backend/src/controllers/notificationController.js)

**Functions:**
- `getNotifications()` - User's notifications
- `createNotification()` - Send notification
- `markAsRead()` - Mark notification read

---

## 🔄 DATA FLOW EXAMPLES

### **Example 1: User Books a Hostel**

```
Frontend (Flutter)
    ↓
User fills booking form & taps "Book Now"
    ↓
POST /bookings {userId, hostelId, checkIn, checkOut}
    ↓
Backend (Node.js/Express)
    ↓
Booking Controller validates data
    ↓
Creates Booking document in MongoDB
    ↓
Creates Notification for user
    ↓
Returns booking confirmation + ID
    ↓
Frontend receives response
    ↓
Shows success message with booking ID
    ↓
User can see booking in "Bookings" screen
```

---

### **Example 2: User Searches on Map**

```
Frontend (Flutter)
    ↓
User opens Map Screen
    ↓
Geolocator gets current location
    ↓
GET /hostels/nearby?lat=12.97&lng=77.59&radius=10
    ↓
Backend queries MongoDB:
  - Find hostels near coordinates
  - Filter by type
  - Calculate distances
    ↓
Also fetch OSM hostels from Nominatim API
    ↓
Merge both sources
    ↓
Return to frontend
    ↓
Frontend renders markers on map
    ↓
User taps marker
    ↓
Bottom panel shows hostel details
```

---

### **Example 3: Admin Approves Hostel**

```
Hostel Owner submits new hostel
    ↓
POST /hostel-applications
    ↓
Stored in "applications" collection with status="pending"
    ↓
Admin sees pending list in dashboard
    ↓
Admin clicks "Review" on pending hostel
    ↓
Opens Hostel Applicants Screen
    ↓
Admin taps "Approve" button
    ↓
PUT /hostel-applications/:id/review {status: "approved"}
    ↓
Backend updates status
    ↓
Creates new Hostel document
    ↓
Updates application status
    ↓
Notification sent to owner: "Hostel Approved!"
    ↓
Hostel now visible on map to users
```

---

## 📊 KEY INTEGRATIONS

### **1. OpenStreetMap (Nominatim)**
- **Used for:** Place search in map
- **How:** User types city name → API returns coordinates
- **Free:** Yes, no API key needed
- **Endpoint:** `https://nominatim.openstreetmap.org/search`

### **2. CartoDB Maps**
- **Used for:** Map tile layer
- **Style:** Dark theme matching app design
- **Endpoint:** `https://basemaps.cartocdn.com/dark_all/`

### **3. OSRM (OpenStreetMap Routing)**
- **Used for:** Calculate routes and directions
- **Returns:** Route coordinates, distance, duration
- **Endpoint:** `https://router.project-osrm.org/route/v1`

### **4. Geolocator (Flutter Package)**
- **Used for:** Get user's GPS location
- **Permissions:** Requests location permission from phone
- **Real-time:** Provides location stream

### **5. Firebase (if implemented)**
- **Used for:** Push notifications
- **Images:** Store and serve hostel photos

---

## 🎯 KEY FEATURES SUMMARY

| Feature | Frontend | Backend | External |
|---------|----------|---------|----------|
| Login/Signup | Login/Signup screens | Auth routes + JWT | - |
| Browse Hostels | Home screen | Hostel API | - |
| Search by Map | Map screen search bar | Hostel API | Nominatim |
| View Location | Routing screen | No backend needed | OSRM |
| Book Hostel | Booking screen | Booking API | - |
| View Bookings | Bookings screen | Booking API | - |
| Reviews | Details screen | Review API | - |
| Admin Dashboard | Admin screens | Admin APIs | - |
| Directions | Routing screen | No backend needed | OSRM |

---

## 💡 TALKING POINTS FOR SEMINAR

**"Our App Has:"**

1. ✅ **Two Data Sources** - Database hostels (verified) + OSM hostels (extended coverage)
2. ✅ **Interactive Map** - Real-time location, search, and hostel discovery
3. ✅ **User Authentication** - JWT tokens, secure passwords
4. ✅ **Booking System** - Date selection, price calculation, confirmation
5. ✅ **Admin Verification** - Hostels reviewed before going live
6. ✅ **Reviews & Ratings** - Community feedback system
7. ✅ **Navigation Integration** - Route planning with OSRM
8. ✅ **Notifications** - Booking confirmations and updates
9. ✅ **Cross-platform** - Works on Android and iOS with Flutter
10. ✅ **Real-time Location** - GPS tracking for nearby hostels

---

## 🎓 LIKELY QUESTIONS

**Q: What does the Map Screen do?**
A: Shows interactive map with user location, nearby hostels, search functionality, and hostel details on tap.

**Q: How do hostels appear on the map?**
A: Backend queries MongoDB for database hostels + Nominatim API for OSM hostels within 10km.

**Q: What happens when someone books?**
A: Frontend sends booking to backend → Backend creates booking record → Notification sent to user.

**Q: How does admin approval work?**
A: New hostels submitted to applications table → Wait for admin review → Admin approves/rejects.

**Q: Why two hostel sources?**
A: Database hostels are verified, OSM provides extended coverage for users to discover more places.

**Q: What's the booking process?**
A: Select hostel → Pick dates → Choose bed type → Confirm → Pay → Get booking ID.

**Q: How are routes calculated?**
A: OSRM API calculates path from user location to hostel location.

**Q: What prevents double booking?**
A: Backend checks dates don't overlap with existing bookings for same hostel.

---

## 📚 FILE STRUCTURE QUICK REFERENCE

```
Frontend:
├── lib/presentation/screens/
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── main_layout.dart
│   ├── home_screen.dart
│   ├── map_screen.dart ⭐
│   ├── hostel_details_screen.dart
│   ├── booking_screen.dart
│   ├── bookings_screen.dart
│   ├── profile_screen.dart
│   ├── routing_map_screen.dart
│   └── admin_*.dart
│
├── lib/data/providers/
│   ├── auth_provider.dart
│   └── hostel_provider.dart
│
└── lib/data/services/
    ├── location_service.dart
    └── api_service.dart

Backend:
├── src/routes/
│   ├── authRoutes.js
│   ├── hostelRoutes.js
│   ├── bookingRoutes.js
│   ├── hostelApplicationRoutes.js
│   └── notificationRoutes.js
│
├── src/controllers/
│   ├── authController.js
│   ├── hostelController.js
│   ├── bookingController.js
│   └── notificationController.js
│
├── src/models/
│   ├── User.js
│   ├── Hostel.js
│   ├── Booking.js
│   ├── Review.js
│   ├── Notification.js
│   └── HostelApplication.js
│
└── src/middlewares/
    └── authMiddleware.js
```

---

This breakdown should help you explain any section of the app! 🎉
