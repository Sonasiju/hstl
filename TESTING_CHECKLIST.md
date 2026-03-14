# Quick Testing Checklist

## ✅ Pre-Testing Setup
- [ ] Backend server restarted (`npm start` in backend folder)
- [ ] Database connection verified
- [ ] Flutter app restarted/rebuilt
- [ ] Clear any cached tokens if needed

## ✅ Test User Registration
- [ ] Create test user account
- [ ] Note down credentials
- [ ] Verify user is logged in

## ✅ Test Admin Account
- [ ] Use existing admin account or create new one
- [ ] Verify admin has `role: "admin"` in database
- [ ] Login as admin

## ✅ Test Booking Creation (As User)
- [ ] Navigate to Browse Hostels
- [ ] Select a hostel
- [ ] Fill booking form with:
  - [ ] Guest Name: "Test Guest"
  - [ ] Contact: "9876543210"
  - [ ] Room Type: "Standard"
  - [ ] Duration: "1" month
  - [ ] Message: "Testing"
- [ ] Click Submit
- [ ] Verify booking appears in "My Bookings" with status "PENDING"

## ✅ Test Admin Views Bookings
- [ ] Switch to admin account
- [ ] Go to "Manage Bookings" tab
- [ ] **CRITICAL CHECK:** Should NOT get 404 error
- [ ] Should see the user's booking in the list
- [ ] Click on the booking card

## ✅ Test Booking Approval (As Admin)
- [ ] Click "Approve" button on booking
- [ ] In approval dialog:
  - [ ] Enter Visit Time: "15 April 2026, 10:00 AM"
  - [ ] Enter Slot: "Room 101"
  - [ ] Enter Optional Note: "Welcome!"
- [ ] Click "Approve" button
- [ ] **IMPORTANT:** Check success message shows slot:
  - Should say: "✅ Booking approved with slot: Room 101"
- [ ] Verify booking list refreshes

## ✅ Test User Sees Approved Booking
- [ ] Switch back to user account
- [ ] Go to "My Bookings"
- [ ] Refresh the page (pull down to refresh)
- [ ] Booking should now show:
  - [ ] Status: "APPROVED" (green with checkmark)
  - [ ] Yellow section showing:
    - [ ] "Visit Time Allotted: 15 April 2026, 10:00 AM"
    - [ ] "Assigned Slot: Room 101"

## ✅ Test Notifications (API)
- [ ] Open Postman or API testing tool
- [ ] Make request:
  ```
  GET http://your-ip:5000/api/notifications
  Headers: Authorization: Bearer <user_token>
  ```
- [ ] Should receive array with notification containing:
  - [ ] `type: "BookingApproved"`
  - [ ] `message`: Contains hostel name and slot info
  - [ ] `title: "✅ Booking Approved!"`
  - [ ] `approvedSlot: "Room 101"`

## ✅ Test Booking Rejection (As Admin)
- [ ] Create another test booking (as user)
- [ ] As admin, go to Manage Bookings
- [ ] Click "Reject" on the new booking
- [ ] Enter Reason: "No availability currently"
- [ ] Click "Reject"
- [ ] Verify success shows: "❌ Booking rejected"
- [ ] Switch to user, refresh "My Bookings"
- [ ] Booking should show:
  - [ ] Status: "REJECTED" (red with X icon)
  - [ ] Reason below: "No availability currently"

## ✅ Test Route Ordering (Backend Validation)
- [ ] In Postman, test these endpoints as admin with valid token:
  - [ ] `GET /api/bookings/admin` - Should return bookings (NOT 404)
  - [ ] `GET /api/bookings/mybookings` - Should return bookings
  - [ ] `PUT /api/bookings/<invalid_id>/status` - Should return 404 (not found)
  - [ ] Verify order matters: specific routes before generic

## ✅ Final Checks
- [ ] No 404 errors when loading admin bookings
- [ ] Slots are saved and displayed correctly
- [ ] Notifications are created automatically
- [ ] Frontend displays slot and visit time nicely
- [ ] Status colors are correct (Green=Approved, Red=Rejected, Orange=Pending)

---

## 🚀 If Any Tests Fail

### 404 Error Still Appearing?
1. Restart backend server
2. Check `bookingRoutes.js` - verify `/admin` comes before `/:id`
3. Check auth middleware - verify `return` statements after errors
4. Check server.js - verify `notificationRoutes` is imported/registered

### Slot Not Showing?
1. Verify JSON request includes `approvedSlot` field
2. Check database - confirm slot is saved in Booking
3. Check frontend - verify approvedSlot variable is being read from API response

### Notifications Not Created?
1. Check backend logs for notification creation errors
2. Verify Notification model is imported in controller
3. Check if userId in booking matches request user
4. Check MongoDB - verify notification is saved

### Route Not Found?
1. Verify new notificationRoutes.js file exists in `src/routes/`
2. Check server.js imports: `const notificationRoutes = require('./src/routes/notificationRoutes');`
3. Check server.js routing: `app.use('/api/notifications', notificationRoutes);`

---

## 💡 Pro Testing Tips

- Use Postman/Insomnia to test APIs directly
- Keep backend console open to see logs
- Check MongoDB Compass to verify data is saved
- Clear app cache if seeing stale data
- Use different user/admin accounts for testing
- Test with multiple bookings

---

**Last Updated:** March 2026
**Time to Complete:** ~10-15 minutes
