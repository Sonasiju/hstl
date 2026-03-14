const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('./src/models/User');
const Hostel = require('./src/models/Hostel');
const connectDB = require('./src/config/db');

dotenv.config();

connectDB();

const importData = async () => {
  try {
    await User.deleteMany();
    await Hostel.deleteMany();

    const createdUsers = await User.insertMany([
      {
        name: 'Admin User',
        email: 'admin@hostel.com',
        password: 'Password@123', // In real system, this will be hashed via prev hook, but seed bypasses save unless manually managed. Let's rely on simple seed for now.
        role: 'admin'
      },
      {
        name: 'Test Student',
        email: 'student@test.com',
        password: 'Password@123',
        role: 'student'
      }
    ]);

    const adminUser = createdUsers[0]._id;

    const sampleHostels = [
      {
        name: 'Sunrise Boys Hostel',
        description: 'Modern boys hostel with all basic amenities including fast WiFi.',
        address: '123 University St, Tech City',
        location: {
          lat: 12.9715987,
          lng: 77.5945627
        },
        rentPerMonth: 5000,
        facilities: ['WiFi', 'Food', 'Laundry'],
        type: 'boys',
        city: 'Bangalore',
        phone: '1234567890',
        totalRooms: 50,
        availableRooms: 20,
        adminId: adminUser,
        images: ['https://images.unsplash.com/photo-1555854877-bab0e564b8d5']
      },
      {
        name: 'Harmony Girls PG',
        description: 'Safe and secure living space for girls. Near to primary tech parks.',
        address: '456 Rose Garden, Tech City',
        location: {
          lat: 12.9351929,
          lng: 77.6244806
        },
        rentPerMonth: 6500,
        facilities: ['AC', 'WiFi', 'Food', 'Security'],
        type: 'girls',
        city: 'Bangalore',
        phone: '0987654321',
        totalRooms: 30,
        availableRooms: 5,
        adminId: adminUser,
        images: ['https://images.unsplash.com/photo-1522771731478-4ea767a14a24']
      }
    ];

    await Hostel.insertMany(sampleHostels);

    console.log('Data Imported!');
    process.exit();
  } catch (error) {
    console.error(`Error: ${error}`);
    process.exit(1);
  }
};

importData();
