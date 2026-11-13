import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _forest = Color(0xFF14532D);
const _green = Color(0xFF237A50);
const _paper = Color(0xFFF8FAF8);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _gold = Color(0xFFFBC02D);
const _stroke = Color(0xFFE2EBE4);

class LguAdminShell extends StatelessWidget {
  final Widget child;
  const LguAdminShell({super.key, required this.child});

  static const _items = [
    _NavItem('Overview', Icons.dashboard_rounded, '/lgu-admin/dashboard'),
    _NavItem('Organizations', Icons.apartment_rounded, '/lgu-admin/organizations'),
    _NavItem('Admin Assignments', Icons.admin_panel_settings_rounded, '/lgu-admin/assignments'),
    _NavItem('Event Monitoring', Icons.event_available_rounded, '/lgu-admin/events'),
    _NavItem('Reports', Icons.bar_chart_rounded, '/lgu-admin/reports'),
    _NavItem('Audit Logs', Icons.history_rounded, '/lgu-admin/audit-logs'),
    _NavItem('Settings', Icons.settings_rounded, '/lgu-admin/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 1000;
    final path = GoRouterState.of(context).uri.path;
    final selected = _items.firstWhere((item) => item.path == path,
      orElse: () => _items.first);

    return Scaffold(
      backgroundColor: _paper,
      drawer: desktop ? null : Drawer(
        backgroundColor: _forest,
        child: _navigation(context, path, mobile: true),
      ),
      body: Row(children: [
        if (desktop) SizedBox(width: 268,
          child: _navigation(context, path, mobile: false)),
        Expanded(child: Column(children: [
          _topBar(selected.title, desktop),
          Expanded(child: child),
        ])),
      ]),
    );
  }

  Widget _navigation(BuildContext context, String path,
      {required bool mobile}) => ColoredBox(
    color: _forest,
    child: SafeArea(child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 18, 30),
        child: Row(children: [
          Container(
            height: 51, width: 51,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(15)),
            // Adjust this path if your logo PNG uses a different file name.
            child: Image.asset('assets/images/kaisa_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.diversity_3_rounded, color: _green, size: 30)),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('KAISA', style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w900, fontSize: 24,
                letterSpacing: -.5)),
              SizedBox(height: 3),
              Text('LGU ADMINISTRATION', style: TextStyle(
                color: Color(0xFFC3DDCE), letterSpacing: 1.1,
                fontWeight: FontWeight.w700, fontSize: 9)),
            ],
          )),
        ]),
      ),
      Expanded(child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 13),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(13, 0, 13, 14),
            child: Text('WORKSPACE', style: TextStyle(
              color: Color(0xFFA8D5B9), letterSpacing: 1.6,
              fontWeight: FontWeight.w900, fontSize: 10)),
          ),
          for (final item in _items) _navigationLink(context, item, path, mobile),
        ],
      )),
      Container(
        padding: const EdgeInsets.all(17),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF3D7353)))),
        child: const Row(children: [
          CircleAvatar(backgroundColor: _gold,
            child: Icon(Icons.shield_outlined, color: _forest)),
          SizedBox(width: 11),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LGU Administrator', style: TextStyle(
                color: Colors.white, fontSize: 12,
                fontWeight: FontWeight.w800)),
              SizedBox(height: 3),
              Text('Development preview', style: TextStyle(
                color: Color(0xFFC3DDCE), fontSize: 11)),
            ],
          )),
        ]),
      ),
    ])),
  );

  Widget _navigationLink(BuildContext context, _NavItem item,
      String path, bool mobile) {
    final selected = item.path == path;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? Colors.white.withValues(alpha: .13) : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () {
            if (mobile) Navigator.of(context).pop();
            if (path != item.path) GoRouter.of(context).go(item.path);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            child: Row(children: [
              Icon(item.icon, size: 21, color: selected ? _gold :
                const Color(0xFFD1E8D9)),
              const SizedBox(width: 13),
              Expanded(child: Text(item.title, style: TextStyle(
                color: Colors.white, fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500))),
              if (selected) Container(width: 5, height: 5,
                decoration: const BoxDecoration(
                  color: _gold, shape: BoxShape.circle)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _topBar(String title, bool desktop) => Container(
    height: 76,
    padding: const EdgeInsets.symmetric(horizontal: 22),
    decoration: const BoxDecoration(color: Colors.white,
      border: Border(bottom: BorderSide(color: _stroke))),
    child: Builder(builder: (context) => Row(children: [
      if (!desktop) ...[
        IconButton(
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: const Icon(Icons.menu_rounded, color: _forest)),
        const SizedBox(width: 6),
      ],
      Expanded(child: Text(title, style: const TextStyle(
        color: _ink, fontSize: 19, fontWeight: FontWeight.w900))),
      const Icon(Icons.shield_outlined, color: _green, size: 18),
      const SizedBox(width: 8),
      const Text('LGU Portal', style: TextStyle(
        color: _muted, fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(width: 15),
      const CircleAvatar(radius: 18, backgroundColor: Color(0xFFE6F2EA),
        child: Icon(Icons.person_outline_rounded, color: _forest)),
    ])),
  );
}

class _NavItem {
  final String title;
  final IconData icon;
  final String path;
  const _NavItem(this.title, this.icon, this.path);
}
