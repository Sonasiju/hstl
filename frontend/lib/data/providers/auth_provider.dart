import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/api_config.dart';

class AuthProvider with ChangeNotifier {

  // ─── STATE ─────────────────────────────────────────────
  bool _isAuthenticated = false;
  bool _isLoading = false;

  String? _token;
  String? _userId;
  String? _userName;
  String? _userEmail;
  String? _userRole;
  String? _userPhone;
  String? _errorMessage;

  // ─── GETTERS ───────────────────────────────────────────
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get token => _token;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userRole => _userRole;
  String? get userPhone => _userPhone;
  String? get errorMessage => _errorMessage;

  // Use dynamic base URL from API config
  String get _baseUrl => ApiConfig.getConfiguredUrl();
  static const String _tokenKey = 'auth_token';
  static const String _rememberMeKey = 'remember_me';

  // ─── PASSWORD VALIDATION ───────────────────────────────
  static List<String> validatePassword(String password) {
    final errors = <String>[];

    if (password.length < 6) {
      errors.add('At least 6 characters');
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      errors.add('At least one uppercase letter (A-Z)');
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      errors.add('At least one lowercase letter (a-z)');
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      errors.add('At least one number (0-9)');
    }

    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
      errors.add('At least one special character (!@#\$%^&*)');
    }

    return errors;
  }

  // ─── EMAIL VALIDATION ──────────────────────────────────
  static bool isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  // ─── AUTO LOGIN ────────────────────────────────────────
  Future<bool> tryAutoLogin() async {

    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

    if (!rememberMe) return false;

    final savedToken = prefs.getString(_tokenKey);

    if (savedToken == null || savedToken.isEmpty) return false;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $savedToken',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {

        final data = json.decode(response.body);

        _token = savedToken;
        _userId = data['_id'];
        _userName = data['name'];
        _userEmail = data['email'];
        _userRole = data['role'];
        _userPhone = data['phone'] ?? '';

        _isAuthenticated = true;

        notifyListeners();
        return true;
      } else {

        await _clearSavedToken();
        return false;
      }
    } catch (e) {
      debugPrint('Auto-login error: $e');
      return false;
    }
  }

  // ─── TOKEN STORAGE ─────────────────────────────────────
  Future<void> _clearSavedToken() async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_rememberMeKey);
  }

  Future<void> _saveToken(String token, bool rememberMe) async {

    final prefs = await SharedPreferences.getInstance();

    if (rememberMe) {
      await prefs.setString(_tokenKey, token);
      await prefs.setBool(_rememberMeKey, true);
    } else {
      await prefs.remove(_tokenKey);
      await prefs.setBool(_rememberMeKey, false);
    }
  }

  // ─── LOGIN ─────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {

    _errorMessage = null;

    if (email.isEmpty) {
      _errorMessage = 'Please enter your email address.';
      notifyListeners();
      return false;
    }

    if (!isValidEmail(email)) {
      _errorMessage = 'Please enter a valid email address.';
      notifyListeners();
      return false;
    }

    if (password.isEmpty) {
      _errorMessage = 'Please enter your password.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {

      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email.trim().toLowerCase(),
          'password': password,
          'rememberMe': rememberMe,
        }),
      ).timeout(const Duration(seconds: 15)); // Increased timeout

      final data = json.decode(response.body);

      if (response.statusCode == 200) {

        _token = data['token'];
        _userId = data['_id'];
        _userName = data['name'];
        _userEmail = data['email'];
        _userRole = data['role'];
        _userPhone = data['phone'];

        _isAuthenticated = true;

        await _saveToken(_token!, rememberMe);

        _isLoading = false;
        notifyListeners();

        return true;
      } else {

        _errorMessage = data['message'] ?? 'Login failed';

        _isLoading = false;
        notifyListeners();

        return false;
      }

    } catch (e) {
      debugPrint('Login connection error: $e');
      _errorMessage = 'Unable to connect to server. Please check your internet and server status.';

      _isLoading = false;
      notifyListeners();

      return false;
    }
  }

  // ─── SIGNUP ────────────────────────────────────────────
  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String role = 'student',
    String phone = '',
  }) async {

    _errorMessage = null;

    if (name.trim().length < 2) {
      _errorMessage = 'Name must be at least 2 characters';
      notifyListeners();
      return false;
    }

    if (!isValidEmail(email)) {
      _errorMessage = 'Please enter a valid email';
      notifyListeners();
      return false;
    }

    final passwordErrors = validatePassword(password);

    if (passwordErrors.isNotEmpty) {

      _errorMessage =
          'Password requirements not met:\n• ${passwordErrors.join('\n• ')}';

      notifyListeners();
      return false;
    }

    if (password != confirmPassword) {
      _errorMessage = 'Passwords do not match';
      notifyListeners();
      return false;
    }

    if (phone.trim().isEmpty) {
      _errorMessage = 'Phone number is required';
      notifyListeners();
      return false;
    }

    if (phone.trim().length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone.trim())) {
      _errorMessage = 'Phone must be exactly 10 digits (numbers only)';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {

      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'role': role,
          'phone': phone,
        }),
      ).timeout(const Duration(seconds: 15)); // Increased timeout

      final data = json.decode(response.body);

      if (response.statusCode == 201) {

        // Registration successful, but DO NOT log in automatically
        // The screen will navigate to login after success
        _isLoading = false;
        notifyListeners();

        return true;

      } else {

        _errorMessage = data['message'] ?? 'Signup failed';

        _isLoading = false;
        notifyListeners();

        return false;
      }

    } catch (e) {
      debugPrint('Signup connection error: $e');
      _errorMessage = 'Unable to connect to server. Please check your internet and server status.';

      _isLoading = false;
      notifyListeners();

      return false;
    }
  }

  // ─── UPDATE PROFILE ────────────────────────────────────
  Future<bool> updateProfile({
    required String name,
    required String phone,
  }) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({'name': name.trim(), 'phone': phone.trim()}),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _userName = data['name'] ?? name;
        _userPhone = data['phone'] ?? phone;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Update failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Could not connect to server.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── CHANGE PASSWORD ───────────────────────────────────
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Password change failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Could not connect to server.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── LOGOUT ────────────────────────────────────────────
  Future<void> logout() async {

    _isAuthenticated = false;

    _token = null;
    _userId = null;
    _userName = null;
    _userEmail = null;
    _userRole = null;
    _userPhone = null;

    _errorMessage = null;

    await _clearSavedToken();

    notifyListeners();
  }

  void clearError() {

    _errorMessage = null;
    notifyListeners();
  }
}
