import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  // ─── State ───────────────────────────────────────────────────────────────
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _token;
  String? _userId;
  String? _userName;
  String? _userEmail;
  String? _userRole;
  String? _errorMessage;

  // ─── Getters ─────────────────────────────────────────────────────────────
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get token => _token;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userRole => _userRole;
  String? get errorMessage => _errorMessage;

  static const String _baseUrl = 'http://10.223.111.90:5000';
  static const String _tokenKey = 'auth_token';
  static const String _rememberMeKey = 'remember_me';

  // ─── Password Validation ─────────────────────────────────────────────────
  /// Returns a list of unmet password requirements.
  /// Empty list means the password is valid.
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
    if (!RegExp(r'[!@#\$%^&*()\-_=+\[\]{};:\'",.<>?/\\|`~]').hasMatch(password)) {
      errors.add('At least one special character (!@#\$%^&*)');
    }
    return errors;
  }

  /// Returns true if the email format is valid.
  static bool isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  // ─── Persistence ─────────────────────────────────────────────────────────
  /// Checks SharedPreferences for a saved token and verifies it with the server.
  /// Call this on app startup.
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

    if (!rememberMe) return false;

    final savedToken = prefs.getString(_tokenKey);
    if (savedToken == null || savedToken.isEmpty) return false;

    // Verify the token is still valid by calling /api/auth/me
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
        _isAuthenticated = true;
        notifyListeners();
        return true;
      } else {
        // Token expired or invalid — clear it
        await _clearSavedToken();
        return false;
      }
    } catch (_) {
      // Server unreachable — still restore session from stored data
      // (offline-first approach)
      return false;
    }
  }

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
      // Clear any saved token for non-remember sessions
      await prefs.remove(_tokenKey);
      await prefs.setBool(_rememberMeKey, false);
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    _errorMessage = null;

    // ── Client-side validation ──
    if (email.isEmpty) {
      _errorMessage = 'Please enter your email address.';
      notifyListeners();
      return false;
    }
    if (!isValidEmail(email)) {
      _errorMessage = 'Please enter a valid email address (e.g. user@example.com).';
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
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        _userId = data['_id'];
        _userName = data['name'];
        _userEmail = data['email'];
        _userRole = data['role'];
        _isAuthenticated = true;
        await _saveToken(_token!, rememberMe);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Login failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Unable to connect to server. Please check your connection.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Signup ───────────────────────────────────────────────────────────────
  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String role = 'student',
    String phone = '',
  }) async {
    _errorMessage = null;

    // ── Client-side validation ──
    if (name.trim().length < 2) {
      _errorMessage = 'Name must be at least 2 characters.';
      notifyListeners();
      return false;
    }
    if (!isValidEmail(email)) {
      _errorMessage = 'Please enter a valid email address (e.g. user@example.com).';
      notifyListeners();
      return false;
    }
    final passwordErrors = validatePassword(password);
    if (passwordErrors.isNotEmpty) {
      _errorMessage = 'Password requirements not met:\n• ${passwordErrors.join('\n• ')}';
      notifyListeners();
      return false;
    }
    if (password != confirmPassword) {
      _errorMessage = 'Passwords do not match.';
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
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        _token = data['token'];
        _userId = data['_id'];
        _userName = data['name'];
        _userEmail = data['email'];
        _userRole = data['role'];
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Server may return a list of errors
        if (data['errors'] != null && data['errors'] is List) {
          final errorsList = (data['errors'] as List).cast<String>();
          _errorMessage = 'Password requirements not met:\n• ${errorsList.join('\n• ')}';
        } else {
          _errorMessage = data['message'] ?? 'Signup failed. Please try again.';
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Unable to connect to server. Please check your connection.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    _isAuthenticated = false;
    _token = null;
    _userId = null;
    _userName = null;
    _userEmail = null;
    _userRole = null;
    _errorMessage = null;
    await _clearSavedToken();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
