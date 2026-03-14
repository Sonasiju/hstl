import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/api_config.dart';
import '../../data/providers/auth_provider.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({Key? key}) : super(key: key);

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookings() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;
      if (token == null || token.isEmpty) {
        setState(() { _error = 'Not logged in. Please restart the app.'; _isLoading = false; });
        return;
      }

      final url = '${ApiConfig.getConfiguredUrl()}/api/bookings/admin';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _bookings = List<dynamic>.from(data);
          _isLoading = false;
        });
      } else {
        String msg;
        try {
          final body = json.decode(response.body);
          msg = body['message'] ?? 'Error ${response.statusCode}';
        } catch (_) {
          msg = 'HTTP ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 100))}';
        }
        setState(() { _error = msg; _isLoading = false; });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection failed: ${e.toString().split('\n').first}';
        _isLoading = false;
      });
    }
  }

  /// Open a dialog to approve a booking and assign a slot
  Future<void> _approveBooking(dynamic booking) async {
    final slotCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime? selectedDateTime;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Approve Booking',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guest: ${booking['guestName'] ?? booking['userId']?['name'] ?? 'Unknown'}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  'Room: ${booking['roomType'] ?? 'Standard'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                const Text('Set Visit Date & Time',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                      builder: (_, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFFFACC15),
                            surface: Color(0xFF1E293B),
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (date != null && ctx.mounted) {
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime: const TimeOfDay(hour: 10, minute: 0),
                        builder: (_, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFFFACC15),
                              surface: Color(0xFF1E293B),
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (time != null) {
                        setDialogState(() {
                          selectedDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedDateTime != null
                            ? const Color(0xFFFACC15)
                            : Colors.white24,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time,
                            color: Color(0xFFFACC15), size: 18),
                        const SizedBox(width: 10),
                        Text(
                          selectedDateTime != null
                              ? '${selectedDateTime!.day}/${selectedDateTime!.month}/${selectedDateTime!.year}  ${selectedDateTime!.hour}:${selectedDateTime!.minute.toString().padLeft(2, '0')}'
                              : 'Tap to pick date & time',
                          style: TextStyle(
                            color: selectedDateTime != null
                                ? Colors.white
                                : Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Assign Slot/Room',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: slotCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g. Room 101, Bed A',
                    hintStyle:
                        const TextStyle(color: Colors.grey, fontSize: 13),
                    prefixIcon: const Icon(Icons.door_sliding,
                        color: Color(0xFFFACC15)),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add a note (optional)',
                    hintStyle:
                        const TextStyle(color: Colors.grey, fontSize: 13),
                    prefixIcon: const Icon(Icons.message_outlined,
                        color: Color(0xFFFACC15)),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (selectedDateTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please pick a visit date & time.'),
                        backgroundColor: Colors.orange),
                  );
                  return;
                }
                if (slotCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please assign a slot/room.'),
                        backgroundColor: Colors.orange),
                  );
                  return;
                }
                Navigator.pop(dialogCtx, true);
              },
              child: const Text('Approve',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedDateTime != null) {
      final visitTimeStr =
          '${selectedDateTime!.day}/${selectedDateTime!.month}/${selectedDateTime!.year}  ${selectedDateTime!.hour}:${selectedDateTime!.minute.toString().padLeft(2, '0')}';
      await _updateStatus(
        booking['_id'].toString(),
        'Approved',
        visitTime: visitTimeStr,
        slot: slotCtrl.text.trim(),
        note: noteCtrl.text.trim(),
      );
    }
  }

  Future<void> _rejectBooking(dynamic booking) async {
    final noteCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Booking',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reject booking for ${booking['guestName'] ?? 'this guest'}?',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Reason (shown to guest)',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateStatus(
        booking['_id'].toString(),
        'Rejected',
        note: noteCtrl.text.trim(),
      );
    }
  }

  Future<void> _updateStatus(
    String id,
    String status, {
    String visitTime = '',
    String slot = '',
    String note = '',
  }) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;

      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Not authenticated. Please log in again.'),
            backgroundColor: Colors.redAccent,
          ));
        }
        return;
      }

      final url = '${ApiConfig.getConfiguredUrl()}/api/bookings/$id/status';
      debugPrint('Updating booking status: PUT $url');

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'status': status,
          if (visitTime.isNotEmpty) 'visitTime': visitTime,
          if (slot.isNotEmpty) 'approvedSlot': slot,
          if (note.isNotEmpty) 'adminNote': note,
        }),
      ).timeout(const Duration(seconds: 20));

      debugPrint('Status update response: ${response.statusCode}');

      if (mounted) {
        if (response.statusCode == 200) {
          await _fetchBookings();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(status == 'Approved'
                ? '✅ Booking approved! Slot: $slot'
                : '❌ Booking rejected'),
            backgroundColor: status == 'Approved'
                ? const Color(0xFF10B981)
                : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ));
        } else {
          String msg;
          try {
            final d = json.decode(response.body);
            msg = d['message'] ?? 'Error ${response.statusCode}';
          } catch (_) {
            msg = 'Server error ${response.statusCode}';
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed: $msg'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (e) {
      debugPrint('_updateStatus error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Could not connect to server.\nError: ${e.toString().split('\n').first}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  List<dynamic> _byStatus(String s) =>
      s == 'all' ? _bookings : _bookings.where((b) => b['status'] == s).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Manage Bookings'),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFACC15)),
            onPressed: _fetchBookings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFACC15),
          labelColor: const Color(0xFFFACC15),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'All (${_bookings.length})'),
            Tab(text: 'Pending (${_byStatus('Pending').length})'),
            Tab(text: 'Done (${_byStatus('Approved').length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFACC15),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: _fetchBookings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList('all'),
                    _buildList('Pending'),
                    _buildList('Approved'),
                  ],
                ),
    );
  }

  Widget _buildList(String filter) {
    final list = _byStatus(filter);
    if (list.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, color: Colors.grey, size: 48),
            SizedBox(height: 12),
            Text('No bookings here.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchBookings,
      color: const Color(0xFFFACC15),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) => _buildCard(list[i]),
      ),
    );
  }

  Widget _buildCard(dynamic b) {
    final status = (b['status']?.toString() ?? 'Pending');
    final guestName = b['guestName']?.toString() ?? b['userId']?['name']?.toString() ?? 'Unknown';
    final guestEmail = b['userId']?['email']?.toString() ?? '';
    final guestPhone = b['contactNumber']?.toString() ?? b['userId']?['phone']?.toString() ?? '';
    final hostelData = b['hostelId'];
    final hostelName = hostelData is Map ? hostelData['name']?.toString() ?? 'Hostel' : 'Hostel';
    final roomType = b['roomType']?.toString() ?? 'Standard';
    final duration = b['durationInMonths']?.toString() ?? '1';
    final amount = b['totalAmount'];
    final message = b['message']?.toString() ?? '';
    final visitTime = b['visitTime']?.toString() ?? '';
    final adminNote = b['adminNote']?.toString() ?? '';

    String? dateStr;
    try {
      final dt = DateTime.parse(b['createdAt'].toString()).toLocal();
      dateStr = '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {}

    Color statusColor;
    switch (status) {
      case 'Approved': statusColor = const Color(0xFF10B981); break;
      case 'Rejected': statusColor = Colors.redAccent; break;
      default: statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Icon(
                    status == 'Approved' ? Icons.check_circle : status == 'Rejected' ? Icons.cancel : Icons.schedule,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(guestName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      if (guestEmail.isNotEmpty)
                        Text(guestEmail,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11)),
                      if (guestPhone.isNotEmpty)
                        Row(children: [
                          const Icon(Icons.phone, color: Colors.blueAccent, size: 12),
                          const SizedBox(width: 4),
                          Text(guestPhone,
                              style: const TextStyle(
                                  color: Colors.blueAccent, fontSize: 11)),
                        ]),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(status.toUpperCase(),
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            const Divider(height: 20, color: Colors.white10),

            // ── Details ──
            _row(Icons.hotel, hostelName),
            _row(Icons.meeting_room, '$roomType · $duration month${int.tryParse(duration) == 1 ? '' : 's'}'),
            if (amount != null) _row(Icons.currency_rupee, '₹$amount estimated'),
            if (dateStr != null) _row(Icons.access_time, 'Requested: $dateStr'),
            if (message.isNotEmpty) _row(Icons.message, message),

            // Visit time if approved
            if (visitTime.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.event_available, color: Color(0xFF10B981), size: 16),
                  const SizedBox(width: 8),
                  const Text('Visit: ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Expanded(
                    child: Text(visitTime,
                        style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ]),
              ),
            ],

            // Admin note
            if (adminNote.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.sticky_note_2, color: Colors.grey, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(adminNote,
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                ]),
              ),
            ],

            // ── Action buttons (show only for Pending) ──
            if (status == 'Pending') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close, size: 14, color: Colors.redAccent),
                      label: const Text('Reject',
                          style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => _rejectBooking(b),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text('Approve + Set Time',
                          style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => _approveBooking(b),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
