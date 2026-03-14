import 'package:flutter/material.dart';
import 'main_layout.dart';

class UserDashboard extends StatelessWidget {
  const UserDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // The User Dashboard is currently built into the MainLayout 
    // which provides the map, discovery, bookings, and profile tabs.
    return const MainLayout();
  }
}
