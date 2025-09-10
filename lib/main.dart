import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/admin_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // 인증 상태를 직접 관리하지 않고 StreamBuilder 사용

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Class 파일 제출 시스템',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder<AuthState>(
        stream: AuthService.authStateStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final session = snapshot.data?.session;
          if (session != null) {
            return const RoleBasedScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}

class RoleBasedScreen extends StatefulWidget {
  const RoleBasedScreen({super.key});

  @override
  State<RoleBasedScreen> createState() => _RoleBasedScreenState();
}

class _RoleBasedScreenState extends State<RoleBasedScreen> {
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final isAdmin = await UserService.isAdmin();
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('사용자 권한을 확인하는 중...'),
            ],
          ),
        ),
      );
    }

    return _isAdmin ? const AdminScreen() : const MainScreen();
  }
}
