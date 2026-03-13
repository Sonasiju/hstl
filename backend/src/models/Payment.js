const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  hostelId: { type: mongoose.Schema.Types.ObjectId, ref: 'Hostel', required: true },
  amount: { type: Number, required: true },
  status: { type: String, enum: ['Paid', 'Pending', 'Failed'], default: 'Pending' },
  transactionId: { type: String }, // Can be integrated with Stripe/Razorpay
  paymentDate: { type: Date, default: Date.now },
  description: { type: String }
}, { timestamps: true });

const Payment = mongoose.model('Payment', paymentSchema);
module.exports = Payment;
