const Hostel = require('../models/Hostel');

// @desc    Get all hostels (public, with optional filters)
// @route   GET /api/hostels
// @access  Public
const getHostels = async (req, res) => {
  try {
    const { lat, lng, maxDistance, priceMin, priceMax, type, limit, city, search } = req.query;

    // Show all hostels as requested for the Discover page
    let query = {};

    if (type) query.type = type;

    // City or area text search
    if (city && city.trim()) {
      query.city = { $regex: city.trim(), $options: 'i' };
    }
    if (search && search.trim()) {
      query.$or = [
        { name: { $regex: search.trim(), $options: 'i' } },
        { city: { $regex: search.trim(), $options: 'i' } },
        { address: { $regex: search.trim(), $options: 'i' } },
        { description: { $regex: search.trim(), $options: 'i' } },
      ];
    }

    if (priceMin || priceMax) {
      query.rentPerMonth = {};
      if (priceMin) query.rentPerMonth.$gte = Number(priceMin);
      if (priceMax) query.rentPerMonth.$lte = Number(priceMax);
    }

    if (lat && lng) {
      // Use $near for geospatial search (requires 2dsphere index on location.coordinates)
      // Since location is stored as {lat, lng} flat (not GeoJSON), we fall back to in-memory sort
      // Just fetch all matching and sort by distance in JS
      const allHostels = await Hostel.find(query).limit(Number(limit) || 100);
      
      const userLat = parseFloat(lat);
      const userLng = parseFloat(lng);
      const maxDist = maxDistance ? Number(maxDistance) : 10; // km

      // Calculate distance but DO NOT filter by maxDist for database hostels
      const withDist = allHostels.map(h => {
        if (!h.location || h.location.lat == null || h.location.lng == null) {
          return { hostel: h, dist: 99999 };
        }
        const dLat = (h.location.lat - userLat) * Math.PI / 180;
        const dLng = (h.location.lng - userLng) * Math.PI / 180;
        const a = Math.sin(dLat/2)**2 +
          Math.cos(userLat * Math.PI/180) * Math.cos(h.location.lat * Math.PI/180) * Math.sin(dLng/2)**2;
        const dist = 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); // km
        return { hostel: h, dist };
      });

      withDist.sort((a, b) => a.dist - b.dist);

      // If no results at all, fallback
      if (withDist.length === 0) {
        const fallback = await Hostel.find({}).limit(Number(limit) || 50);
        return res.json(fallback);
      }

      return res.json(withDist.map(x => ({ ...x.hostel.toObject(), distance: x.dist })));
    }

    const hostels = await Hostel.find(query).limit(Number(limit) || 50);
    res.json(hostels);
  } catch (error) {
    console.error('getHostels error:', error);
    res.status(500).json({ message: error.message });
  }
};


// @desc    Get hostels belonging to the logged-in admin
// @route   GET /api/hostels/my
// @access  Private/Admin
const getMyHostels = async (req, res) => {
  try {
    const hostels = await Hostel.find({ adminId: req.user._id });
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
    const { name, description, address, city, phone, location, rentPerMonth, pricePerNight, facilities, type, totalRooms } = req.body;

    const hostel = new Hostel({
      adminId: req.user._id,
      name,
      description,
      address,
      city,
      phone,
      location,
      rentPerMonth: rentPerMonth || pricePerNight * 30,
      pricePerNight: pricePerNight || rentPerMonth / 30,
      facilities,
      type: type || 'coed',
      totalRooms,
      availableRooms: totalRooms,
    });

    const createdHostel = await hostel.save();
    res.status(201).json(createdHostel);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Delete a hostel (Admin only – must own the hostel)
// @route   DELETE /api/hostels/:id
// @access  Private/Admin
const deleteHostel = async (req, res) => {
  try {
    const hostel = await Hostel.findById(req.params.id);

    if (!hostel) return res.status(404).json({ message: 'Hostel not found' });

    if (hostel.adminId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized to delete this hostel' });
    }

    await hostel.deleteOne();
    res.json({ message: 'Hostel removed' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update a hostel (Admin only – must own the hostel)
// @route   PUT /api/hostels/:id
// @access  Private/Admin
const updateHostel = async (req, res) => {
  try {
    const hostel = await Hostel.findById(req.params.id);

    if (!hostel) return res.status(404).json({ message: 'Hostel not found' });

    if (hostel.adminId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized to edit this hostel' });
    }

    const fields = ['name', 'description', 'address', 'city', 'phone', 'rentPerMonth', 'facilities', 'type', 'totalRooms', 'availableRooms'];
    fields.forEach(f => { if (req.body[f] !== undefined) hostel[f] = req.body[f]; });

    const updated = await hostel.save();
    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = { getHostels, getMyHostels, getHostelById, createHostel, deleteHostel, updateHostel };
