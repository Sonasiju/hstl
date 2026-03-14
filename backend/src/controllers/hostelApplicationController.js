const HostelApplication = require('../models/HostelApplication');
const Hostel = require('../models/Hostel');
const Notification = require('../models/Notification');

// @desc    Submit hostel for review (owner submits their hostel)
// @route   POST /api/hostel-applications
// @access  Private
const submitHostelApplication = async (req, res) => {
  try {
    const { hostelId } = req.body;

    // Verify hostel exists
    const hostel = await Hostel.findById(hostelId);
    if (!hostel) {
      return res.status(404).json({ message: 'Hostel not found' });
    }

    // Verify user owns this hostel
    if (hostel.adminId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'You do not own this hostel' });
    }

    // Check if already has a pending application
    const existingApp = await HostelApplication.findOne({
      hostelId,
      status: 'pending'
    });

    if (existingApp) {
      return res.status(400).json({ 
        message: 'This hostel already has a pending application' 
      });
    }

    // Create application
    const application = new HostelApplication({
      ownerId: req.user._id,
      hostelId,
      hostelName: hostel.name,
      ownerName: req.user.name,
      ownerEmail: req.user.email,
      ownerPhone: req.user.phone || '',
      location: `${hostel.address}, ${hostel.city}`,
      status: 'pending'
    });

    const savedApp = await application.save();
    const populated = await savedApp.populate('ownerId', 'name email phone');

    console.log(`Hostel application submitted for ${hostel.name} by ${req.user.name}`);
    res.status(201).json({
      message: 'Hostel application submitted successfully',
      application: populated
    });
  } catch (error) {
    console.error('Submit hostel application error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get all hostel applications (for admin review)
// @route   GET /api/hostel-applications
// @access  Private/Admin
const getHostelApplications = async (req, res) => {
  try {
    const { status } = req.query; // Optional filter by status

    let filter = {};
    if (status) {
      filter.status = status;
    }

    const applications = await HostelApplication.find(filter)
      .populate('ownerId', 'name email phone')
      .populate('hostelId', 'name address city rentPerMonth')
      .populate('reviewedBy', 'name email')
      .sort({ submittedAt: -1 });

    res.json(applications);
  } catch (error) {
    console.error('Get hostel applications error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Review hostel application (approve/reject)
// @route   PUT /api/hostel-applications/:id/review
// @access  Private/Admin
const reviewHostelApplication = async (req, res) => {
  try {
    const { status, feedback } = req.body;

    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({ 
        message: 'Status must be "approved" or "rejected"' 
      });
    }

    const application = await HostelApplication.findById(req.params.id)
      .populate('ownerId', 'name email')
      .populate('hostelId', 'name adminId');

    if (!application) {
      return res.status(404).json({ message: 'Application not found' });
    }

    // Update application
    application.status = 'reviewed';
    application.reviewedBy = req.user._id;
    application.feedback = feedback || '';
    application.reviewedAt = new Date();

    // Update hostel status
    const hostel = await Hostel.findById(application.hostelId);
    if (status === 'approved') {
      hostel.approvalStatus = 'approved';
      hostel.isActive = true;
      console.log(`Hostel "${hostel.name}" approved by admin ${req.user.name}`);
    } else {
      hostel.approvalStatus = 'rejected';
      hostel.isActive = false;
      console.log(`Hostel "${hostel.name}" rejected by admin ${req.user.name}`);
    }
    hostel.reviewedBy = req.user._id;
    hostel.reviewNotes = feedback || '';
    hostel.reviewedAt = new Date();

    await hostel.save();
    const updatedApp = await application.save();

    // Create notification for hostel owner
    try {
      const notifType = status === 'approved' ? 'HostelApproved' : 'HostelRejected';
      const notifTitle = status === 'approved' 
        ? '✅ Your Hostel is Approved!' 
        : '❌ Hostel Application Rejected';
      const notifMessage = status === 'approved'
        ? `Great! Your hostel "${hostel.name}" has been approved and is now live. Users can now book rooms at your hostel!`
        : `Your hostel "${hostel.name}" application was reviewed. ${feedback ? `Feedback: ${feedback}` : 'Please contact admin for details.'}`;

      const notification = new Notification({
        userId: application.ownerId,
        message: notifMessage,
        title: notifTitle,
        type: notifType,
        isRead: false
      });

      await notification.save();
    } catch (notifError) {
      console.error('Error creating notification:', notifError);
      // Don't fail the entire operation
    }

    const populated = await updatedApp.populate([
      { path: 'ownerId', select: 'name email phone' },
      { path: 'hostelId', select: 'name address city' },
      { path: 'reviewedBy', select: 'name email' }
    ]);

    res.json({
      message: `Hostel application ${status}`,
      application: populated
    });
  } catch (error) {
    console.error('Review hostel application error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get single application details
// @route   GET /api/hostel-applications/:id
// @access  Private
const getApplicationDetails = async (req, res) => {
  try {
    const application = await HostelApplication.findById(req.params.id)
      .populate('ownerId', 'name email phone')
      .populate('hostelId', 'name address city rentPerMonth facilities images')
      .populate('reviewedBy', 'name email');

    if (!application) {
      return res.status(404).json({ message: 'Application not found' });
    }

    res.json(application);
  } catch (error) {
    console.error('Get application details error:', error);
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  submitHostelApplication,
  getHostelApplications,
  reviewHostelApplication,
  getApplicationDetails
};
