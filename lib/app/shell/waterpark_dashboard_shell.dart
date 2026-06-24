import 'package:flutter/material.dart';
import 'package:waterpark/app/navigation/app_section.dart';
import 'package:waterpark/core/theme/waterpark_brand.dart';
import 'package:waterpark/features/dashboard/presentation/pages/dashboard_overview_page.dart';
import 'package:waterpark/features/qr_scan/presentation/pages/qr_scan_page.dart';
import 'package:waterpark/features/staff_access/presentation/pages/staff_access_page.dart';
import 'package:waterpark/features/ticketing/presentation/pages/ticketing_overview_page.dart';
import 'package:waterpark/shared/widgets/brand_surface.dart';

const kWaterparkLogoAsset = 'logo waterpark.png';

class WaterparkDashboardShell extends StatefulWidget {
  const WaterparkDashboardShell({super.key});

  @override
  State<WaterparkDashboardShell> createState() =>
      _WaterparkDashboardShellState();
}

class _WaterparkDashboardShellState extends State<WaterparkDashboardShell> {
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
      body: Stack(
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
      (AppSection.staffAccess, 'Staff Access', Icons.badge_outlined),
      (AppSection.qrScan, 'QR Scan', Icons.qr_code_scanner_rounded),
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
        const DashboardTopBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
          child: switch (selected) {
            AppSection.dashboard => const DashboardOverviewPage(),
            AppSection.ticketing => const TicketingOverviewPage(),
            AppSection.staffAccess => const StaffAccessPage(),
            AppSection.qrScan => const QrScanPage(),
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
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              Builder(
                builder: (context) {
                  return Semantics(
                    button: true,
                    label: 'Open navigation',
                    child: GestureDetector(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.menu_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              const ConnectivityStatusIndicator(
                status: ConnectivityState.good,
                tooltip: 'Connected',
              ),
              const SizedBox(width: 12),
              const TopBarIcon(Icons.refresh_rounded, tooltip: 'Refresh'),
              const SizedBox(width: 10),
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: WaterparkBrand.gray, size: 18),
              ),
            ],
          ),
          IgnorePointer(
            child: Image.asset(
              kWaterparkLogoAsset,
              height: 58,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class TopBarIcon extends StatelessWidget {
  const TopBarIcon(this.icon, {required this.tooltip, super.key});

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 24,
        height: 24,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

enum ConnectivityState { good, warning, poor }

class ConnectivityStatusIndicator extends StatelessWidget {
  const ConnectivityStatusIndicator({
    required this.status,
    required this.tooltip,
    super.key,
  });

  final ConnectivityState status;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ConnectivityState.good => const Color(0xFF3CD56C),
      ConnectivityState.warning => const Color(0xFFFFC247),
      ConnectivityState.poor => const Color(0xFFFF5D59),
    };

    return Tooltip(
      message: tooltip,
      child: Icon(Icons.wifi_rounded, color: color, size: 20),
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
