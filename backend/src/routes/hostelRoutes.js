const express = require('express');
const { getHostels, getMyHostels, getHostelById, createHostel, deleteHostel, updateHostel } = require('../controllers/hostelController');
const { protect, admin } = require('../middlewares/authMiddleware');

const router = express.Router();

router.get('/my', protect, admin, getMyHostels);        // Admin's own hostels
router.route('/')
  .get(getHostels)
  .post(protect, admin, createHostel);

router.route('/:id')
  .get(getHostelById)
  .put(protect, admin, updateHostel)
  .delete(protect, admin, deleteHostel);

module.exports = router;
