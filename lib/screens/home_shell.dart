import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'assignments_screen.dart';
import 'calendar_screen.dart';
import 'earnings_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.api}); final ApiService api;
  @override State<HomeShell> createState()=>_HomeShellState();
}
class _HomeShellState extends State<HomeShell>{
  int index=0;
  @override Widget build(BuildContext context){final screens=[HomeScreen(api:widget.api),AssignmentsScreen(api:widget.api),const CalendarScreen(),EarningsScreen(api:widget.api),const ProfileScreen()];return Scaffold(body:SafeArea(child:IndexedStack(index:index,children:screens)),bottomNavigationBar:NavigationBar(height:67,selectedIndex:index,onDestinationSelected:(i)=>setState(()=>index=i),indicatorColor:TpColors.blueSoft,destinations:const [NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home_rounded,color:TpColors.blue),label:'Início'),NavigationDestination(icon:Icon(Icons.calendar_today_outlined),selectedIcon:Icon(Icons.calendar_month_rounded,color:TpColors.blue),label:'Turnos'),NavigationDestination(icon:Icon(Icons.event_outlined),selectedIcon:Icon(Icons.event_rounded,color:TpColors.blue),label:'Agenda'),NavigationDestination(icon:Icon(Icons.account_balance_wallet_outlined),selectedIcon:Icon(Icons.account_balance_wallet_rounded,color:TpColors.blue),label:'Ganhos'),NavigationDestination(icon:Icon(Icons.person_outline_rounded),selectedIcon:Icon(Icons.person_rounded,color:TpColors.blue),label:'Perfil')]));}
}
