const jwt = require('jsonwebtoken');
const User = require('../models/User');

const JWT_SECRET = process.env.JWT_SECRET || 'secret123';

/**
 * Generate a JWT token with configurable expiry.
 * @param {string} id - User ID
 * @param {boolean} rememberMe - If true, token lasts 30 days; otherwise 1 day
 */
const generateToken = (id, rememberMe = false) => {
  return jwt.sign({ id }, JWT_SECRET, {
    expiresIn: rememberMe ? '30d' : '1d',
  });
};

/**
 * Validate password strength.
 * Rules:
 *  - Minimum 6 characters
 *  - At least one uppercase letter (A-Z)
 *  - At least one lowercase letter (a-z)
 *  - At least one digit (0-9)
 *  - At least one special character (!@#$%^&* etc.)
 */
const validatePassword = (password) => {
  const errors = [];

  if (!password || password.length < 6) {
    errors.push('Password must be at least 6 characters long.');
  }
  if (!/[A-Z]/.test(password)) {
    errors.push('Password must contain at least one uppercase letter (A-Z).');
  }
  if (!/[a-z]/.test(password)) {
    errors.push('Password must contain at least one lowercase letter (a-z).');
  }
  if (!/[0-9]/.test(password)) {
    errors.push('Password must contain at least one number (0-9).');
  }
  if (!/[!@#$%^&*()\-_=+\[\]{};:'",.<>?/\\|`~]/.test(password)) {
    errors.push('Password must contain at least one special character (!@#$%^&* etc.).');
  }

  return errors;
};

/**
 * Validate email format.
 */
const validateEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

// @desc    Register a new user
// @route   POST /api/auth/signup
// @access  Public
const registerUser = async (req, res) => {
  const { name, email, password, phone, role = 'student' } = req.body;

  try {
    // --- Input validation ---
    if (!name || name.trim().length < 2) {
      return res.status(400).json({ message: 'Name must be at least 2 characters.' });
    }

    if (!email || !validateEmail(email)) {
      return res.status(400).json({ message: 'Please provide a valid email address.' });
    }

    if (!password) {
      return res.status(400).json({ message: 'Password is required.' });
    }

    const passwordErrors = validatePassword(password);
    if (passwordErrors.length > 0) {
      return res.status(400).json({
        message: 'Password does not meet requirements.',
        errors: passwordErrors,
      });
    }

    if (!phone || phone.trim().length === 0) {
      return res.status(400).json({ message: 'Phone number is required.' });
    }

    if (!/^[0-9]+$/.test(phone.trim())) {
      return res.status(400).json({ message: 'Phone number must contain only digits.' });
    }

    if (phone.trim().length !== 10) {
      return res.status(400).json({ message: 'Phone number must be exactly 10 digits.' });
    }

    // --- Check existing user ---
    const userExists = await User.findOne({ email: email.toLowerCase() });
    if (userExists) {
      return res.status(400).json({ message: 'An account with this email already exists.' });
    }

    // --- Create user (password hashed by model pre-save hook) ---
    const user = await User.create({
      name: name.trim(),
      email: email.toLowerCase().trim(),
      password,
      role,
      phone: phone || '',
    });

    if (user) {
      res.status(201).json({
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        token: generateToken(user._id, false),
        message: 'Account created successfully!',
      });
    } else {
      res.status(400).json({ message: 'Invalid user data. Please try again.' });
    }
  } catch (error) {
    console.error('Registration error:', error.message);
    console.error('Error details:', error);
    res.status(500).json({ message: 'Server error. Please try again later.', error: error.message });
  }
};

// @desc    Auth user & get token
// @route   POST /api/auth/login
// @access  Public
const loginUser = async (req, res) => {
  const { email, password, rememberMe } = req.body;

  try {
    // --- Input validation ---
    if (!email || !validateEmail(email)) {
      return res.status(400).json({ message: 'Please provide a valid email address.' });
    }

    if (!password) {
      return res.status(400).json({ message: 'Please provide your password.' });
    }

    // --- Authenticate user ---
    const user = await User.findOne({ email: email.toLowerCase() });

    if (user && (await user.matchPassword(password))) {
      const remember = rememberMe === true || rememberMe === 'true';
      res.json({
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        token: generateToken(user._id, remember),
        rememberMe: remember,
        message: 'Login successful!',
      });
    } else {
      res.status(401).json({ message: 'Invalid email or password. Please try again.' });
    }
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Server error. Please try again later.' });
  }
};

// @desc    Get current logged-in user (token verification)
// @route   GET /api/auth/me
// @access  Private
const getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }
    res.json({
      _id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      phone: user.phone || '',
    });
  } catch (error) {
    console.error('GetMe error:', error);
    res.status(500).json({ message: 'Server error.' });
  }
};

// @desc    Update user profile (name, phone)
// @route   PUT /api/auth/profile
// @access  Private
const updateProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    if (req.body.name) user.name = req.body.name.trim();
    if (req.body.phone !== undefined) {
      const phone = req.body.phone.trim();
      
      // Validate phone
      if (phone && phone.length > 0) {
        if (!/^[0-9]+$/.test(phone)) {
          return res.status(400).json({ message: 'Phone number must contain only digits.' });
        }
        if (phone.length !== 10) {
          return res.status(400).json({ message: 'Phone number must be exactly 10 digits.' });
        }
      }
      
      user.phone = phone;
    }

    const updated = await user.save();
    res.json({ _id: updated._id, name: updated.name, email: updated.email, role: updated.role, phone: updated.phone });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Change password
// @route   PUT /api/auth/change-password
// @access  Private
const changePassword = async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  try {
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const isMatch = await user.matchPassword(currentPassword);
    if (!isMatch) return res.status(400).json({ message: 'Current password is incorrect' });

    const errors = validatePassword(newPassword);
    if (errors.length > 0) return res.status(400).json({ message: errors[0] });

    user.password = newPassword;
    await user.save();
    res.json({ message: 'Password updated successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = { registerUser, loginUser, getMe, updateProfile, changePassword };
