import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'app_store.dart';
import 'models.dart';
import 'notification_service.dart';

part 'ui_home.dart';
part 'ui_planner.dart';
part 'ui_settings.dart';
part 'ui_forms.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(LightCoinApp(store: AppStore()));
}

const _purple = Color(0xFF6D5DFB);
const _mint = Color(0xFF39D3B4);
const _ink = Color(0xFF17152A);
final _money = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
);
final _day = DateFormat('dd/MM/yyyy');
final _time = DateFormat('HH:mm');

class LightCoinApp extends StatefulWidget {
  const LightCoinApp({super.key, required this.store});
  final AppStore store;

  @override
  State<LightCoinApp> createState() => _LightCoinAppState();
}

class _LightCoinAppState extends State<LightCoinApp> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_changed);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await Future.wait([
        initializeDateFormatting('vi_VN'),
        widget.store.load(),
      ]);
    } catch (_) {
      // Giao diện vẫn phải xuất hiện ngay cả khi một dịch vụ phụ gặp lỗi.
    }
    if (mounted) setState(() => _ready = true);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.store.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.store.darkMode;
    final overlay = (dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark)
        .copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Light Coin',
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlay,
        child: child ?? const SizedBox.shrink(),
      ),
      home: _ready ? Shell(store: widget.store) : const _LaunchScreen(),
    );
  }
}

class _LaunchScreen extends StatelessWidget {
  const _LaunchScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6554F6),
              Color(0xFF7665FF),
              Color(0xFF31CDAE),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .22),
                  ),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  size: 46,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Light Coin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.7,
                ),
              ),
              const SizedBox(height: 22),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                  backgroundColor: Colors.white24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ThemeData _theme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final surface = dark ? const Color(0xFF11101A) : const Color(0xFFF7F7FB);
  final card = dark ? const Color(0xFF1B1927) : Colors.white;
  final scheme = ColorScheme.fromSeed(
    seedColor: _purple,
    brightness: brightness,
    surface: surface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: surface,
    textTheme: ThemeData(brightness: brightness).textTheme.apply(
          bodyColor: dark ? Colors.white : _ink,
          displayColor: dark ? Colors.white : _ink,
        ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: dark ? .10 : .42),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF23202F) : const Color(0xFFF1F0F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _purple, width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: card,
      indicatorColor: _purple.withValues(alpha: .13),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w500,
        ),
      ),
    ),
  );
}
