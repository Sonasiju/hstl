import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/api_config.dart';
import '../../data/providers/auth_provider.dart';
import 'hostel_details_screen.dart';
import 'create_hostel_screen.dart';

/// Shows only hostels that belong to the logged-in admin (GET /api/hostels/my)
class AdminHostelListScreen extends StatefulWidget {
  const AdminHostelListScreen({Key? key}) : super(key: key);

  @override
  State<AdminHostelListScreen> createState() => _AdminHostelListScreenState();
}

class _AdminHostelListScreenState extends State<AdminHostelListScreen> {
  List<dynamic> _hostels = [];
  bool _isLoading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchHostels();
  }

  Future<void> _fetchHostels() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.get(
        Uri.parse('${ApiConfig.getConfiguredUrl()}/api/hostels/my'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _hostels = List<dynamic>.from(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Could not load your hostels (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Could not connect to server.';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteHostel(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Hostel',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'Are you sure you want to delete this hostel? This cannot be undone.',
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.delete(
        Uri.parse('${ApiConfig.getConfiguredUrl()}/api/hostels/$id'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() => _hostels.removeWhere(
            (h) => h['_id']?.toString() == id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Hostel deleted'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating),
          );
        }
      } else {
        if (mounted) {
          final d = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(d['message'] ?? 'Delete failed'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not connect.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _hostels.where((h) {
      final name = (h['name'] ?? '').toString().toLowerCase();
      final city = (h['city'] ?? '').toString().toLowerCase();
      return name.contains(_search.toLowerCase()) ||
          city.contains(_search.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('My Hostels'),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFFACC15)),
            tooltip: 'Add Hostel',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CreateHostelScreen()),
              );
              _fetchHostels(); // refresh after creating
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFACC15)),
            onPressed: _fetchHostels,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name or city...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFACC15)),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          // Count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text(
                  '${filtered.length} hostel${filtered.length != 1 ? 's' : ''} listed by you',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFACC15)))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.redAccent, size: 48),
                            const SizedBox(height: 12),
                            Text(_error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFACC15),
                                foregroundColor: Colors.black,
                              ),
                              onPressed: _fetchHostels,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.hotel,
                                    color: Colors.grey, size: 56),
                                const SizedBox(height: 14),
                                const Text('No hostels added yet.',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 15)),
                                const SizedBox(height: 8),
                                const Text(
                                    'Tap + to create your first hostel listing.',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchHostels,
                            color: const Color(0xFFFACC15),
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) =>
                                  _buildHostelTile(filtered[i]),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFACC15),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add Hostel',
            style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateHostelScreen()),
          );
          _fetchHostels();
        },
      ),
    );
  }

  Widget _buildHostelTile(dynamic hostel) {
    final id = hostel['_id']?.toString() ?? '';
    final name = hostel['name']?.toString() ?? 'Unknown';
    final city = hostel['city']?.toString() ?? hostel['address']?.toString() ?? '-';
    final rent = hostel['rentPerMonth'];
    final type = hostel['type']?.toString() ?? '';
    final rooms = hostel['availableRooms']?.toString() ?? '-';
    final totalRooms = hostel['totalRooms']?.toString() ?? '-';
    final ratings = hostel['ratings'];
    final phone = hostel['phone']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: const Color(0xFFFACC15).withOpacity(0.15))),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => HostelDetailsScreen(hostel: hostel)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFACC15).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.hotel,
                        color: Color(0xFFFACC15), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        const SizedBox(height: 3),
                        Text(city,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(children: [
                            const Icon(Icons.phone,
                                color: Colors.blueAccent, size: 12),
                            const SizedBox(width: 4),
                            Text(phone,
                                style: const TextStyle(
                                    color: Colors.blueAccent, fontSize: 11)),
                          ]),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (rent != null)
                        Text('₹$rent/mo',
                            style: const TextStyle(
                                color: Color(0xFFFACC15),
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      if (ratings != null)
                        Row(children: [
                          const Icon(Icons.star,
                              color: Colors.amber, size: 12),
                          const SizedBox(width: 3),
                          Text(ratings.toString(),
                              style: const TextStyle(
                                  color: Colors.amber, fontSize: 11)),
                        ]),
                    ],
                  ),
                ],
              ),

              const Divider(height: 16, color: Colors.white10),

              Row(
                children: [
                  if (type.isNotEmpty) ...[
                    _chip(type.toUpperCase(), Colors.blueAccent),
                    const SizedBox(width: 8),
                  ],
                  _chip('$rooms/$totalRooms rooms', const Color(0xFF10B981)),
                  const Spacer(),
                  PopupMenuButton<String>(
                    color: const Color(0xFF1E293B),
                    icon: const Icon(Icons.more_horiz, color: Colors.grey),
                    onSelected: (val) {
                      if (val == 'delete' && id.isNotEmpty) {
                        _deleteHostel(id);
                      } else if (val == 'view') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  HostelDetailsScreen(hostel: hostel)),
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(children: [
                          Icon(Icons.visibility,
                              color: Colors.white, size: 16),
                          SizedBox(width: 10),
                          Text('View Details',
                              style: TextStyle(color: Colors.white)),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete,
                              color: Colors.redAccent, size: 16),
                          SizedBox(width: 10),
                          Text('Delete',
                              style: TextStyle(color: Colors.redAccent)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
