import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'presentation/screens/login_screen.dart';
import 'presentation/screens/user_dashboard.dart';
import 'presentation/screens/admin_dashboard.dart';

import 'data/providers/auth_provider.dart';
import 'data/providers/hostel_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<HostelProvider>(
          create: (_) => HostelProvider(),
        ),
      ],
      child: const HostelApp(),
    ),
  );
}

class HostelApp extends StatelessWidget {
  const HostelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HostelHub',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFFFACC15),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFACC15),
          brightness: Brightness.dark,
        ),

        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _autoLogin();
  }

  Future<void> _autoLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await authProvider.tryAutoLogin();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "HostelHub",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFACC15),
                ),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(
                color: Color(0xFFFACC15),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, auth, child) {

        if (auth.isAuthenticated) {

          /// ROLE BASED DASHBOARD
          if (auth.userRole == "admin") {
            return const AdminDashboard();
          }

          return const UserDashboard();
        }

        return const LoginScreen();
      },
    );
  }
}