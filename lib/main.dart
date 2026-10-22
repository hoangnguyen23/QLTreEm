import 'package:flutter/material.dart';
import 'config/api_config.dart';
import 'services/api_service.dart';
import 'services/pairing_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/parent/parent_main_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/child/child_main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.init();

  Widget initialScreen = const LoginScreen();

  final token = await ApiService.getToken();
  final role = await ApiService.getSavedRole();
  final isChildPaired = await PairingService.isChildDevicePaired();

  if (isChildPaired) {
    initialScreen = const ChildMainScreen();
  } else if (token != null && token.isNotEmpty) {
    if (role == 'ADMIN') {
      initialScreen = const AdminUsersScreen();
    } else if (role == 'CHILD') {
      initialScreen = const ChildMainScreen();
    } else {
      initialScreen = const ParentMainScreen();
    }
  }

  runApp(MyApp(initialScreen: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Điện Thoại Trẻ Em',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // Modern Royal Blue
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: initialScreen,
    );
  }
}
