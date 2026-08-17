part of 'main.dart';

class Shell extends StatefulWidget{const Shell({super.key,required this.store});final AppStore store;@override State<Shell> createState()=>_ShellState();}
class _ShellState extends State<Shell>{
  int index=0;
  @override Widget build(BuildContext context){
    final pages=[HomePage(store:widget.store,onGo:(i)=>setState(()=>index=i)),CalendarPage(store:widget.store),SavingsPage(store:widget.store),RemindersPage(store:widget.store),SettingsPage(store:widget.store)];
    return Scaffold(
      body:SafeArea(child:IndexedStack(index:index,children:pages)),
      bottomNavigationBar:NavigationBar(selectedIndex:index,onDestinationSelected:(i)=>setState(()=>index=i),destinations:const [
        NavigationDestination(icon:Icon(Icons.auto_awesome_rounded),label:'Hôm nay'),
        NavigationDestination(icon:Icon(Icons.calendar_month_rounded),label:'Lịch'),
        NavigationDestination(icon:Icon(Icons.savings_rounded),label:'Tiết kiệm'),
        NavigationDestination(icon:Icon(Icons.notifications_active_rounded),label:'Nhắc hẹn'),
        NavigationDestination(icon:Icon(Icons.tune_rounded),label:'Cài đặt'),
      ]),
    );
  }
}

class PageFrame extends StatelessWidget{const PageFrame({super.key,required this.title,this.subtitle,required this.child,this.action});final String title;final String? subtitle;final Widget child;final Widget? action;@override Widget build(BuildContext context)=>CustomScrollView(slivers:[SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(20,24,20,14),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:28,fontWeight:FontWeight.w800,letterSpacing:-.7)),if(subtitle!=null)...[const SizedBox(height:4),Text(subtitle!,style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant,fontSize:13))]])),if(action!=null)action!] ))),SliverPadding(padding:const EdgeInsets.fromLTRB(20,0,20,110),sliver:SliverToBoxAdapter(child:child))]);}

class HomePage extends StatelessWidget{
  const HomePage({super.key,required this.store,required this.onGo});final AppStore store;final ValueChanged<int> onGo;
  @override Widget build(BuildContext context){
    final now=DateTime.now();
    final upcoming=[...store.events.where((e)=>e.dateTime.isAfter(now)),...store.reminders.where((r)=>r.dateTime.isAfter(now)&&!r.done)].toList();
    final saved=store.goals.fold<double>(0,(s,g)=>s+g.current), target=store.goals.fold<double>(0,(s,g)=>s+g.target);
    return PageFrame(title:'Light Coin',subtitle:DateFormat("EEEE, d 'tháng' M",'vi_VN').format(now),action:Container(width:44,height:44,decoration:BoxDecoration(gradient:const LinearGradient(colors:[_purple,_mint]),borderRadius:BorderRadius.circular(15)),child:const Icon(Icons.bolt_rounded,color:Colors.white)),child:Column(children:[
      Container(width:double.infinity,padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF6554F6),Color(0xFF7D68FF),Color(0xFF31CDAE)]),borderRadius:BorderRadius.circular(30),boxShadow:[BoxShadow(color:_purple.withValues(alpha:.24),blurRadius:28,offset:const Offset(0,12))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('TỔNG TIẾT KIỆM',style:TextStyle(color:Colors.white70,fontWeight:FontWeight.w700,fontSize:11,letterSpacing:1.2)),const SizedBox(height:9),Text(_money.format(saved),style:const TextStyle(color:Colors.white,fontSize:31,fontWeight:FontWeight.w800,letterSpacing:-1)),const SizedBox(height:16),ClipRRect(borderRadius:BorderRadius.circular(20),child:LinearProgressIndicator(value:target<=0?0.0:(saved/target).clamp(0.0,1.0).toDouble(),minHeight:8,backgroundColor:Colors.white24,valueColor:const AlwaysStoppedAnimation(Colors.white))),const SizedBox(height:9),Text(target<=0?'Tạo mục tiêu đầu tiên để bắt đầu':'${((saved/target)*100).clamp(0,999).toStringAsFixed(0)}% của ${_money.format(target)}',style:const TextStyle(color:Colors.white70,fontSize:12))])),
      const SizedBox(height:18),
      Row(children:[Expanded(child:_Quick(icon:Icons.event_available_rounded,label:'Tạo lịch',onTap:()=>_showEventForm(context,store))),const SizedBox(width:10),Expanded(child:_Quick(icon:Icons.add_card_rounded,label:'Tiết kiệm',onTap:()=>_showGoalForm(context,store))),const SizedBox(width:10),Expanded(child:_Quick(icon:Icons.alarm_add_rounded,label:'Nhắc hẹn',onTap:()=>_showReminderForm(context,store)))]),
      const SizedBox(height:26),_section(context,'Sắp tới',onTap:()=>onGo(1)),const SizedBox(height:10),
      if(upcoming.isEmpty)_Empty(icon:Icons.wb_sunny_outlined,title:'Lịch đang thoáng',text:'Thêm một việc quan trọng để Light Coin nhắc bạn đúng lúc.') else ...upcoming.take(3).map((x){final isEvent=x is CalendarItem;final dt=isEvent?(x as CalendarItem).dateTime:(x as ReminderItem).dateTime;final title=isEvent?(x as CalendarItem).title:(x as ReminderItem).title;return Padding(padding:const EdgeInsets.only(bottom:10),child:_Tile(icon:isEvent?Icons.calendar_today_rounded:Icons.notifications_rounded,title:title,subtitle:'${_day.format(dt)} • ${_time.format(dt)}',accent:isEvent?_purple:_mint));}),
      const SizedBox(height:16),_section(context,'Mục tiêu',onTap:()=>onGo(2)),const SizedBox(height:10),
      if(store.goals.isEmpty)_Empty(icon:Icons.savings_outlined,title:'Chưa có mục tiêu',text:'Một con số rõ ràng thường dễ theo đuổi hơn một lời hứa mơ hồ.') else ...store.goals.take(2).map((g)=>Padding(padding:const EdgeInsets.only(bottom:10),child:_GoalCard(goal:g,compact:true,onAdd:()=>_showAddMoney(context,store,g),onDelete:null))),
    ]));
  }
  Widget _section(BuildContext c,String t,{required VoidCallback onTap})=>Row(children:[Expanded(child:Text(t,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800))),TextButton(onPressed:onTap,child:const Text('Xem tất cả'))]);
}
class _Quick extends StatelessWidget{const _Quick({required this.icon,required this.label,required this.onTap});final IconData icon;final String label;final VoidCallback onTap;@override Widget build(BuildContext context)=>Material(color:Theme.of(context).cardTheme.color,borderRadius:BorderRadius.circular(22),child:InkWell(borderRadius:BorderRadius.circular(22),onTap:onTap,child:Padding(padding:const EdgeInsets.symmetric(vertical:17,horizontal:8),child:Column(children:[Container(width:42,height:42,decoration:BoxDecoration(color:_purple.withValues(alpha:.1),borderRadius:BorderRadius.circular(14)),child:Icon(icon,color:_purple,size:21)),const SizedBox(height:9),Text(label,textAlign:TextAlign.center,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700))]))));}
