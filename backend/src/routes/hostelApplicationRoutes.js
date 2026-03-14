const express = require('express');
const {
  submitHostelApplication,
  getHostelApplications,
  reviewHostelApplication,
  getApplicationDetails
} = require('../controllers/hostelApplicationController');
const { protect, admin } = require('../middlewares/authMiddleware');

const router = express.Router();

// Owner routes
router.post('/', protect, submitHostelApplication);

// Admin routes
router.get('/', protect, admin, getHostelApplications);
router.get('/:id', protect, getApplicationDetails);
router.put('/:id/review', protect, admin, reviewHostelApplication);

module.exports = router;
