import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'state/cart.dart';
import 'state/tab_notifier.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const SchoolOrderApp());
}

class SchoolOrderApp extends StatelessWidget {
  const SchoolOrderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProvider<Cart>(create: (_) => Cart()),
        ChangeNotifierProvider<TabNotifier>(create: (_) => TabNotifier()),
      ],
      child: MaterialApp(
        title: 'Librairie DSM',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _AppRoot(),
      ),
    );
  }
}

/// Tente de restaurer la session sauvegardée avant d'afficher le shell.
class _AppRoot extends StatefulWidget {
  const _AppRoot();
  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await context.read<ApiService>().restoreSession();
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const MainShell();
  }
}
