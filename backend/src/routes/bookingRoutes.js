const express = require('express');
const { createBooking, getMyBookings, getAdminBookings, updateBookingStatus } = require('../controllers/bookingController');
const { protect, admin } = require('../middlewares/authMiddleware');

const router = express.Router();

// More specific routes BEFORE generic ones
// Admin routes (specific)
router.get('/admin', protect, admin, getAdminBookings);

// User routes
router.get('/mybookings', protect, getMyBookings);
router.post('/', protect, createBooking);

// Generic routes (specific parameter routes after named routes)
router.put('/:id/status', protect, admin, updateBookingStatus);

module.exports = router;
