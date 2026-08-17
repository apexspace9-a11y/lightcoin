import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'app_store.dart';
import 'models.dart';
import 'notification_service.dart';

part 'ui_home.dart';
part 'ui_planner.dart';
part 'ui_settings.dart';
part 'ui_forms.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN');
  final store = AppStore();
  await NotificationService.instance.init();
  await store.load();
  runApp(LightCoinApp(store: store));
}

const _purple = Color(0xFF6D5DFB);
const _mint = Color(0xFF39D3B4);
const _ink = Color(0xFF17152A);
final _money = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
final _day = DateFormat('dd/MM/yyyy');
final _time = DateFormat('HH:mm');

class LightCoinApp extends StatefulWidget {
  const LightCoinApp({super.key, required this.store});
  final AppStore store;
  @override State<LightCoinApp> createState() => _LightCoinAppState();
}
class _LightCoinAppState extends State<LightCoinApp> {
  @override void initState(){super.initState();widget.store.addListener(_changed);} 
  void _changed()=>setState((){});
  @override void dispose(){widget.store.removeListener(_changed);super.dispose();}
  @override Widget build(BuildContext context){
    final dark=widget.store.darkMode;
    return MaterialApp(
      debugShowCheckedModeBanner:false,
      title:'Light Coin',
      themeMode: dark?ThemeMode.dark:ThemeMode.light,
      theme:_theme(Brightness.light),
      darkTheme:_theme(Brightness.dark),
      home:Shell(store:widget.store),
    );
  }
}
ThemeData _theme(Brightness b){
  final dark=b==Brightness.dark;
  final scheme=ColorScheme.fromSeed(seedColor:_purple,brightness:b,surface:dark?const Color(0xFF11101A):const Color(0xFFF8F8FC));
  return ThemeData(
    useMaterial3:true,
    colorScheme:scheme,
    scaffoldBackgroundColor:scheme.surface,
    fontFamily:'sans-serif',
    textTheme:ThemeData(brightness:b).textTheme.apply(bodyColor:dark?Colors.white: _ink,displayColor:dark?Colors.white:_ink),
    cardTheme:CardThemeData(elevation:0,margin:EdgeInsets.zero,color:dark?const Color(0xFF1B1927):Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(24))),
    inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:dark?const Color(0xFF23202F):const Color(0xFFF2F1F8),border:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:BorderSide.none),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:BorderSide.none),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:const BorderSide(color:_purple,width:1.3))),
    navigationBarTheme:NavigationBarThemeData(height:72,indicatorColor:_purple.withValues(alpha:.14),labelTextStyle:WidgetStateProperty.resolveWith((s)=>TextStyle(fontSize:11,fontWeight:s.contains(WidgetState.selected)?FontWeight.w700:FontWeight.w500))),
  );
}
