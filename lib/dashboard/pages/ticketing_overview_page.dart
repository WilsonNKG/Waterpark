import 'package:flutter/material.dart';
import 'package:waterpark/core/waterpark_brand.dart';
import 'package:waterpark/dashboard/widgets/dashboard_common.dart';

class TicketingOverviewPage extends StatelessWidget {
  const TicketingOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ticketing',
          style: TextStyle(
            color: WaterparkBrand.deepBlue,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Suggested model: create one batch, generate a code range for that batch, then each printed ticket carries its own unique QR or barcode.',
          style: TextStyle(
            color: WaterparkBrand.gray,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        SizedBox(height: 16),
        TicketingWorkflowRow(),
        SizedBox(height: 16),
        TicketingBatchDraft(),
        SizedBox(height: 16),
        TicketingIdeaNotes(),
      ],
    );
  }
}

class TicketingWorkflowRow extends StatelessWidget {
  const TicketingWorkflowRow({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (
        '1. Create Batch',
        'Choose ticket type, date, price, and how many tickets.',
        Icons.inventory_2_outlined,
        WaterparkBrand.primaryBlue,
      ),
      (
        '2. Generate Codes',
        'System creates unique codes like WKD-20260623-0001.',
        Icons.qr_code_2_rounded,
        WaterparkBrand.aqua,
      ),
      (
        '3. Print / Export',
        'Print physical tickets or export QR sheets for gate use.',
        Icons.print_outlined,
        WaterparkBrand.warning,
      ),
      (
        '4. Scan & Validate',
        'Gate scanner marks each code as used once only.',
        Icons.verified_outlined,
        WaterparkBrand.success,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 920 ? 2 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: steps.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 152,
          ),
          itemBuilder: (context, index) {
            final step = steps[index];
            return BrandSurface(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: step.$4.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(step.$3, color: step.$4, size: 20),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    step.$1,
                    style: const TextStyle(
                      color: WaterparkBrand.deepBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.$2,
                    style: const TextStyle(
                      color: WaterparkBrand.gray,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class TicketingBatchDraft extends StatelessWidget {
  const TicketingBatchDraft({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 880;
        return stacked
            ? const Column(
                children: [
                  TicketBatchTableCard(),
                  SizedBox(height: 16),
                  BarcodeConceptCard(),
                ],
              )
            : const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: TicketBatchTableCard()),
                  SizedBox(width: 16),
                  Expanded(flex: 2, child: BarcodeConceptCard()),
                ],
              );
      },
    );
  }
}

class TicketBatchTableCard extends StatelessWidget {
  const TicketBatchTableCard({super.key});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['WKD-2306-A', 'Weekday', '500', 'WKD-20260623-0001', 'Ready'],
      ['WND-2306-A', 'Weekend', '350', 'WND-20260623-0001', 'Ready'],
      ['GRP-2306-A', 'Group', '200', 'GRP-20260623-0001', 'Draft'],
    ];

    return BrandSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Batch Draft',
            style: TextStyle(
              color: WaterparkBrand.deepBlue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Each batch has a label, ticket category, quantity, and a generated sequence start.',
            style: TextStyle(color: WaterparkBrand.gray, height: 1.4),
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
                      Expanded(flex: 2, child: TicketHeaderCell('Batch')),
                      Expanded(child: TicketHeaderCell('Type')),
                      Expanded(child: TicketHeaderCell('Qty')),
                      Expanded(flex: 2, child: TicketHeaderCell('First Code')),
                      Expanded(child: TicketHeaderCell('Status')),
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
                        Expanded(flex: 2, child: TicketBodyCell(row[0])),
                        Expanded(child: TicketBodyCell(row[1])),
                        Expanded(child: TicketBodyCell(row[2])),
                        Expanded(flex: 2, child: TicketBodyCell(row[3])),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: row[4] == 'Ready'
                                    ? const Color(0xFFE7FAF0)
                                    : const Color(0xFFFFF4DA),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                row[4],
                                style: TextStyle(
                                  color: row[4] == 'Ready'
                                      ? WaterparkBrand.success
                                      : WaterparkBrand.warning,
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

class BarcodeConceptCard extends StatelessWidget {
  const BarcodeConceptCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BrandSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Barcode Idea',
            style: TextStyle(
              color: WaterparkBrand.deepBlue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Best practice is not one barcode for the whole batch. Use one batch to generate many unique ticket codes.',
            style: TextStyle(color: WaterparkBrand.gray, height: 1.45),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: WaterparkBrand.oceanGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Example QR payload',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                SizedBox(height: 8),
                Text(
                  'WKD-20260623-0148',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const TicketingBullet(
            'Batch = a production group, not the final scan code.',
          ),
          const TicketingBullet(
            'Every visitor ticket should have a unique QR so one scan cannot be reused.',
          ),
          const TicketingBullet(
            'You can still track all tickets under the same batch number for reporting.',
          ),
        ],
      ),
    );
  }
}

class TicketingIdeaNotes extends StatelessWidget {
  const TicketingIdeaNotes({super.key});

  @override
  Widget build(BuildContext context) {
    return const BrandSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended Ticket Model',
            style: TextStyle(
              color: WaterparkBrand.deepBlue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          TicketingBullet(
            'Create ticket templates first: Weekday, Weekend, Group, Promo.',
          ),
          TicketingBullet(
            'When staff opens a new batch, the system stores batch metadata and quantity.',
          ),
          TicketingBullet(
            'System auto-generates unique QR codes inside that batch range.',
          ),
          TicketingBullet(
            'Gate scanner reads the unique code and checks status: unused, used, void, expired.',
          ),
          TicketingBullet(
            'Reports can still summarize by batch, date, ticket type, and cashier.',
          ),
        ],
      ),
    );
  }
}

class TicketingBullet extends StatelessWidget {
  const TicketingBullet(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: WaterparkBrand.aqua,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: WaterparkBrand.gray,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TicketHeaderCell extends StatelessWidget {
  const TicketHeaderCell(this.text, {super.key});

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

class TicketBodyCell extends StatelessWidget {
  const TicketBodyCell(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: WaterparkBrand.deepBlue, fontSize: 13),
    );
  }
}
