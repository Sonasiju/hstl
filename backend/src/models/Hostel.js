const mongoose = require('mongoose');

const hostelSchema = new mongoose.Schema({
  adminId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true },
  description: { type: String, required: true },
  address: { type: String, required: true },
  city: { type: String, required: true },
  phone: { type: String, required: true },
  location: {
    lat: { type: Number, required: true },
    lng: { type: Number, required: true }
  },
  rentPerMonth: { type: Number, required: true },
  pricePerNight: { type: Number },
  facilities: [{ type: String }], // e.g., 'WiFi', 'AC', 'Food', 'Laundry'
  type: { type: String, enum: ['boys', 'girls', 'coed'], default: 'coed' },
  ratings: { type: Number, default: 0 },
  numReviews: { type: Number, default: 0 },
  totalRooms: { type: Number, required: true },
  availableRooms: { type: Number, required: true },
  images: [{ type: String }], // List of URLs
  
  // Approval status
  approvalStatus: { type: String, enum: ['pending', 'reviewed', 'approved', 'rejected'], default: 'pending' },
  reviewedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  reviewNotes: { type: String, default: '' },
  reviewedAt: { type: Date, default: null },
  isActive: { type: Boolean, default: false } // Only active (approved) hostels show in browse
}, { timestamps: true });

// Geospatial indexing for distance searches
hostelSchema.index({ location: '2dsphere' });

const Hostel = mongoose.model('Hostel', hostelSchema);
module.exports = Hostel;
