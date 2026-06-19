import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme.dart';
import 'services/api_service.dart';
import 'state/cart.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const SchoolOrderApp());
}

class SchoolOrderApp extends StatelessWidget {
  const SchoolOrderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProvider<Cart>(create: (_) => Cart()),
      ],
      child: MaterialApp(
        title: 'Librairie DSM',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const LoginScreen(),
      ),
    );
  }
}
