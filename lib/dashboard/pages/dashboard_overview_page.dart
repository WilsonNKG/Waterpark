import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:waterpark/core/waterpark_brand.dart';
import 'package:waterpark/dashboard/widgets/dashboard_common.dart';

class DashboardOverviewPage extends StatelessWidget {
  const DashboardOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard Overview',
          style: TextStyle(
            color: WaterparkBrand.deepBlue,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 14),
        DashboardMetrics(),
        SizedBox(height: 16),
        DashboardChartsRow(),
        SizedBox(height: 16),
        DashboardBottomRow(),
      ],
    );
  }
}

class DashboardMetrics extends StatelessWidget {
  const DashboardMetrics({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = [
      MetricData(
        'Tickets Sold',
        '1,250',
        'Today',
        Icons.confirmation_num_outlined,
        WaterparkBrand.primaryBlue,
      ),
      MetricData(
        'Total Revenue',
        'IDR 18,750,000',
        'Today',
        Icons.shield_outlined,
        WaterparkBrand.success,
      ),
      MetricData(
        'Tickets Used',
        '1,102',
        'Today',
        Icons.local_activity_outlined,
        WaterparkBrand.accentRed,
      ),
      MetricData(
        'Active Visitors',
        '842',
        'Now',
        Icons.person_outline_rounded,
        WaterparkBrand.aqua,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth < 980 ? 2 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: count == 2 ? 152 : 148,
          ),
          itemBuilder: (context, index) => MetricCard(data: cards[index]),
        );
      },
    );
  }
}

class MetricData {
  const MetricData(
    this.title,
    this.value,
    this.subtitle,
    this.icon,
    this.color,
  );

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class MetricCard extends StatelessWidget {
  const MetricCard({required this.data, super.key});

  final MetricData data;

  @override
  Widget build(BuildContext context) {
    return BrandSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(data.icon, color: data.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(
                    color: Color(0xFF59718A),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            data.value,
            style: const TextStyle(
              color: WaterparkBrand.deepBlue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.subtitle,
            style: const TextStyle(color: WaterparkBrand.gray, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class DashboardChartsRow extends StatelessWidget {
  const DashboardChartsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 860;
        return stacked
            ? const Column(
                children: [
                  SalesOverviewCard(),
                  SizedBox(height: 14),
                  EntryStatusCard(),
                ],
              )
            : const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: SalesOverviewCard()),
                  SizedBox(width: 14),
                  Expanded(flex: 2, child: EntryStatusCard()),
                ],
              );
      },
    );
  }
}

class SalesOverviewCard extends StatelessWidget {
  const SalesOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BrandSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Sales Overview',
                style: TextStyle(
                  color: WaterparkBrand.deepBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD8E8F6)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'This Week',
                      style: TextStyle(
                        color: WaterparkBrand.deepBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SizedBox(height: 230, child: SalesChartPlaceholder()),
        ],
      ),
    );
  }
}

class SalesChartPlaceholder extends StatelessWidget {
  const SalesChartPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SalesChartPainter(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _AxisLabel('2.5M'),
                      _AxisLabel('2M'),
                      _AxisLabel('1.5M'),
                      _AxisLabel('1M'),
                      _AxisLabel('500K'),
                      _AxisLabel('0'),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: List.generate(
                        5,
                        (index) => Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              height: 1,
                              color: const Color(0xFFE6EFF8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _AxisLabel('Mon'),
                _AxisLabel('Tue'),
                _AxisLabel('Wed'),
                _AxisLabel('Thu'),
                _AxisLabel('Fri'),
                _AxisLabel('Sat'),
                _AxisLabel('Sun'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: WaterparkBrand.gray, fontSize: 11),
    );
  }
}

class SalesChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = Rect.fromLTWH(54, 14, size.width - 72, size.height - 46);
    final points =
        [
          const Offset(0.00, 0.72),
          const Offset(0.14, 0.58),
          const Offset(0.28, 0.66),
          const Offset(0.42, 0.54),
          const Offset(0.56, 0.60),
          const Offset(0.70, 0.34),
          const Offset(0.84, 0.46),
          const Offset(1.00, 0.28),
        ].map((point) {
          return Offset(
            chartRect.left + chartRect.width * point.dx,
            chartRect.top + chartRect.height * point.dy,
          );
        }).toList();

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final midX = (previous.dx + current.dx) / 2;
      path.cubicTo(midX, previous.dy, midX, current.dy, current.dx, current.dy);
    }

    final fill = Path.from(path)
      ..lineTo(points.last.dx, chartRect.bottom)
      ..lineTo(points.first.dx, chartRect.bottom)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x330077C8), Color(0x000077C8)],
        ).createShader(chartRect),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = WaterparkBrand.primaryBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = WaterparkBrand.primaryBlue);
      canvas.drawCircle(point, 8, Paint()..color = const Color(0x330077C8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EntryStatusCard extends StatelessWidget {
  const EntryStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BrandSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Entry Status',
            style: TextStyle(
              color: WaterparkBrand.deepBlue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 18),
          SizedBox(height: 230, child: EntryStatusContent()),
        ],
      ),
    );
  }
}

class EntryStatusContent extends StatelessWidget {
  const EntryStatusContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Center(
            child: SizedBox(width: 150, height: 150, child: DonutChart()),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LegendItem(
                color: WaterparkBrand.aqua,
                label: 'Used',
                value: '1,102 (75%)',
              ),
              SizedBox(height: 14),
              LegendItem(
                color: WaterparkBrand.primaryBlue,
                label: 'Not Used',
                value: '320 (22%)',
              ),
              SizedBox(height: 14),
              LegendItem(
                color: WaterparkBrand.accentRed,
                label: 'Void / Invalid',
                value: '48 (2%)',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DonutChart extends StatelessWidget {
  const DonutChart({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: DonutChartPainter());
  }
}

class DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const strokeWidth = 18.0;
    final rect = Rect.fromCircle(
      center: center,
      radius: math.min(size.width, size.height) / 2 - strokeWidth / 2,
    );

    final segments = [
      (WaterparkBrand.aqua, 0.75),
      (WaterparkBrand.primaryBlue, 0.22),
      (WaterparkBrand.accentRed, 0.03),
    ];

    var start = -math.pi / 2;
    for (final segment in segments) {
      final sweep = math.pi * 2 * segment.$2;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = segment.$1
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth,
      );
      start += sweep + 0.02;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LegendItem extends StatelessWidget {
  const LegendItem({
    required this.color,
    required this.label,
    required this.value,
    super.key,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: WaterparkBrand.deepBlue,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(color: WaterparkBrand.gray, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}

class DashboardBottomRow extends StatelessWidget {
  const DashboardBottomRow({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 880;
        return stacked
            ? const Column(
                children: [
                  RecentTransactionsCard(),
                  SizedBox(height: 14),
                  QuickActionsCard(),
                ],
              )
            : const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: RecentTransactionsCard()),
                  SizedBox(width: 14),
                  Expanded(child: QuickActionsCard()),
                ],
              );
      },
    );
  }
}

class RecentTransactionsCard extends StatelessWidget {
  const RecentTransactionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', 'INV-2506-001', 'Santi', 'IDR 1,250,000', '10:30', 'Success'],
      ['2', 'INV-2506-002', 'Rizky', 'IDR 980,000', '10:28', 'Success'],
      ['3', 'INV-2506-003', 'Dewi', 'IDR 750,000', '10:25', 'Success'],
      ['4', 'INV-2506-004', 'Budi', 'IDR 1,100,000', '10:20', 'Success'],
    ];

    return BrandSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Transactions',
            style: TextStyle(
              color: WaterparkBrand.deepBlue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FCFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE3EEF8)),
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(child: _HeaderCell('No.')),
                      Expanded(flex: 2, child: _HeaderCell('Receipt No.')),
                      Expanded(child: _HeaderCell('Cashier')),
                      Expanded(flex: 2, child: _HeaderCell('Total')),
                      Expanded(child: _HeaderCell('Time')),
                      Expanded(child: _HeaderCell('Status')),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE3EEF8)),
                for (final row in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _BodyCell(row[0])),
                        Expanded(flex: 2, child: _BodyCell(row[1])),
                        Expanded(child: _BodyCell(row[2])),
                        Expanded(flex: 2, child: _BodyCell(row[3])),
                        Expanded(child: _BodyCell(row[4])),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE7FAF0),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Success',
                                style: TextStyle(
                                  color: WaterparkBrand.success,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF6B829B),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: WaterparkBrand.deepBlue, fontSize: 13),
    );
  }
}

class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const BrandSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              color: WaterparkBrand.deepBlue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 16),
          QuickActionButton(
            label: 'New Ticket Sale',
            icon: Icons.add_rounded,
            gradient: WaterparkBrand.oceanGradient,
            foreground: Colors.white,
          ),
          SizedBox(height: 12),
          QuickActionButton(
            label: 'Scan Ticket',
            icon: Icons.qr_code_scanner_rounded,
            foreground: WaterparkBrand.aqua,
            borderColor: WaterparkBrand.aqua,
          ),
          SizedBox(height: 12),
          QuickActionButton(
            label: 'Void Ticket',
            icon: Icons.delete_outline_rounded,
            foreground: WaterparkBrand.accentRed,
            borderColor: WaterparkBrand.accentRed,
          ),
          SizedBox(height: 12),
          QuickActionButton(
            label: 'View Reports',
            icon: Icons.insert_chart_outlined_rounded,
            foreground: WaterparkBrand.primaryBlue,
            borderColor: WaterparkBrand.secondaryBlue,
          ),
        ],
      ),
    );
  }
}

class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    required this.label,
    required this.icon,
    required this.foreground,
    this.gradient,
    this.borderColor,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Gradient? gradient;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? Colors.white : null,
        borderRadius: BorderRadius.circular(12),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: foreground, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
