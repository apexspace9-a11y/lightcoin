import 'package:flutter/material.dart';

import 'services/notification_service.dart';
import 'state/money_store.dart';
import 'ui/app_shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  final store = MoneyStore();
  await store.load();
  runApp(SaveMoneyApp(store: store));
}

class SaveMoneyApp extends StatelessWidget {
  const SaveMoneyApp({super.key, required this.store});
  final MoneyStore store;

  ThemeMode _themeMode(String value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Tiết Kiệm',
          theme: lightTheme(),
          darkTheme: darkTheme(),
          themeMode: _themeMode(store.theme),
          home: AppShell(store: store),
        ),
      );
}
