const Booking = require('../models/Booking');
const Hostel = require('../models/Hostel');
const Notification = require('../models/Notification');

// @desc    Create new booking (visit request)
// @route   POST /api/bookings
// @access  Private
const createBooking = async (req, res) => {
  const { hostelId, guestName, contactNumber, roomType, durationInMonths, message } = req.body;

  try {
    // Admin users are not allowed to create bookings
    if (req.user.role === 'admin') {
      return res.status(403).json({ message: 'Admins cannot create bookings. Only regular users can book hostels.' });
    }

    const mongoose = require('mongoose');
    if (!mongoose.Types.ObjectId.isValid(hostelId)) {
      return res.status(400).json({ message: 'Invalid hostel ID format' });
    }

    const hostel = await Hostel.findById(hostelId);

    if (!hostel) {
      return res.status(404).json({ message: 'Hostel not found' });
    }

    const totalAmount = hostel.rentPerMonth * (durationInMonths || 1);

    const booking = new Booking({
      userId: req.user._id,
      hostelId,
      guestName: guestName || req.user.name,
      contactNumber: contactNumber || req.user.phone || '',
      roomType: roomType || 'Standard',
      durationInMonths: durationInMonths || 1,
      message: message || '',
      totalAmount,
      status: 'Pending',
    });

    const createdBooking = await booking.save();
    const populated = await createdBooking.populate('hostelId', 'name address city rentPerMonth phone images');
    
    console.log(`New booking created: ${createdBooking._id} by user ${req.user._id}`);
    res.status(201).json(populated);
  } catch (error) {
    console.error('Create booking error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get logged-in user's bookings
// @route   GET /api/bookings/mybookings
// @access  Private
const getMyBookings = async (req, res) => {
  try {
    const bookings = await Booking.find({ userId: req.user._id })
      .populate('hostelId', 'name address city rentPerMonth phone images location')
      .sort({ createdAt: -1 });
    
    res.json(bookings);
  } catch (error) {
    console.error('Get my bookings error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get ALL bookings for hostels managed by this admin
// @route   GET /api/bookings/admin
// @access  Private/Admin
const getAdminBookings = async (req, res) => {
  try {
    let bookings;

    // Special case: admin@gmail.com sees EVERYTHING
    if (req.user.email === 'admin@gmail.com') {
      bookings = await Booking.find({})
        .populate('hostelId', 'name address city rentPerMonth')
        .populate('userId', 'name email phone')
        .populate('adminId', 'name email')
        .sort({ createdAt: -1 });
    } else {
      // Find all hostels this admin owns
      const adminHostels = await Hostel.find({ adminId: req.user._id }).select('_id name');
      const hostelIds = adminHostels.map(h => h._id);

      bookings = await Booking.find({ hostelId: { $in: hostelIds } })
        .populate('hostelId', 'name address city rentPerMonth')
        .populate('userId', 'name email phone')
        .populate('adminId', 'name email')
        .sort({ createdAt: -1 });
    }

    res.json(bookings);
  } catch (error) {
    console.error('Get admin bookings error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Admin approve/reject a booking and assign a slot
// @route   PUT /api/bookings/:id/status
// @access  Private/Admin
const updateBookingStatus = async (req, res) => {
  const { status, visitTime, adminNote, approvedSlot, checkinDate } = req.body;

  try {
    const booking = await Booking.findById(req.params.id).populate('hostelId', 'adminId name').populate('userId', 'name email');

    if (!booking) {
      return res.status(404).json({ message: 'Booking not found' });
    }

    // Ensure this admin owns the hostel, UNLESS they are admin@gmail.com
    if (booking.hostelId.adminId.toString() !== req.user._id.toString() && req.user.email !== 'admin@gmail.com') {
      return res.status(403).json({ message: 'Not authorized to update this booking' });
    }

    if (!['Approved', 'Rejected', 'Pending'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }

    // Update booking with admin response
    booking.status = status;
    booking.adminId = req.user._id;
    
    if (status === 'Approved') {
      booking.approvedAt = new Date();
      if (visitTime) booking.visitTime = visitTime;
      if (checkinDate) booking.checkinDate = checkinDate;
      if (approvedSlot) booking.approvedSlot = approvedSlot;
      booking.notificationSent = false; // Reset to ensure notification is sent
    }
    
    if (adminNote) booking.adminNote = adminNote;

    const updated = await booking.save();
    const populated = await updated.populate([
      { path: 'hostelId', select: 'name address city rentPerMonth' },
      { path: 'userId', select: 'name email phone' },
      { path: 'adminId', select: 'name email' }
    ]);
    
    // Create notification for user
    try {
      const hostelName = booking.hostelId.name || 'Hostel';
      let notifMessage, notifType, notifTitle;

      if (status === 'Approved') {
        notifType = 'BookingApproved';
        notifTitle = '✅ Booking Approved!';
        notifMessage = `Your booking for ${hostelName} has been approved! 🎉 Your assigned slot is: ${approvedSlot || 'TBD'}. Visit time: ${visitTime || 'To be confirmed'}`;
      } else if (status === 'Rejected') {
        notifType = 'BookingRejected';
        notifTitle = '❌ Booking Not Approved';
        notifMessage = `Your booking for ${hostelName} was not approved. ${adminNote ? `Reason: ${adminNote}` : 'Please contact us for more details.'}`;
      } else {
        notifType = 'BookingPending';
        notifTitle = '⏳ Booking Status Updated';
        notifMessage = `Your booking for ${hostelName} is still pending. ${adminNote || 'We will review it soon.'}`;
      }

      const notification = new Notification({
        userId: booking.userId,
        bookingId: booking._id,
        message: notifMessage,
        title: notifTitle,
        type: notifType,
        approvedSlot: approvedSlot || null,
        visitTime: visitTime || null,
        isRead: false
      });

      await notification.save();
      booking.notificationSent = true;
      await booking.save();
      console.log(`Notification sent to user ${booking.userId} for booking ${booking._id}`);
    } catch (notifError) {
      console.error('Error creating notification:', notifError);
      // Don't fail the entire operation if notification fails
    }
    
    console.log(`Booking ${req.params.id} updated to ${status} by admin ${req.user._id}`);
    res.json(populated);
  } catch (error) {
    console.error('Update booking status error:', error);
    res.status(500).json({ message: error.message });
  }
};

module.exports = { createBooking, getMyBookings, getAdminBookings, updateBookingStatus };
