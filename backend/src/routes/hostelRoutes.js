const express = require('express');
const { getHostels, getHostelById, createHostel } = require('../controllers/hostelController');
const { protect, admin } = require('../middlewares/authMiddleware');

const router = express.Router();

router.route('/')
  .get(getHostels)
  .post(protect, admin, createHostel);

router.route('/:id')
  .get(getHostelById);

module.exports = router;
