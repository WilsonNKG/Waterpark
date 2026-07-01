import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:waterpark/core/theme/waterpark_brand.dart';
import 'package:waterpark/shared/widgets/brand_surface.dart';

class TicketingOverviewPage extends StatefulWidget {
  const TicketingOverviewPage({super.key});

  @override
  State<TicketingOverviewPage> createState() => _TicketingOverviewPageState();
}

class _TicketingOverviewPageState extends State<TicketingOverviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _batchLabelController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _operatorController = TextEditingController();

  final List<TicketBatchRecord> _batches = [];

  String _selectedType = 'Weekday';
  DateTime _selectedDate = DateTime.now();
  int _selectedBatchIndex = 0;

  @override
  void dispose() {
    _batchLabelController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _operatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalTickets = _batches.fold<int>(
      0,
      (sum, batch) => sum + batch.quantity,
    );
    final usedTickets = _batches.fold<int>(0, (sum, batch) => sum + batch.used);
    final voidedTickets = _batches.fold<int>(
      0,
      (sum, batch) => sum + batch.voided,
    );
    final readyTickets = _batches.fold<int>(
      0,
      (sum, batch) => sum + batch.ready,
    );
    final selectedBatch = _batches.isEmpty ? null : _batches[_selectedBatchIndex];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ticketing',
            style: TextStyle(
              color: WaterparkBrand.deepBlue,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This page is now active for batch setup and code generation. Create a batch, review the generated codes, and update ticket status from the same screen.',
            style: TextStyle(
              color: WaterparkBrand.gray,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          TicketSummaryRow(
            totalTickets: totalTickets,
            readyTickets: readyTickets,
            usedTickets: usedTickets,
            voidedTickets: voidedTickets,
          ),
          const SizedBox(height: 16),
          BatchSelectionOverviewCard(
            totalBatches: _batches.length,
            activeBatch: selectedBatch,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 1180;
              if (stacked) {
                return Column(
                  children: [
                    TicketBatchCreateCard(
                      formKey: _formKey,
                      batchLabelController: _batchLabelController,
                      priceController: _priceController,
                      quantityController: _quantityController,
                      operatorController: _operatorController,
                      selectedType: _selectedType,
                      selectedDate: _selectedDate,
                      onTypeChanged: (value) {
                        setState(() {
                          _selectedType = value;
                        });
                      },
                      onDateTap: _pickVisitDate,
                      onCreateBatch: _createBatch,
                    ),
                    const SizedBox(height: 16),
                    TicketBatchTableCard(
                      batches: _batches,
                      selectedBatchIndex: _selectedBatchIndex,
                      onSelectBatch: _openBatchDetails,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        TicketBatchCreateCard(
                          formKey: _formKey,
                          batchLabelController: _batchLabelController,
                          priceController: _priceController,
                          quantityController: _quantityController,
                          operatorController: _operatorController,
                          selectedType: _selectedType,
                          selectedDate: _selectedDate,
                          onTypeChanged: (value) {
                            setState(() {
                              _selectedType = value;
                            });
                          },
                          onDateTap: _pickVisitDate,
                          onCreateBatch: _createBatch,
                        ),
                        const SizedBox(height: 16),
                        TicketBatchTableCard(
                          batches: _batches,
                          selectedBatchIndex: _selectedBatchIndex,
                          onSelectBatch: _openBatchDetails,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickVisitDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  void _createBatch() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final quantity = int.parse(_quantityController.text.trim());
    final price = _parseCurrency(_priceController.text)!;

    final batch = TicketBatchRecord.create(
      batchLabel: _batchLabelController.text.trim().toUpperCase(),
      type: _selectedType,
      quantity: quantity,
      price: price,
      visitDate: _selectedDate,
      operator: _operatorController.text.trim(),
    );

    setState(() {
      _batches.insert(0, batch);
      _selectedBatchIndex = 0;
      _batchLabelController.clear();
      _priceController.clear();
      _quantityController.clear();
      _operatorController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Created ${batch.batchLabel} with ${batch.quantity} tickets.',
        ),
      ),
    );
  }

  void _updateTicketStatus(String ticketCode, TicketStatus status) {
    if (_batches.isEmpty) {
      return;
    }

    final batch = _batches[_selectedBatchIndex];
    final ticketIndex = batch.tickets.indexWhere(
      (ticket) => ticket.code == ticketCode,
    );
    if (ticketIndex == -1) {
      return;
    }

    setState(() {
      batch.tickets[ticketIndex] = batch.tickets[ticketIndex].copyWith(
        status: status,
        scannedAt: status == TicketStatus.used ? DateTime.now() : null,
      );
    });
  }

  Future<void> _openBatchDetails(int index) async {
    setState(() {
      _selectedBatchIndex = index;
    });

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TicketBatchDetailsPage(
          batch: _batches[index],
          onTicketStatusChanged: _updateTicketStatus,
        ),
      ),
    );
  }
}

class TicketSummaryRow extends StatelessWidget {
  const TicketSummaryRow({
    required this.totalTickets,
    required this.readyTickets,
    required this.usedTickets,
    required this.voidedTickets,
    super.key,
  });

  final int totalTickets;
  final int readyTickets;
  final int usedTickets;
  final int voidedTickets;

  @override
  Widget build(BuildContext context) {
    final cards = [
      ('Tickets Generated', '$totalTickets', Icons.confirmation_num_outlined,
          WaterparkBrand.primaryBlue),
      ('Ready To Scan', '$readyTickets', Icons.qr_code_2_rounded,
          WaterparkBrand.aqua),
      ('Used Tickets', '$usedTickets', Icons.verified_outlined,
          WaterparkBrand.success),
      ('Voided Tickets', '$voidedTickets', Icons.block_rounded,
          WaterparkBrand.warning),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 920 ? 2 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 140,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            return BrandSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: card.$4.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(card.$3, color: card.$4, size: 20),
                  ),
                  const Spacer(),
                  Text(
                    card.$2,
                    style: const TextStyle(
                      color: WaterparkBrand.deepBlue,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.$1,
                    style: const TextStyle(
                      color: WaterparkBrand.gray,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

class BatchSelectionOverviewCard extends StatelessWidget {
  const BatchSelectionOverviewCard({
    required this.totalBatches,
    required this.activeBatch,
    super.key,
  });

  final int totalBatches;
  final TicketBatchRecord? activeBatch;

  @override
  Widget build(BuildContext context) {
    return BrandSurface(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 880;
          final activeLabel = activeBatch?.batchLabel ?? 'No batch selected';
          final activeMeta = activeBatch == null
              ? 'Create a batch, then click it to preview all tickets and statuses.'
              : '${activeBatch!.type} • ${activeBatch!.tickets.length} tickets • ${activeBatch!.batchStatusLabel}';

          final totalCard = _BatchOverviewMetric(
            title: 'All Batches',
            value: '$totalBatches',
            subtitle: totalBatches == 1 ? '1 batch created' : '$totalBatches batches created',
            icon: Icons.layers_rounded,
            color: WaterparkBrand.primaryBlue,
          );

          final activeCard = _BatchOverviewMetric(
            title: 'Active Batch',
            value: activeLabel,
            subtitle: activeMeta,
            icon: Icons.local_activity_rounded,
            color: activeBatch?.batchStatusColor ?? WaterparkBrand.aqua,
          );

          if (stacked) {
            return Column(
              children: [
                totalCard,
                const SizedBox(height: 12),
                activeCard,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: totalCard),
              const SizedBox(width: 12),
              Expanded(child: activeCard),
            ],
          );
        },
      ),
    );
  }
}

class _BatchOverviewMetric extends StatelessWidget {
  const _BatchOverviewMetric({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FCFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EEF8)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: WaterparkBrand.gray,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WaterparkBrand.deepBlue,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: WaterparkBrand.gray,
                    fontSize: 13,
                    height: 1.4,
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

class TicketBatchCreateCard extends StatelessWidget {
  const TicketBatchCreateCard({
    required this.formKey,
    required this.batchLabelController,
    required this.priceController,
    required this.quantityController,
    required this.operatorController,
    required this.selectedType,
    required this.selectedDate,
    required this.onTypeChanged,
    required this.onDateTap,
    required this.onCreateBatch,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController batchLabelController;
  final TextEditingController priceController;
  final TextEditingController quantityController;
  final TextEditingController operatorController;
  final String selectedType;
  final DateTime selectedDate;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onDateTap;
  final VoidCallback onCreateBatch;

  @override
  Widget build(BuildContext context) {
    return BrandSurface(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Ticket Batch',
                        style: TextStyle(
                          color: WaterparkBrand.deepBlue,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Set the batch details once, then the page generates a unique code sequence for every ticket in that batch.',
                        style: TextStyle(
                          color: WaterparkBrand.gray,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: onCreateBatch,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Generate Batch'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 900;
                if (stacked) {
                  return Column(
                    children: [
                      TicketingTextField(
                        controller: batchLabelController,
                        label: 'Batch Label',
                        hint: 'Ex: WKD-2906-A',
                        required: true,
                      ),
                      const SizedBox(height: 12),
                      _TypePicker(
                        selectedType: selectedType,
                        onChanged: onTypeChanged,
                        required: true,
                      ),
                      const SizedBox(height: 12),
                      _DateField(
                        selectedDate: selectedDate,
                        onTap: onDateTap,
                        required: true,
                      ),
                      const SizedBox(height: 12),
                      TicketingTextField(
                        controller: quantityController,
                        label: 'Quantity',
                        hint: 'Ex: 100',
                        keyboardType: TextInputType.number,
                        required: true,
                      ),
                      const SizedBox(height: 12),
                      TicketingTextField(
                        controller: priceController,
                        label: 'Price',
                        hint: 'Ex: 75.000',
                        keyboardType: TextInputType.number,
                        required: true,
                        isCurrency: true,
                      ),
                      const SizedBox(height: 12),
                      TicketingTextField(
                        controller: operatorController,
                        label: 'Operator',
                        hint: 'Ex: Front Desk',
                        required: true,
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TicketingTextField(
                            controller: batchLabelController,
                            label: 'Batch Label',
                            hint: 'Ex: WKD-2906-A',
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TypePicker(
                            selectedType: selectedType,
                            onChanged: onTypeChanged,
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            selectedDate: selectedDate,
                            onTap: onDateTap,
                            required: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TicketingTextField(
                            controller: quantityController,
                            label: 'Quantity',
                            hint: 'Ex: 100',
                            keyboardType: TextInputType.number,
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TicketingTextField(
                            controller: priceController,
                            label: 'Price',
                            hint: 'Ex: 75.000',
                            keyboardType: TextInputType.number,
                            required: true,
                            isCurrency: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TicketingTextField(
                            controller: operatorController,
                            label: 'Operator',
                            hint: 'Ex: Front Desk',
                            required: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TicketBatchTableCard extends StatelessWidget {
  const TicketBatchTableCard({
    required this.batches,
    required this.selectedBatchIndex,
    required this.onSelectBatch,
    super.key,
  });

  final List<TicketBatchRecord> batches;
  final int selectedBatchIndex;
  final ValueChanged<int> onSelectBatch;

  @override
  Widget build(BuildContext context) {
    return BrandSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Batches',
            style: TextStyle(
              color: WaterparkBrand.deepBlue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a batch to make it active, then review its generated ticket codes and live ticket status.',
            style: TextStyle(color: WaterparkBrand.gray, height: 1.4),
          ),
          const SizedBox(height: 14),
          if (batches.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FCFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE3EEF8)),
              ),
              child: const Text(
              'No ticket batches yet. Create your first batch from the form above and it will appear here.',
                style: TextStyle(
                  color: WaterparkBrand.gray,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            )
          else
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
                  for (var index = 0; index < batches.length; index++)
                    InkWell(
                      onTap: () => onSelectBatch(index),
                      child: Container(
                        color: index == selectedBatchIndex
                            ? const Color(0xFFEFF7FF)
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TicketBodyCell(batches[index].batchLabel),
                            ),
                            Expanded(
                              child: TicketBodyCell(batches[index].type),
                            ),
                            Expanded(
                              child: TicketBodyCell('${batches[index].quantity}'),
                            ),
                            Expanded(
                              flex: 2,
                              child: TicketBodyCell(batches[index].firstCode),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: TicketStatusPill(
                                  label: batches[index].batchStatusLabel,
                                  color: batches[index].batchStatusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
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

class TicketBatchDetailsPage extends StatefulWidget {
  const TicketBatchDetailsPage({
    required this.batch,
    required this.onTicketStatusChanged,
    super.key,
  });

  final TicketBatchRecord? batch;
  final void Function(String ticketCode, TicketStatus status)
      onTicketStatusChanged;

  @override
  State<TicketBatchDetailsPage> createState() => _TicketBatchDetailsPageState();
}

class _TicketBatchDetailsPageState extends State<TicketBatchDetailsPage> {
  @override
  Widget build(BuildContext context) {
    if (widget.batch == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4FAFF),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: WaterparkBrand.deepBlue,
          title: const Text('Batch Details'),
        ),
        body: const Padding(
          padding: EdgeInsets.all(20),
          child: BrandSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Batch Details',
                  style: TextStyle(
                    color: WaterparkBrand.deepBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'No batch is selected yet. Return to the ticketing page and choose a batch to see its tickets.',
                  style: TextStyle(
                    color: WaterparkBrand.gray,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentBatch = widget.batch!;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: WaterparkBrand.deepBlue,
        title: Text(currentBatch.batchLabel),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: TicketBatchDetailCard(
            batch: currentBatch,
            onTicketStatusChanged: (ticketCode, status) {
              setState(() {
                widget.onTicketStatusChanged(ticketCode, status);
              });
            },
          ),
        ),
      ),
    );
  }
}

class TicketBatchDetailCard extends StatelessWidget {
  const TicketBatchDetailCard({
    required this.batch,
    required this.onTicketStatusChanged,
    super.key,
  });

  final TicketBatchRecord batch;
  final void Function(String ticketCode, TicketStatus status)
      onTicketStatusChanged;

  @override
  Widget build(BuildContext context) {
    return BrandSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batch.batchLabel,
                      style: const TextStyle(
                        color: WaterparkBrand.deepBlue,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${batch.type} • ${_formatDate(batch.visitDate)} • ${batch.operator}',
                      style: const TextStyle(
                        color: WaterparkBrand.gray,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TicketStatusPill(
                label: batch.batchStatusLabel,
                color: batch.batchStatusColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: WaterparkBrand.oceanGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'First ticket QR payload',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        batch.firstCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: batch.firstCode,
                    size: 96,
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              TicketStatusPill(
                label: '${batch.ready} Ready',
                color: WaterparkBrand.aqua,
              ),
              TicketStatusPill(
                label: '${batch.used} Used',
                color: WaterparkBrand.success,
              ),
              TicketStatusPill(
                label: '${batch.voided} Void',
                color: WaterparkBrand.warning,
              ),
              TicketStatusPill(
                label: _formatRupiah(batch.price),
                color: WaterparkBrand.primaryBlue,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Batch Tickets (${batch.tickets.length})',
            style: TextStyle(
              color: WaterparkBrand.deepBlue,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Each ticket below belongs to this batch and has its own QR. The card uses a ticket-style artwork placeholder for now, so we can replace it later with the real printed ticket design.',
            style: TextStyle(
              color: WaterparkBrand.gray,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 760,
            child: ListView.separated(
              itemCount: batch.tickets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ticket = batch.tickets[index];
                return TicketVisualCard(
                  batch: batch,
                  ticket: ticket,
                  ticketNumber: index + 1,
                  onUse: () =>
                      onTicketStatusChanged(ticket.code, TicketStatus.used),
                  onReset: () =>
                      onTicketStatusChanged(ticket.code, TicketStatus.ready),
                  onVoid: () =>
                      onTicketStatusChanged(ticket.code, TicketStatus.voided),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TicketVisualCard extends StatelessWidget {
  const TicketVisualCard({
    required this.batch,
    required this.ticket,
    required this.ticketNumber,
    required this.onUse,
    required this.onReset,
    required this.onVoid,
    super.key,
  });

  final TicketBatchRecord batch;
  final TicketRecord ticket;
  final int ticketNumber;
  final VoidCallback onUse;
  final VoidCallback onReset;
  final VoidCallback onVoid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FCFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EEF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 560;
              final ticketArtwork = _TicketArtworkCard(
                batch: batch,
                ticket: ticket,
                ticketNumber: ticketNumber,
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ticketArtwork,
                    const SizedBox(height: 12),
                    _TicketMetaBlock(
                      ticket: ticket,
                      onUse: onUse,
                      onReset: onReset,
                      onVoid: onVoid,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: ticketArtwork),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 3,
                    child: _TicketMetaBlock(
                      ticket: ticket,
                      onUse: onUse,
                      onReset: onReset,
                      onVoid: onVoid,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TicketArtworkCard extends StatelessWidget {
  const _TicketArtworkCard({
    required this.batch,
    required this.ticket,
    required this.ticketNumber,
  });

  final TicketBatchRecord batch;
  final TicketRecord ticket;
  final int ticketNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E7DCC), Color(0xFF49B2F0)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220066B6),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -14,
            right: 120,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'logo waterpark.png',
                          height: 38,
                          fit: BoxFit.contain,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            batch.type,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Puri Nirwana Waterpark Ticket',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ticket.code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _TicketArtworkMeta(
                          label: 'Batch',
                          value: batch.batchLabel,
                        ),
                        _TicketArtworkMeta(
                          label: 'Ticket No.',
                          value: '#${ticketNumber.toString().padLeft(3, '0')}',
                        ),
                        _TicketArtworkMeta(
                          label: 'Visit Date',
                          value: _formatDate(batch.visitDate),
                        ),
                        _TicketArtworkMeta(
                          label: 'Price',
                          value: _formatRupiah(batch.price),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                        ),
                      ),
                      child: const Text(
                        'Ticket artwork placeholder. Replace this visual with the real ticket design image later if needed.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 116,
                      height: 116,
                      child: QrImageView(
                        data: ticket.code,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'QR Placeholder',
                      style: TextStyle(
                        color: WaterparkBrand.gray,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TicketArtworkMeta extends StatelessWidget {
  const _TicketArtworkMeta({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TicketMetaBlock extends StatelessWidget {
  const _TicketMetaBlock({
    required this.ticket,
    required this.onUse,
    required this.onReset,
    required this.onVoid,
  });

  final TicketRecord ticket;
  final VoidCallback onUse;
  final VoidCallback onReset;
  final VoidCallback onVoid;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                ticket.code,
                style: const TextStyle(
                  color: WaterparkBrand.deepBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TicketStatusPill(
              label: ticket.status.label,
              color: ticket.status.color,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          ticket.scannedAt == null
              ? 'Not scanned yet'
              : 'Scanned ${_formatDateTime(ticket.scannedAt!)}',
          style: const TextStyle(
            color: WaterparkBrand.gray,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Ticket Actions',
          style: TextStyle(
            color: WaterparkBrand.deepBlue,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _TicketActionButton(
              icon: Icons.verified_rounded,
              tooltip: 'Mark Used',
              color: WaterparkBrand.success,
              onPressed: ticket.status == TicketStatus.used ? null : onUse,
            ),
            _TicketActionButton(
              icon: Icons.restart_alt_rounded,
              tooltip: 'Reset To Ready',
              color: WaterparkBrand.primaryBlue,
              onPressed: ticket.status == TicketStatus.ready ? null : onReset,
            ),
            _TicketActionButton(
              icon: Icons.block_rounded,
              tooltip: 'Void Ticket',
              color: WaterparkBrand.warning,
              onPressed: ticket.status == TicketStatus.voided ? null : onVoid,
            ),
          ],
        ),
      ],
    );
  }
}

class _TicketActionButton extends StatelessWidget {
  const _TicketActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: onPressed == null
                ? const Color(0xFFF3F5F8)
                : color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: onPressed == null
                  ? const Color(0xFFE3EAF1)
                  : color.withValues(alpha: 0.16),
            ),
          ),
          child: Icon(
            icon,
            color: onPressed == null ? WaterparkBrand.gray : color,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _TypePicker extends StatelessWidget {
  const _TypePicker({
    required this.selectedType,
    required this.onChanged,
    this.required = false,
  });

  final String selectedType;
  final ValueChanged<String> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) {
    const types = ['Weekday', 'Weekend', 'Group', 'Promo'];

    return DropdownButtonFormField<String>(
      initialValue: selectedType,
      decoration: _ticketInputDecoration('Ticket Type', required: required),
      items: [
        for (final type in types)
          DropdownMenuItem<String>(
            value: type,
            child: Text(type),
          ),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.selectedDate,
    required this.onTap,
    this.required = false,
  });

  final DateTime selectedDate;
  final VoidCallback onTap;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: _ticketInputDecoration('Visit Date', required: required),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatDate(selectedDate),
                style: const TextStyle(
                  color: WaterparkBrand.deepBlue,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.calendar_month_rounded),
          ],
        ),
      ),
    );
  }
}

class TicketingTextField extends StatelessWidget {
  const TicketingTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.required = false,
    this.isCurrency = false,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final bool required;
  final bool isCurrency;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _ticketInputDecoration(label, required: required).copyWith(
        hintText: hint,
        prefixText: isCurrency ? 'Rp ' : null,
        hintStyle: const TextStyle(
          color: Color(0xFF9FB2C5),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixStyle: const TextStyle(
          color: Color(0xFF9FB2C5),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputFormatters: [
        if (keyboardType == TextInputType.number && !isCurrency)
          FilteringTextInputFormatter.digitsOnly,
        if (isCurrency) _RupiahTextInputFormatter(),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Required';
        }
        if (keyboardType == TextInputType.number) {
          final parsedValue = isCurrency
              ? _parseCurrency(value)
              : int.tryParse(value.trim());
          if (parsedValue == null) {
            return 'Number only';
          }
          if (parsedValue <= 0) {
            return 'Must be more than 0';
          }
        }
        return null;
      },
    );
  }
}

class TicketStatusPill extends StatelessWidget {
  const TicketStatusPill({
    required this.label,
    required this.color,
    super.key,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
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

InputDecoration _ticketInputDecoration(String label, {bool required = false}) {
  return InputDecoration(
    label: RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: WaterparkBrand.gray,
          fontSize: 14,
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Color(0xFFE04F5F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]
            : const [],
      ),
    ),
    floatingLabelBehavior: FloatingLabelBehavior.always,
    filled: true,
    fillColor: const Color(0xFFF8FBFF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFDCEAF7)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFDCEAF7)),
    ),
  );
}

int? _parseCurrency(String value) {
  final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitsOnly.isEmpty) {
    return null;
  }
  return int.tryParse(digitsOnly);
}

String _formatRupiahDigits(String digits) {
  if (digits.isEmpty) {
    return '';
  }

  final reversed = digits.split('').reversed.toList();
  final buffer = StringBuffer();
  for (var index = 0; index < reversed.length; index++) {
    if (index > 0 && index % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(reversed[index]);
  }

  return buffer.toString().split('').reversed.join();
}

String _formatRupiah(int amount) {
  return 'Rp ${_formatRupiahDigits(amount.toString())}';
}

class _RupiahTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final formatted = _formatRupiahDigits(digitsOnly);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatDateTime(DateTime date) {
  return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

enum TicketStatus { ready, used, voided }

extension TicketStatusX on TicketStatus {
  String get label {
    return switch (this) {
      TicketStatus.ready => 'Ready',
      TicketStatus.used => 'Used',
      TicketStatus.voided => 'Void',
    };
  }

  Color get color {
    return switch (this) {
      TicketStatus.ready => WaterparkBrand.aqua,
      TicketStatus.used => WaterparkBrand.success,
      TicketStatus.voided => WaterparkBrand.warning,
    };
  }
}

class TicketRecord {
  const TicketRecord({
    required this.code,
    required this.status,
    this.scannedAt,
  });

  final String code;
  final TicketStatus status;
  final DateTime? scannedAt;

  TicketRecord copyWith({
    TicketStatus? status,
    DateTime? scannedAt,
  }) {
    final nextStatus = status ?? this.status;
    return TicketRecord(
      code: code,
      status: nextStatus,
      scannedAt: nextStatus == TicketStatus.ready
          ? null
          : scannedAt ?? this.scannedAt,
    );
  }
}

class TicketBatchRecord {
  TicketBatchRecord({
    required this.batchLabel,
    required this.type,
    required this.quantity,
    required this.price,
    required this.visitDate,
    required this.operator,
    required this.tickets,
  });

  factory TicketBatchRecord.create({
    required String batchLabel,
    required String type,
    required int quantity,
    required int price,
    required DateTime visitDate,
    required String operator,
  }) {
    final prefix = switch (type) {
      'Weekday' => 'WKD',
      'Weekend' => 'WND',
      'Group' => 'GRP',
      'Promo' => 'PRM',
      _ => 'TKT',
    };
    final datePart =
        '${visitDate.year}${visitDate.month.toString().padLeft(2, '0')}${visitDate.day.toString().padLeft(2, '0')}';

    return TicketBatchRecord(
      batchLabel: batchLabel,
      type: type,
      quantity: quantity,
      price: price,
      visitDate: visitDate,
      operator: operator,
      tickets: List.generate(
        quantity,
        (index) => TicketRecord(
          code: '$prefix-$datePart-${(index + 1).toString().padLeft(4, '0')}',
          status: TicketStatus.ready,
        ),
      ),
    );
  }

  final String batchLabel;
  final String type;
  final int quantity;
  final int price;
  final DateTime visitDate;
  final String operator;
  final List<TicketRecord> tickets;

  String get firstCode => tickets.first.code;
  int get ready => tickets.where((ticket) => ticket.status == TicketStatus.ready).length;
  int get used => tickets.where((ticket) => ticket.status == TicketStatus.used).length;
  int get voided => tickets.where((ticket) => ticket.status == TicketStatus.voided).length;

  String get batchStatusLabel {
    if (used == quantity) {
      return 'Finished';
    }
    if (used > 0 || voided > 0) {
      return 'Active';
    }
    return 'Ready';
  }

  Color get batchStatusColor {
    if (used == quantity) {
      return WaterparkBrand.success;
    }
    if (used > 0 || voided > 0) {
      return WaterparkBrand.primaryBlue;
    }
    return WaterparkBrand.aqua;
  }
}
