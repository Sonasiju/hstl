import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/api_config.dart';
import '../../data/providers/auth_provider.dart';

/// Booking screen — user fills a visit request form for a specific hostel
class BookingScreen extends StatefulWidget {
  final dynamic hostel;

  const BookingScreen({Key? key, required this.hostel}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _contactCtrl;
  final TextEditingController _messageCtrl = TextEditingController();

  String _selectedRoomType = 'Single (1-sharing)';
  int _durationMonths = 1;
  bool _isSubmitting = false;

  final List<String> _roomTypes = [
    'Single (1-sharing)',
    'Double (2-sharing)',
    'Triple (3-sharing)',
    'Any available',
  ];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _nameCtrl = TextEditingController(text: auth.userName ?? '');
    _contactCtrl = TextEditingController(text: auth.userPhone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  String get _hostelName =>
      widget.hostel['name']?.toString() ?? 'Hostel';

  String get _hostelId =>
      widget.hostel['_id']?.toString() ?? '';

  num get _rentPerMonth => widget.hostel['rentPerMonth'] ?? 0;

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_hostelId.isEmpty) {
      _showSnack('Cannot book: hostel ID is missing.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.getConfiguredUrl()}/api/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
        body: json.encode({
          'hostelId': _hostelId,
          'guestName': _nameCtrl.text.trim(),
          'contactNumber': _contactCtrl.text.trim(),
          'roomType': _selectedRoomType,
          'durationInMonths': _durationMonths,
          'message': _messageCtrl.text.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (response.statusCode == 201) {
          _showSuccessDialog();
        } else {
          final data = json.decode(response.body);
          _showSnack(data['message'] ?? 'Booking failed. Try again.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnack('Could not connect. Please check your connection.', isError: true);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: Color(0xFF10B981), size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Booking Requested!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Your visit request for $_hostelName has been submitted.\n\nThe admin will review and confirm your booking.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.schedule, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Status: Pending – Awaiting admin approval',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFACC15),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back to hostel list
              },
              child: const Text('Go Back',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Book a Visit'),
        backgroundColor: const Color(0xFF0F172A),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HOSTEL INFO CARD ──
              _buildHostelInfoCard(),

              const SizedBox(height: 24),

              _sectionTitle('Your Details'),
              const SizedBox(height: 14),

              // Name
              _buildField(
                ctrl: _nameCtrl,
                label: 'Your Full Name',
                icon: Icons.person_outline,
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Enter your full name'
                    : null,
              ),
              const SizedBox(height: 14),

              // Contact
              _buildField(
                ctrl: _contactCtrl,
                label: 'Contact Number',
                icon: Icons.phone_outlined,
                type: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Contact number is required';
                  if (!RegExp(r'^[0-9]+$').hasMatch(v.trim())) return 'Enter numbers only';
                  if (v.trim().length != 10) return '⚠️ Enter exactly 10 digits (India)';
                  return null;
                },
                helperText: '⚠️ India: 10 digits required (e.g. 9876543210)',
              ),

              const SizedBox(height: 24),
              _sectionTitle('Room Preference'),
              const SizedBox(height: 14),

              // Room type dropdown
              _buildDropdown(),
              const SizedBox(height: 14),

              // Duration stepper
              _buildDurationStepper(),
              const SizedBox(height: 14),

              // Estimated cost
              _buildCostCard(),

              const SizedBox(height: 14),

              // Message
              _buildField(
                ctrl: _messageCtrl,
                label: 'Additional Message (optional)',
                icon: Icons.message_outlined,
                maxLines: 3,
                required: false,
              ),

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFACC15),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _isSubmitting ? null : _submitBooking,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, size: 18),
                            SizedBox(width: 8),
                            Text('Submit Booking Request',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              const Center(
                child: Text(
                  'Your request will be reviewed by the hostel admin.\nYou will be notified once approved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────── WIDGETS ────────────────────────────

  Widget _buildHostelInfoCard() {
    final phone = widget.hostel['phone']?.toString();
    final city = widget.hostel['city']?.toString() ?? widget.hostel['address']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF162032)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFACC15).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFACC15).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.hotel, color: Color(0xFFFACC15), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_hostelName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                if (city.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(city,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
                if (phone != null && phone.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.phone, color: Color(0xFFFACC15), size: 12),
                    const SizedBox(width: 4),
                    Text(phone,
                        style: const TextStyle(
                            color: Color(0xFFFACC15), fontSize: 12)),
                  ]),
                ],
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '₹$_rentPerMonth',
                style: const TextStyle(
                    color: Color(0xFFFACC15),
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
              const Text('/mo',
                  style: TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRoomType,
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(color: Colors.white),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Color(0xFFFACC15)),
          isExpanded: true,
          items: _roomTypes.map((t) {
            return DropdownMenuItem(
              value: t,
              child: Row(
                children: [
                  const Icon(Icons.meeting_room,
                      color: Color(0xFFFACC15), size: 16),
                  const SizedBox(width: 10),
                  Text(t),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedRoomType = v!),
        ),
      ),
    );
  }

  Widget _buildDurationStepper() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month,
              color: Color(0xFFFACC15), size: 18),
          const SizedBox(width: 10),
          const Text('Duration:',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline,
                color: Colors.grey),
            onPressed: _durationMonths > 1
                ? () => setState(() => _durationMonths--)
                : null,
          ),
          Text(
            '$_durationMonths Month${_durationMonths > 1 ? 's' : ''}',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: Color(0xFFFACC15)),
            onPressed: _durationMonths < 24
                ? () => setState(() => _durationMonths++)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCostCard() {
    final total = _rentPerMonth * _durationMonths;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFACC15).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFFACC15).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.currency_rupee,
              color: Color(0xFFFACC15), size: 18),
          const SizedBox(width: 8),
          const Text('Estimated Total:',
              style: TextStyle(color: Colors.white70)),
          const Spacer(),
          Text(
            '₹$total',
            style: const TextStyle(
                color: Color(0xFFFACC15),
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          color: Colors.grey,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5));

  Widget _buildField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
    bool required = true,
    String? helperText,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      validator: required ? (validator ?? (v) => (v == null || v.isEmpty) ? 'Required' : null) : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFFFACC15), size: 20),
        helperText: helperText,
        helperStyle: const TextStyle(color: Colors.orange, fontSize: 11),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFFFACC15), width: 1.5)),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}
