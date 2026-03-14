const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  bookingId: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', default: null },
  message: { type: String, required: true },
  type: { type: String, enum: ['BookingApproved', 'BookingRejected', 'BookingPending', 'PaymentReminder', 'General', 'Update'], default: 'General' },
  title: { type: String, default: '' },
  approvedSlot: { type: String, default: null }, // For booking approval notifications
  visitTime: { type: String, default: null }, // For booking approval notifications
  isRead: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
}, { timestamps: true });

const Notification = mongoose.model('Notification', notificationSchema);
module.exports = Notification;
