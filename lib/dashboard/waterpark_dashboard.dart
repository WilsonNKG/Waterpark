import 'package:flutter/material.dart';
import 'package:waterpark/core/app_section.dart';
import 'package:waterpark/core/waterpark_brand.dart';
import 'package:waterpark/dashboard/pages/dashboard_overview_page.dart';
import 'package:waterpark/dashboard/pages/ticketing_overview_page.dart';
import 'package:waterpark/dashboard/widgets/dashboard_common.dart';

class WaterparkDashboard extends StatefulWidget {
  const WaterparkDashboard({super.key});

  @override
  State<WaterparkDashboard> createState() => _WaterparkDashboardState();
}

class _WaterparkDashboardState extends State<WaterparkDashboard> {
  AppSection _selectedSection = AppSection.dashboard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DashboardDrawer(
        selected: _selectedSection,
        onSelect: (section) {
          setState(() {
            _selectedSection = section;
          });
          Navigator.of(context).maybePop();
        },
      ),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: -80,
              right: -70,
              child: BackgroundOrb(size: 280, color: Color(0x114CB6F5)),
            ),
            const Positioned(
              bottom: -120,
              left: -60,
              child: BackgroundOrb(size: 260, color: Color(0x1000B8A9)),
            ),
            SingleChildScrollView(
              child: DashboardMainPanel(selected: _selectedSection),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final AppSection selected;
  final ValueChanged<AppSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = [
      (AppSection.dashboard, 'Dashboard', Icons.home_outlined),
      (AppSection.ticketing, 'Ticketing', Icons.confirmation_num_outlined),
      (
        AppSection.scanValidation,
        'Scan & Validation',
        Icons.qr_code_scanner_rounded,
      ),
      (AppSection.sales, 'Sales', Icons.point_of_sale_outlined),
      (AppSection.reports, 'Reports', Icons.bar_chart_outlined),
      (AppSection.settings, 'Settings', Icons.settings_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: WaterparkBrand.oceanGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Menu',
              style: TextStyle(
                color: WaterparkBrand.deepBlue,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        for (final item in items) ...[
          SidebarItem(
            title: item.$2,
            icon: item.$3,
            active: selected == item.$1,
            onTap: () => onSelect(item.$1),
          ),
          if (item != items.last) const SizedBox(height: 10),
        ],
        const Spacer(),
        Container(
          width: double.infinity,
          height: 1,
          color: const Color(0xFFE1EDF8),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Icon(
              Icons.waves_rounded,
              color: WaterparkBrand.secondaryBlue,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Puri Nirwana Waterpark',
              style: TextStyle(
                color: WaterparkBrand.gray,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DashboardDrawer extends StatelessWidget {
  const DashboardDrawer({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final AppSection selected;
  final ValueChanged<AppSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 292,
      backgroundColor: WaterparkBrand.surface,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9FDFF), Color(0xFFF1F8FF)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            child: SizedBox.expand(
              child: DashboardSidebar(selected: selected, onSelect: onSelect),
            ),
          ),
        ),
      ),
    );
  }
}

class SidebarItem extends StatelessWidget {
  const SidebarItem({
    required this.title,
    required this.icon,
    required this.active,
    required this.onTap,
    super.key,
  });

  final String title;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: active ? WaterparkBrand.lightBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: active
                    ? WaterparkBrand.primaryBlue
                    : WaterparkBrand.gray,
                size: 21,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: active
                      ? WaterparkBrand.primaryBlue
                      : WaterparkBrand.deepBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardMainPanel extends StatelessWidget {
  const DashboardMainPanel({required this.selected, super.key});

  final AppSection selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        const DashboardTopBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
          child: switch (selected) {
            AppSection.dashboard => const DashboardOverviewPage(),
            AppSection.ticketing => const TicketingOverviewPage(),
            _ => const SectionPlaceholder(),
          },
        ),
      ],
    );
  }
}

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: WaterparkBrand.oceanGradient,
        boxShadow: const [
          BoxShadow(
            color: Color(0x220077C8),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              return Semantics(
                button: true,
                label: 'Open navigation',
                child: GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.menu_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                SizedBox(height: 2),
                Text(
                  'Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const TopBarIcon(Icons.search_rounded),
          const SizedBox(width: 10),
          const TopBarIcon(Icons.notifications_none_rounded, badge: '3'),
          const SizedBox(width: 10),
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: WaterparkBrand.gray),
          ),
        ],
      ),
    );
  }
}

class TopBarIcon extends StatelessWidget {
  const TopBarIcon(this.icon, {this.badge, super.key});

  final IconData icon;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        if (badge != null)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: WaterparkBrand.accentRed,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class SectionPlaceholder extends StatelessWidget {
  const SectionPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const BrandSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This section is next',
            style: TextStyle(
              color: WaterparkBrand.deepBlue,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'The menu works now. We can design this module after Ticketing is approved.',
            style: TextStyle(color: WaterparkBrand.gray, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class BackgroundOrb extends StatelessWidget {
  const BackgroundOrb({required this.size, required this.color, super.key});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
