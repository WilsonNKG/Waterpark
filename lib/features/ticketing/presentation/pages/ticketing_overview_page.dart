import 'package:flutter/material.dart';
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
  final _batchLabelController = TextEditingController(text: 'WKD-2906-A');
  final _priceController = TextEditingController(text: '75000');
  final _quantityController = TextEditingController(text: '120');
  final _operatorController = TextEditingController(text: 'Front Desk');

  final List<TicketBatchRecord> _batches = [
    TicketBatchRecord.create(
      batchLabel: 'WKD-2906-A',
      type: 'Weekday',
      quantity: 120,
      price: 75000,
      visitDate: DateTime(2026, 6, 29),
      operator: 'Front Desk',
    ),
    TicketBatchRecord.create(
      batchLabel: 'WND-2906-A',
      type: 'Weekend',
      quantity: 80,
      price: 95000,
      visitDate: DateTime(2026, 6, 30),
      operator: 'Counter 2',
    ),
  ];

  String _selectedType = 'Weekday';
  DateTime _selectedDate = DateTime(2026, 6, 29);
  int _selectedBatchIndex = 0;

  @override
  void initState() {
    super.initState();
    _batches[0].tickets[0] = _batches[0].tickets[0].copyWith(
      status: TicketStatus.used,
      scannedAt: DateTime(2026, 6, 29, 9, 12),
    );
    _batches[0].tickets[1] = _batches[0].tickets[1].copyWith(
      status: TicketStatus.used,
      scannedAt: DateTime(2026, 6, 29, 9, 14),
    );
    _batches[1].tickets[0] = _batches[1].tickets[0].copyWith(
      status: TicketStatus.voided,
    );
  }

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
    final selectedBatch = _batches[_selectedBatchIndex];

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
                      onSelectBatch: (index) {
                        setState(() {
                          _selectedBatchIndex = index;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TicketBatchDetailCard(
                      batch: selectedBatch,
                      onTicketStatusChanged: _updateTicketStatus,
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
                          onSelectBatch: (index) {
                            setState(() {
                              _selectedBatchIndex = index;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: TicketBatchDetailCard(
                      batch: selectedBatch,
                      onTicketStatusChanged: _updateTicketStatus,
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
    final price = int.parse(_priceController.text.trim());

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
      _batchLabelController.text =
          '${_prefixForType(_selectedType)}-${_selectedDate.day.toString().padLeft(2, '0')}${_selectedDate.month.toString().padLeft(2, '0')}-A';
      _quantityController.text = '100';
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

  String _prefixForType(String type) {
    return switch (type) {
      'Weekday' => 'WKD',
      'Weekend' => 'WND',
      'Group' => 'GRP',
      'Promo' => 'PRM',
      _ => 'TKT',
    };
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
                        hint: 'WKD-2906-A',
                      ),
                      const SizedBox(height: 12),
                      _TypePicker(
                        selectedType: selectedType,
                        onChanged: onTypeChanged,
                      ),
                      const SizedBox(height: 12),
                      _DateField(
                        selectedDate: selectedDate,
                        onTap: onDateTap,
                      ),
                      const SizedBox(height: 12),
                      TicketingTextField(
                        controller: quantityController,
                        label: 'Quantity',
                        hint: '100',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TicketingTextField(
                        controller: priceController,
                        label: 'Price',
                        hint: '75000',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TicketingTextField(
                        controller: operatorController,
                        label: 'Operator',
                        hint: 'Front Desk',
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
                            hint: 'WKD-2906-A',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TypePicker(
                            selectedType: selectedType,
                            onChanged: onTypeChanged,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            selectedDate: selectedDate,
                            onTap: onDateTap,
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
                            hint: '100',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TicketingTextField(
                            controller: priceController,
                            label: 'Price',
                            hint: '75000',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TicketingTextField(
                            controller: operatorController,
                            label: 'Operator',
                            hint: 'Front Desk',
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
            'Select a batch to review its generated ticket codes and live ticket status.',
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
    final previewTickets = batch.tickets.take(6).toList();

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
                label: 'Rp ${batch.price}',
                color: WaterparkBrand.primaryBlue,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Generated Ticket Preview',
            style: TextStyle(
              color: WaterparkBrand.deepBlue,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (final ticket in previewTickets) ...[
            TicketPreviewRow(
              ticket: ticket,
              onUse: () => onTicketStatusChanged(ticket.code, TicketStatus.used),
              onReset: () =>
                  onTicketStatusChanged(ticket.code, TicketStatus.ready),
              onVoid: () =>
                  onTicketStatusChanged(ticket.code, TicketStatus.voided),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class TicketPreviewRow extends StatelessWidget {
  const TicketPreviewRow({
    required this.ticket,
    required this.onUse,
    required this.onReset,
    required this.onVoid,
    super.key,
  });

  final TicketRecord ticket;
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TicketActionButton(
                icon: Icons.verified_rounded,
                tooltip: 'Mark Used',
                color: WaterparkBrand.success,
                onPressed:
                    ticket.status == TicketStatus.used ? null : onUse,
              ),
              _TicketActionButton(
                icon: Icons.restart_alt_rounded,
                tooltip: 'Reset To Ready',
                color: WaterparkBrand.primaryBlue,
                onPressed:
                    ticket.status == TicketStatus.ready ? null : onReset,
              ),
              _TicketActionButton(
                icon: Icons.block_rounded,
                tooltip: 'Void Ticket',
                color: WaterparkBrand.warning,
                onPressed:
                    ticket.status == TicketStatus.voided ? null : onVoid,
              ),
            ],
          ),
        ],
      ),
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
  });

  final String selectedType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const types = ['Weekday', 'Weekend', 'Group', 'Promo'];

    return DropdownButtonFormField<String>(
      value: selectedType,
      decoration: _ticketInputDecoration('Ticket Type'),
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
  });

  final DateTime selectedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: _ticketInputDecoration('Visit Date'),
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
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _ticketInputDecoration(label).copyWith(hintText: hint),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Required';
        }
        if (keyboardType == TextInputType.number) {
          final parsedValue = int.tryParse(value.trim());
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

InputDecoration _ticketInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
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
