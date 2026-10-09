import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'assignments_screen.dart';
import 'earnings_screen.dart';
import 'home_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.api, required this.onLogout});
  final ApiService api;
  final Future<void> Function() onLogout;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(api: widget.api, onSeeAll: () => setState(() => index = 1)),
      HomeScreen(api: widget.api, showAll: true),
      AssignmentsScreen(api: widget.api),
      EarningsScreen(api: widget.api),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: index, children: screens),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 71,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .98),
            borderRadius: BorderRadius.circular(27),
            boxShadow: const [
              BoxShadow(color: Color(0x1B143F6B), blurRadius: 26, offset: Offset(0, -3)),
            ],
          ),
          child: Row(
            children: [
              _NavigationTile(
                active: index == 0,
                icon: Icons.home_rounded,
                title: 'Início',
                onTap: () => setState(() => index = 0),
              ),
              _NavigationTile(
                active: index == 1,
                icon: Icons.search_rounded,
                title: 'Vagas',
                onTap: () => setState(() => index = 1),
              ),
              _NavigationTile(
                active: index == 2,
                icon: Icons.calendar_month_rounded,
                title: 'Meus turnos',
                onTap: () => setState(() => index = 2),
              ),
              _NavigationTile(
                active: index == 3,
                icon: Icons.account_balance_wallet_outlined,
                title: 'Ganhos',
                onTap: () => setState(() => index = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.active,
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final bool active;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: active ? const Color(0xFFE8F4FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(21),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(21),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 27,
                color: active ? TpColors.blue : const Color(0xFF6E7E98)),
              const SizedBox(height: 3),
              Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                  color: active ? TpColors.blue : const Color(0xFF6D7D98),
                )),
            ],
          ),
        ),
      ),
    );
  }
}
