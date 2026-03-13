require('dotenv').config();
const express = require('express');
const cors = require('cors');
const connectDB = require('./src/config/db');

// Import routes
const authRoutes = require('./src/routes/authRoutes');
const hostelRoutes = require('./src/routes/hostelRoutes');
const bookingRoutes = require('./src/routes/bookingRoutes');

const app = express();

// Connect Database
connectDB();

// Middleware
app.use(cors()); // Allows connections from other devices
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/hostels', hostelRoutes);
app.use('/api/bookings', bookingRoutes);

app.get('/', (req, res) => {
  res.send('Hostel Management API is running...');
});

const PORT = process.env.PORT || 5000;

// Explicitly listen on 0.0.0.0 to allow external network connections
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on http://10.223.111.90:${PORT}`);
});
