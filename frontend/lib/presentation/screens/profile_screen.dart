import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import '../../data/providers/auth_provider.dart';
import 'hostel_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  dynamic _currentHostel;
  bool _isLoadingHostel = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentHostel();
  }

  Future<void> _fetchCurrentHostel() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.userRole != 'student') return;

    setState(() => _isLoadingHostel = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getConfiguredUrl()}/api/bookings/mybookings'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );

      if (response.statusCode == 200) {
        final List bookings = json.decode(response.body);
        // Find the first approved booking
        final approved = bookings.firstWhere(
            (b) => b['status'] == 'Approved',
            orElse: () => null);
        if (approved != null && mounted) {
          setState(() => _currentHostel = approved['hostelId']);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingHostel = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: CustomScrollView(
            slivers: [
              // ── APP BAR ──
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: const Color(0xFF0F172A),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeader(auth),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    onPressed: () => _confirmLogout(context, auth),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── CURRENT HOSTEL SECTION (for students) ──
                      if (auth.userRole == 'student') ...[
                        _sectionTitle('YOUR RESIDENCE'),
                        const SizedBox(height: 12),
                        _buildCurrentHostelCard(),
                        const SizedBox(height: 24),
                      ],

                      // ── ACCOUNT INFO ──
                      _sectionTitle('ACCOUNT INFO'),
                      const SizedBox(height: 12),
                      _buildInfoContainer([
                        _InfoTile(icon: Icons.person, label: 'Name', value: auth.userName),
                        _InfoTile(icon: Icons.email, label: 'Email', value: auth.userEmail),
                        _InfoTile(icon: Icons.phone, label: 'Phone', value: auth.userPhone, fallback: 'Not set'),
                      ]),

                      const SizedBox(height: 24),

                      // ── ACTIONS ──
                      _sectionTitle('ACTIONS'),
                      const SizedBox(height: 12),
                      _buildInfoContainer([
                        _ActionTile(
                          icon: Icons.edit_outlined,
                          label: 'Edit Profile',
                          color: const Color(0xFFFACC15),
                          onTap: () => _openEditProfile(context, auth),
                        ),
                        _ActionTile(
                          icon: Icons.lock_outline,
                          label: 'Change Password',
                          color: Colors.blueAccent,
                          onTap: () => _openChangePassword(context, auth),
                        ),
                      ]),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFACC15), width: 2),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF0F172A),
              child: Text(
                auth.userName?.isNotEmpty == true ? auth.userName![0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFFACC15)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(auth.userName ?? 'User',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(auth.userRole?.toUpperCase() ?? 'GUEST',
              style: const TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildCurrentHostelCard() {
    if (_isLoadingHostel) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15)));
    }

    if (_currentHostel == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: const [
            Icon(Icons.hotel_outlined, color: Colors.grey, size: 32),
            SizedBox(height: 10),
            Text('No active residence', style: TextStyle(color: Colors.grey)),
            Text('Book a hostel to see your details here.', style: TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      );
    }

    final name = _currentHostel['name'] ?? 'Your Hostel';
    final address = _currentHostel['address'] ?? '';
    final city = _currentHostel['city'] ?? '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFACC15), Color(0xFFEAB308)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFFFACC15).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HostelDetailsScreen(hostel: _currentHostel))),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.location_city, color: Colors.black87, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Hostel', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(name, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('$address, $city', style: const TextStyle(color: Colors.black54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.black45, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5));

  Widget _buildInfoContainer(List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
      child: Column(children: tiles),
    );
  }

  void _openEditProfile(BuildContext context, AuthProvider auth) {
    final nameCtrl = TextEditingController(text: auth.userName ?? '');
    final phoneCtrl = TextEditingController(text: auth.userPhone ?? '');
    final outerCtx = context;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Container(width: 40, height: 3, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2))),
              _textField(nameCtrl, 'Name', Icons.person),
              const SizedBox(height: 12),
              _textField(phoneCtrl, 'Phone', Icons.phone, type: TextInputType.phone),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('⚠️ India: 10 digits required', style: TextStyle(color: Colors.orange, fontSize: 11)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFACC15), foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 50)),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(outerCtx).showSnackBar(const SnackBar(
                      content: Text('Name cannot be empty'),
                      backgroundColor: Colors.red,
                    ));
                    return;
                  }

                  final phone = phoneCtrl.text.trim();
                  if (phone.isNotEmpty) {
                    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
                      ScaffoldMessenger.of(outerCtx).showSnackBar(const SnackBar(
                        content: Text('Phone must be exactly 10 digits'),
                        backgroundColor: Colors.red,
                      ));
                      return;
                    }
                  }

                  final success = await auth.updateProfile(name: nameCtrl.text, phone: phoneCtrl.text);
                  if (outerCtx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(outerCtx).showSnackBar(SnackBar(
                      content: Text(success ? '✅ Profile updated!' : (auth.errorMessage ?? 'Update failed')),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ));
                  }
                },
                child: const Text('Save Changes'),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _openChangePassword(BuildContext context, AuthProvider auth) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool isLoading = false;
    final outerCtx = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Change Password', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Container(width: 40, height: 3, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2))),
              _textField(oldCtrl, 'Current Password', Icons.lock, obscure: true),
              const SizedBox(height: 12),
              _textField(newCtrl, 'New Password', Icons.lock_outline, obscure: true),
              const SizedBox(height: 12),
              _textField(confirmCtrl, 'Confirm New Password', Icons.lock_reset, obscure: true),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: isLoading ? null : () async {
                  if (oldCtrl.text.isEmpty || newCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(outerCtx).showSnackBar(const SnackBar(
                      content: Text('Please fill all fields'),
                      backgroundColor: Colors.orange,
                    ));
                    return;
                  }
                  if (newCtrl.text != confirmCtrl.text) {
                    ScaffoldMessenger.of(outerCtx).showSnackBar(const SnackBar(
                      content: Text('New passwords do not match'),
                      backgroundColor: Colors.orange,
                    ));
                    return;
                  }
                  setModalState(() => isLoading = true);
                  final success = await auth.changePassword(
                    currentPassword: oldCtrl.text,
                    newPassword: newCtrl.text,
                  );
                  setModalState(() => isLoading = false);
                  if (outerCtx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(outerCtx).showSnackBar(SnackBar(
                      content: Text(success ? '✅ Password updated successfully!' : (auth.errorMessage ?? 'Password change failed')),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ));
                  }
                },
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Update Password'),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure?', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () { Navigator.pop(context); auth.logout(); }, child: const Text('Logout', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String label, IconData icon, {bool obscure = false, TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFFFACC15)),
        filled: true, fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String fallback;
  const _InfoTile({required this.icon, required this.label, this.value, this.fallback = '-'});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFACC15), size: 20),
      title: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      subtitle: Text(value ?? fallback, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
    );
  }
}
