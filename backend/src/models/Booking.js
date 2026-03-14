const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  hostelId: { type: mongoose.Schema.Types.ObjectId, ref: 'Hostel', required: true },
  
  // Guest-provided details
  guestName: { type: String, required: true },
  contactNumber: { type: String, required: true },
  roomType: { type: String, default: 'Standard' },
  durationInMonths: { type: Number, required: true },
  message: { type: String, default: '' },

  totalAmount: { type: Number, required: true },

  // Admin response with slot information
  status: { type: String, enum: ['Pending', 'Approved', 'Rejected'], default: 'Pending' },
  approvedAt: { type: Date, default: null },
  visitTime: { type: String, default: null }, // Admin sets this when approving
  checkinDate: { type: Date, default: null }, // Actual check-in date when approved
  approvedSlot: { type: String, default: null }, // e.g., "Room 101", "Bed A", etc.
  adminNote: { type: String, default: '' },
  adminId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null }, // Admin who approved

  paymentStatus: { type: String, enum: ['Paid', 'Pending'], default: 'Pending' },
  notificationSent: { type: Boolean, default: false }, // Track if user was notified
  bookingDate: { type: Date, default: Date.now }
}, { timestamps: true });

const Booking = mongoose.model('Booking', bookingSchema);
module.exports = Booking;
