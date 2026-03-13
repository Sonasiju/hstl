import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/main_layout.dart';
import 'data/providers/hostel_provider.dart';
import 'data/providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HostelProvider()),
      ],
      child: const HostelApp(),
    ),
  );
}

class HostelApp extends StatelessWidget {
  const HostelApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HostelHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFFFACC15),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFFFACC15),
          secondary: const Color(0xFF10B981),
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
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
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInit = true;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      Provider.of<AuthProvider>(context, listen: false).tryAutoLogin().then((_) {
        setState(() {
          _isLoading = false;
        });
      });
      _isInit = false;
    }
    super.didChangeDependencies();
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
                'HostelHub',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFACC15),
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(color: Color(0xFFFACC15)),
            ],
          ),
        ),
      );
    }

    // Use Consumer to react to auth state changes
    return Consumer<AuthProvider>(
      builder: (ctx, auth, _) {
        if (auth.isAuthenticated) {
          return const MainLayout();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
