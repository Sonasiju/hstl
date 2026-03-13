const Booking = require('../models/Booking');
const Hostel = require('../models/Hostel');

// @desc    Create new booking
// @route   POST /api/bookings
// @access  Private
const createBooking = async (req, res) => {
  const { hostelId, roomType, durationInMonths } = req.body;

  try {
    const hostel = await Hostel.findById(hostelId);

    if (!hostel) {
      return res.status(404).json({ message: 'Hostel not found' });
    }

    if (hostel.availableRooms <= 0) {
      return res.status(400).json({ message: 'No rooms available at this time' });
    }

    const totalAmount = hostel.rentPerMonth * durationInMonths;

    const booking = new Booking({
      userId: req.user._id,
      hostelId,
      roomType,
      durationInMonths,
      totalAmount
    });

    const createdBooking = await booking.save();

    // Update available rooms
    hostel.availableRooms -= 1;
    await hostel.save();

    res.status(201).json(createdBooking);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get logged in user bookings
// @route   GET /api/bookings/mybookings
// @access  Private
const getMyBookings = async (req, res) => {
  try {
    const bookings = await Booking.find({ userId: req.user._id }).populate('hostelId', 'name location images');
    res.json(bookings);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = { createBooking, getMyBookings };
