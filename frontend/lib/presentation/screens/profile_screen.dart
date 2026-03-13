import 'package:flutter/material.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
               Navigator.of(context).pushReplacement(
                 MaterialPageRoute(builder: (context) => const LoginScreen())
               );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF2563EB),
              child: Text(
                'TS',
                style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Test Student',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'student@test.com',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            _buildActionItem(context, Icons.person_outline, 'Edit Profile'),
            _buildActionItem(context, Icons.payment, 'Payment Methods'),
            _buildActionItem(context, Icons.history, 'Payment History'),
            _buildActionItem(context, Icons.notifications_none, 'Notifications'),
            _buildActionItem(context, Icons.report_problem_outlined, 'Report an Issue'),
            const SizedBox(height: 24),
            _buildActionItem(context, Icons.security, 'Privacy Policy'),
            _buildActionItem(context, Icons.help_outline, 'Help & Support'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String title) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF2563EB)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Navigate to respective page
      },
    );
  }
}
