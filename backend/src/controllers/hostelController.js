const Hostel = require('../models/Hostel');

// @desc    Get all hostels with optional filtering and distance
// @route   GET /api/hostels
// @access  Public
const getHostels = async (req, res) => {
  try {
    const { lat, lng, maxDistance, priceMin, priceMax, type, limit } = req.query;

    let query = {};

    // Filter by type (boys, girls, coed)
    if (type) {
      query.type = type;
    }

    // Filter by price
    if (priceMin || priceMax) {
      query.rentPerMonth = {};
      if (priceMin) query.rentPerMonth.$gte = Number(priceMin);
      if (priceMax) query.rentPerMonth.$lte = Number(priceMax);
    }

    // Geospatial search if lat and lng provided
    if (lat && lng) {
      query.location = {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(lng), parseFloat(lat)]
          },
          // Convert maxDistance from km to meters (default 10km)
          $maxDistance: maxDistance ? Number(maxDistance) * 1000 : 10000
        }
      };
    }

    let hostels = await Hostel.find(query).limit(Number(limit) || 20);

    // If no results, try without geo query just to show something
    if (hostels.length === 0 && query.location) {
      delete query.location;
      hostels = await Hostel.find(query).limit(Number(limit) || 20);
    }

    res.json(hostels);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get hostel by ID
// @route   GET /api/hostels/:id
// @access  Public
const getHostelById = async (req, res) => {
  try {
    const hostel = await Hostel.findById(req.params.id);
    if (hostel) {
      res.json(hostel);
    } else {
      res.status(404).json({ message: 'Hostel not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Create a hostel (Admin only)
// @route   POST /api/hostels
// @access  Private/Admin
const createHostel = async (req, res) => {
  try {
    const { name, description, address, location, rentPerMonth, facilities, type, totalRooms } = req.body;
    
    const hostel = new Hostel({
      adminId: req.user._id,
      name,
      description,
      address,
      location,
      rentPerMonth,
      facilities,
      type,
      totalRooms,
      availableRooms: totalRooms, // initially all rooms available
    });

    const createdHostel = await hostel.save();
    res.status(201).json(createdHostel);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = { getHostels, getHostelById, createHostel };
