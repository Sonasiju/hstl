# Hostel Management Mobile Application

A production-ready application for finding and booking hostels. 
The application implements clean architecture and provides robust Backend APIs alongside modern Flutter screens.

## 🗂 Project Structure

```text
hstl/
├── backend/
│   ├── package.json
│   ├── server.js               # Entry point
│   ├── seed.js                 # Sample data seeder
│   └── src/
│       ├── config/
│       │   └── db.js           # MongoDB connection
│       ├── controllers/
│       │   ├── authController.js
│       │   ├── bookingController.js
│       │   └── hostelController.js
│       ├── middlewares/
│       │   └── authMiddleware.js
│       ├── models/
│       │   ├── Booking.js
│       │   ├── Complaint.js
│       │   ├── Hostel.js
│       │   ├── Notification.js
│       │   ├── Payment.js
│       │   ├── Review.js
│       │   └── User.js
│       └── routes/
│           ├── authRoutes.js
│           ├── bookingRoutes.js
│           └── hostelRoutes.js
└── frontend/
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── core/
        ├── data/
        │   └── providers/
        │       └── hostel_provider.dart
        └── presentation/
            └── screens/
                ├── home_screen.dart
                ├── hostel_details_screen.dart
                └── main_layout.dart
```

## ⚙️ Running the Backend

1. Navigate to the `backend` folder:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Run the seed script to import sample data (requires MongoDB running):
   ```bash
   node seed.js
   ```
4. Start the server:
   ```bash
   npm run dev
   ```

## 📱 Running the Frontend

1. Navigate to the `frontend` folder:
   ```bash
   cd frontend
   ```
2. Build iOS/Android:
   ```bash
   flutter pub get
   flutter run
   ```

## 📌 Features Implemented Today
- Scalable MongoDB Schema with 8 Collections.
- Secure Auth, Geolocation-ready Hostels APIs, and Booking engine APIs.
- Flutter Modern UI mimicking Airbnb.
- Fallback mock data attached via Riverpod/Provider approach.
