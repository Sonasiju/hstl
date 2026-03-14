import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/api_config.dart';
import '../../data/providers/auth_provider.dart';

class HostelApplicantsScreen extends StatefulWidget {
  const HostelApplicantsScreen({Key? key}) : super(key: key);

  @override
  State<HostelApplicantsScreen> createState() => _HostelApplicantsScreenState();
}

class _HostelApplicantsScreenState extends State<HostelApplicantsScreen> {
  List<dynamic> _applications = [];
  bool _isLoading = true;
  String? _error;
  String _filterStatus = 'pending'; // Filter: pending, reviewed, approved, rejected

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;

      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Not logged in. Please restart the app.';
          _isLoading = false;
        });
        return;
      }

      final url = _filterStatus == 'all'
          ? '${ApiConfig.getConfiguredUrl()}/api/hostel-applications'
          : '${ApiConfig.getConfiguredUrl()}/api/hostel-applications?status=$_filterStatus';

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
          _applications = List<dynamic>.from(data);
          _isLoading = false;
        });
      } else {
        String msg;
        try {
          final body = json.decode(response.body);
          msg = body['message'] ?? 'Error ${response.statusCode}';
        } catch (_) {
          msg = 'HTTP ${response.statusCode}';
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

  Future<void> _reviewApplication(dynamic application) async {
    final feedbackCtrl = TextEditingController();
    String selectedStatus = 'approved';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Review Application',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hostel: ${application['hostelName']}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Owner: ${application['ownerName']}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                'Status:',
                style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setState) => DropdownButtonFormField<String>(
                  value: selectedStatus,
                  dropdownColor: const Color(0xFF0F172A),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'approved', child: Text('Approved', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'rejected', child: Text('Rejected', style: TextStyle(color: Colors.white))),
                  ],
                  onChanged: (value) {
                    setState(() => selectedStatus = value ?? 'approved');
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Feedback Message (Optional):',
                style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: feedbackCtrl,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter your feedback...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFACC15),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save & Notify User', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _submitReview(application['_id'], selectedStatus, feedbackCtrl.text.trim());
    }
  }

  Future<void> _submitReview(String appId, String status, String feedback) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.put(
        Uri.parse('${ApiConfig.getConfiguredUrl()}/api/hostel-applications/$appId/review'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'status': status,
          'feedback': feedback,
        }),
      ).timeout(const Duration(seconds: 10));

      if (mounted) {
        if (response.statusCode == 200) {
          _fetchApplications(); // Refresh list
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('✅ Application ${status}!'),
            backgroundColor: status == 'approved' ? const Color(0xFF10B981) : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ));
        } else {
          final d = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(d['message'] ?? 'Error'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Hostel Applicants'),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFACC15)),
            onPressed: _fetchApplications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFACC15),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: _fetchApplications,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filter tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          _filterTab('Pending', 'pending'),
                          const SizedBox(width: 8),
                          _filterTab('Reviewed', 'reviewed'),
                          const SizedBox(width: 8),
                          _filterTab('Approved', 'approved'),
                          const SizedBox(width: 8),
                          _filterTab('Rejected', 'rejected'),
                          const SizedBox(width: 8),
                          _filterTab('All', 'all'),
                        ],
                      ),
                    ),
                    // Applications list
                    Expanded(
                      child: _applications.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.inbox_outlined, color: Colors.grey, size: 60),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No applications found.',
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchApplications,
                              color: const Color(0xFFFACC15),
                              backgroundColor: const Color(0xFF1E293B),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _applications.length,
                                itemBuilder: (_, i) => _buildApplicationCard(_applications[i]),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _filterTab(String label, String status) {
    final isSelected = _filterStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFACC15) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFACC15) : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationCard(dynamic application) {
    final status = application['status']?.toString() ?? 'pending';
    final hostelName = application['hostelName']?.toString() ?? 'Unknown';
    final ownerName = application['ownerName']?.toString() ?? '-';
    final location = application['location']?.toString() ?? '';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'approved':
        statusColor = const Color(0xFF10B981);
        statusLabel = 'APPROVED';
        break;
      case 'rejected':
        statusColor = Colors.redAccent;
        statusLabel = 'REJECTED';
        break;
      case 'reviewed':
        statusColor = Colors.orange;
        statusLabel = 'REVIEWED';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = 'PENDING';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hostelName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Owner: $ownerName',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      if (location.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            location,
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (status == 'pending')
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFACC15),
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _reviewApplication(application),
                    child: const Text('Tap to Review', style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                else if (application['feedback'] != null && application['feedback'].toString().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Review Feedback:',
                          style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          application['feedback'],
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
