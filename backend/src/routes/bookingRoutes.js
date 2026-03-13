const express = require('express');
const { createBooking, getMyBookings } = require('../controllers/bookingController');
const { protect } = require('../middlewares/authMiddleware');

const router = express.Router();

router.route('/')
  .post(protect, createBooking);

router.route('/mybookings')
  .get(protect, getMyBookings);

module.exports = router;
