const mongoose = require('mongoose');

const hostelApplicationSchema = new mongoose.Schema({
  // Owner's hostel info
  ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  hostelId: { type: mongoose.Schema.Types.ObjectId, ref: 'Hostel', required: true },
  
  // Hostel details at time of application
  hostelName: { type: String, required: true },
  ownerName: { type: String, required: true },
  ownerEmail: { type: String, required: true },
  ownerPhone: { type: String, required: true },
  location: { type: String, required: true }, // Address
  
  // Application review
  status: { type: String, enum: ['pending', 'reviewed', 'approved', 'rejected'], default: 'pending' },
  reviewedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null }, // Admin who reviewed
  feedback: { type: String, default: '' }, // Admin's review feedback
  reviewedAt: { type: Date, default: null },
  
  submittedAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
}, { timestamps: true });

const HostelApplication = mongoose.model('HostelApplication', hostelApplicationSchema);
module.exports = HostelApplication;
