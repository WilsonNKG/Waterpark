import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:waterpark/core/theme/waterpark_brand.dart';
import 'package:waterpark/features/ticketing/domain/ticket_inventory.dart';
import 'package:waterpark/shared/widgets/brand_surface.dart';

class TicketingOverviewPage extends StatefulWidget {
  const TicketingOverviewPage({super.key});

  @override
  State<TicketingOverviewPage> createState() => _TicketingOverviewPageState();
}

class _TicketingOverviewPageState extends State<TicketingOverviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _legacyFormKey = GlobalKey<FormState>();
  final _batchLabelController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _operatorController = TextEditingController();
  final _legacyBatchLabelController = TextEditingController();
  final _legacyPriceController = TextEditingController();
  final _legacyOperatorController = TextEditingController();
  final _startingTicketNumberController = TextEditingController();
  final _endingTicketNumberController = TextEditingController();

  String _selectedType = 'Weekday';
  DateTime _selectedDate = DateTime.now();
  String _legacySelectedType = 'Weekday';
  DateTime _legacySelectedDate = DateTime.now();
  int _selectedBatchIndex = 0;

  @override
  void dispose() {
    _batchLabelController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _operatorController.dispose();
    _legacyBatchLabelController.dispose();
    _legacyPriceController.dispose();
    _legacyOperatorController.dispose();
    _startingTicketNumberController.dispose();
    _endingTicketNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = TicketInventoryScope.of(context);

    return ListenableBuilder(
      listenable: inventory,
      builder: (context, _) {
        final batches = inventory.batches;
        final totalTickets = batches.fold<int>(
          0,
          (sum, batch) => sum + batch.quantity,
        );
        final usedTickets = batches.fold<int>(
          0,
          (sum, batch) => sum + batch.used,
        );
        final voidedTickets = batches.fold<int>(
          0,
          (sum, batch) => sum + batch.voided,
        );
        final readyTickets = batches.fold<int>(
          0,
          (sum, batch) => sum + batch.ready,
        );
        final safeSelectedIndex = batches.isEmpty
            ? 0
            : _selectedBatchIndex.clamp(0, batches.length - 1);
        final selectedBatch = batches.isEmpty
            ? null
            : batches[safeSelectedIndex];

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
                totalBatches: batches.length,
                activeBatch: selectedBatch,
              ),
              const SizedBox(height: 16),
              if (inventory.errorMessage != null) ...[
                _TicketingErrorBanner(message: inventory.errorMessage!),
                const SizedBox(height: 16),
              ],
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
                        LegacyTicketImportCard(
                          formKey: _legacyFormKey,
                          batchLabelController: _legacyBatchLabelController,
                          priceController: _legacyPriceController,
                          operatorController: _legacyOperatorController,
                          startingTicketNumberController:
                              _startingTicketNumberController,
                          endingTicketNumberController:
                              _endingTicketNumberController,
                          selectedType: _legacySelectedType,
                          selectedDate: _legacySelectedDate,
                          onTypeChanged: (value) {
                            setState(() {
                              _legacySelectedType = value;
                            });
                          },
                          onDateTap: _pickLegacyVisitDate,
                          onRegisterTickets: _registerExistingTickets,
                        ),
                        const SizedBox(height: 16),
                        TicketBatchTableCard(
                          batches: batches,
                          selectedBatchIndex: safeSelectedIndex,
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
                            LegacyTicketImportCard(
                              formKey: _legacyFormKey,
                              batchLabelController: _legacyBatchLabelController,
                              priceController: _legacyPriceController,
                              operatorController: _legacyOperatorController,
                              startingTicketNumberController:
                                  _startingTicketNumberController,
                              endingTicketNumberController:
                                  _endingTicketNumberController,
                              selectedType: _legacySelectedType,
                              selectedDate: _legacySelectedDate,
                              onTypeChanged: (value) {
                                setState(() {
                                  _legacySelectedType = value;
                                });
                              },
                              onDateTap: _pickLegacyVisitDate,
                              onRegisterTickets: _registerExistingTickets,
                            ),
                            const SizedBox(height: 16),
                            TicketBatchTableCard(
                              batches: batches,
                              selectedBatchIndex: safeSelectedIndex,
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
      },
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

  Future<void> _pickLegacyVisitDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _legacySelectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _legacySelectedDate = pickedDate;
    });
  }

  Future<void> _createBatch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final inventory = TicketInventoryScope.of(context);
    final batchLabel = _batchLabelController.text.trim().toUpperCase();
    final quantity = int.parse(_quantityController.text.trim());
    final price = _parseCurrency(_priceController.text)!;

    try {
      await inventory.createBatch(
        batchLabel: batchLabel,
        type: _selectedType,
        quantity: quantity,
        price: price,
        visitDate: _selectedDate,
        operator: _operatorController.text.trim(),
      );

      setState(() {
        _selectedBatchIndex = 0;
        _batchLabelController.clear();
        _priceController.clear();
        _quantityController.clear();
        _operatorController.clear();
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created $batchLabel with $quantity tickets.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not create batch. $error')));
    }
  }

  Future<void> _updateTicketStatus(
    String ticketCode,
    TicketStatus status,
  ) async {
    await TicketInventoryScope.of(
      context,
    ).updateTicketStatus(ticketCode, status);
  }

  Future<void> _registerExistingTickets() async {
    if (!_legacyFormKey.currentState!.validate()) {
      return;
    }

    final inventory = TicketInventoryScope.of(context);
    final batchLabel = _legacyBatchLabelController.text.trim().toUpperCase();
    final price = _parseCurrency(_legacyPriceController.text)!;
    final startingTicketNumber = int.parse(
      _startingTicketNumberController.text.trim(),
    );
    final endingTicketNumber = int.parse(
      _endingTicketNumberController.text.trim(),
    );

    if (endingTicketNumber < startingTicketNumber) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ending ticket number must be greater than or equal to the starting number.',
          ),
        ),
      );
      return;
    }

    try {
      await inventory.registerExistingTickets(
        batchLabel: batchLabel,
        type: _legacySelectedType,
        price: price,
        visitDate: _legacySelectedDate,
        operator: _legacyOperatorController.text.trim(),
        startingTicketNumber: startingTicketNumber,
        endingTicketNumber: endingTicketNumber,
      );

      setState(() {
        _selectedBatchIndex = 0;
        _legacyBatchLabelController.clear();
        _legacyPriceController.clear();
        _legacyOperatorController.clear();
        _startingTicketNumberController.clear();
        _endingTicketNumberController.clear();
      });

      if (!mounted) {
        return;
      }

      final registeredCount = (endingTicketNumber - startingTicketNumber) + 1;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Registered $registeredCount existing paper tickets for $batchLabel.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not register existing tickets. $error')),
      );
    }
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
          batch: TicketInventoryScope.of(context).batches[index],
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
      (
        'Tickets Generated',
        '$totalTickets',
        Icons.confirmation_num_outlined,
        WaterparkBrand.primaryBlue,
      ),
      (
        'Ready To Scan',
        '$readyTickets',
        Icons.qr_code_2_rounded,
        WaterparkBrand.aqua,
      ),
      (
        'Used Tickets',
        '$usedTickets',
        Icons.verified_outlined,
        WaterparkBrand.success,
      ),
      (
        'Voided Tickets',
        '$voidedTickets',
        Icons.block_rounded,
        WaterparkBrand.warning,
      ),
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

class _TicketingErrorBanner extends StatelessWidget {
  const _TicketingErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return BrandSurface(
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: WaterparkBrand.accentRed,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: WaterparkBrand.deepBlue,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
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
            subtitle: totalBatches == 1
                ? '1 batch created'
                : '$totalBatches batches created',
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
              children: [totalCard, const SizedBox(height: 12), activeCard],
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
  final Future<void> Function() onCreateBatch;

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
                  onPressed: () {
                    onCreateBatch();
                  },
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

class LegacyTicketImportCard extends StatelessWidget {
  const LegacyTicketImportCard({
    required this.formKey,
    required this.batchLabelController,
    required this.priceController,
    required this.operatorController,
    required this.startingTicketNumberController,
    required this.endingTicketNumberController,
    required this.selectedType,
    required this.selectedDate,
    required this.onTypeChanged,
    required this.onDateTap,
    required this.onRegisterTickets,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController batchLabelController;
  final TextEditingController priceController;
  final TextEditingController operatorController;
  final TextEditingController startingTicketNumberController;
  final TextEditingController endingTicketNumberController;
  final String selectedType;
  final DateTime selectedDate;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onDateTap;
  final Future<void> Function() onRegisterTickets;

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
                        'Register Existing Paper Tickets',
                        style: TextStyle(
                          color: WaterparkBrand.deepBlue,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Use this for old printed tickets you still want to accept. The app will store the exact ticket numbers and generate matching QR identities for scanning.',
                        style: TextStyle(
                          color: WaterparkBrand.gray,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed: () {
                    onRegisterTickets();
                  },
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: const Text('Register Tickets'),
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
                        hint: 'Ex: WKD-20260701',
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
                      const SizedBox(height: 12),
                      TicketingTextField(
                        controller: startingTicketNumberController,
                        label: 'Starting Ticket No.',
                        hint: 'Ex: 1',
                        keyboardType: TextInputType.number,
                        required: true,
                      ),
                      const SizedBox(height: 12),
                      TicketingTextField(
                        controller: endingTicketNumberController,
                        label: 'Ending Ticket No.',
                        hint: 'Ex: 50',
                        keyboardType: TextInputType.number,
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
                            hint: 'Ex: WKD-20260701',
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: TicketingTextField(
                            controller: startingTicketNumberController,
                            label: 'Starting Ticket No.',
                            hint: 'Ex: 1',
                            keyboardType: TextInputType.number,
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TicketingTextField(
                            controller: endingTicketNumberController,
                            label: 'Ending Ticket No.',
                            hint: 'Ex: 50',
                            keyboardType: TextInputType.number,
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
                        Expanded(
                          flex: 2,
                          child: TicketHeaderCell('First Code'),
                        ),
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
                              child: TicketBodyCell(
                                '${batches[index].quantity}',
                              ),
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
  final Future<void> Function(String ticketCode, TicketStatus status)
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
            onTicketStatusChanged: (ticketCode, status) async {
              await widget.onTicketStatusChanged(ticketCode, status);
              if (mounted) {
                setState(() {});
              }
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
  final Future<void> Function(String ticketCode, TicketStatus status)
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
                      '${batch.batchLabel} • ${batch.tickets.length} Tickets',
                      style: const TextStyle(
                        color: WaterparkBrand.deepBlue,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${batch.type} • ${_formatDate(batch.visitDate)} • ${batch.operator}',
                      style: const TextStyle(
                        color: WaterparkBrand.gray,
                        fontSize: 12,
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
          const SizedBox(height: 14),
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
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columnCount = constraints.maxWidth >= 1100 ? 3 : 2;
              final compactLayout = true;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnCount,
                  crossAxisSpacing: constraints.maxWidth < 680 ? 10 : 14,
                  mainAxisSpacing: constraints.maxWidth < 680 ? 10 : 14,
                  childAspectRatio: switch (columnCount) {
                    3 => 0.86,
                    _ => constraints.maxWidth < 680 ? 0.72 : 0.90,
                  },
                ),
                itemCount: batch.tickets.length,
                itemBuilder: (context, index) {
                  final ticket = batch.tickets[index];
                  return TicketVisualCard(
                    batch: batch,
                    ticket: ticket,
                    ticketNumber: ticket.ticketNumber,
                    compactLayout: compactLayout,
                    onUse: () =>
                        onTicketStatusChanged(ticket.code, TicketStatus.used),
                    onReset: () =>
                        onTicketStatusChanged(ticket.code, TicketStatus.ready),
                    onVoid: () =>
                        onTicketStatusChanged(ticket.code, TicketStatus.voided),
                  );
                },
              );
            },
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
    required this.compactLayout,
    required this.onUse,
    required this.onReset,
    required this.onVoid,
    super.key,
  });

  final TicketBatchRecord batch;
  final TicketRecord ticket;
  final int ticketNumber;
  final bool compactLayout;
  final VoidCallback onUse;
  final VoidCallback onReset;
  final VoidCallback onVoid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compactLayout ? 12 : 14),
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
              final stacked = compactLayout || constraints.maxWidth < 560;
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
                      ticketNumber: ticketNumber,
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
                      ticketNumber: ticketNumber,
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
    final theme = _TicketVisualTheme.resolve(batch.type);

    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.baseColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor,
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: theme.backgroundAssetPath == null
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: theme.backgroundGradient!,
                          ),
                        )
                      : Image.asset(
                          theme.backgroundAssetPath!,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: theme.squareOverlayGradient,
                    ),
                  ),
                ),
                Positioned(
                  top: -18,
                  right: -18,
                  child: Container(
                    width: 118,
                    height: 118,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18001933),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF5FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Image.asset(
                                'assets/logo/logo waterpark.png',
                                height: 16,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.accentColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                batch.type.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          theme.headline,
                          style: const TextStyle(
                            color: WaterparkBrand.deepBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          theme.subline,
                          style: const TextStyle(
                            color: Color(0xFF426988),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F8FD),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      ticket.code,
                                      style: TextStyle(
                                        color: theme.textColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      _TicketArtworkMeta(
                                        label: 'Batch',
                                        value: batch.batchLabel,
                                      ),
                                      _TicketArtworkMeta(
                                        label: 'No.',
                                        value:
                                            '#${ticketNumber.toString().padLeft(3, '0')}',
                                      ),
                                      _TicketArtworkMeta(
                                        label: 'Date',
                                        value: _formatDate(batch.visitDate),
                                      ),
                                      _TicketArtworkMeta(
                                        label: 'Price',
                                        value: _formatRupiah(batch.price),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 90,
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE6EEF5),
                                ),
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 66,
                                    height: 66,
                                    child: QrImageView(
                                      data: ticket.code,
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    theme.qrLabel,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: WaterparkBrand.deepBlue,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.accentColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            theme.footerNote,
                            style: const TextStyle(
                              color: WaterparkBrand.deepBlue,
                              fontSize: 9,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }
}

class _TicketArtworkMeta extends StatelessWidget {
  const _TicketArtworkMeta({required this.label, required this.value});

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
          style: TextStyle(
            color: const Color(0xFF66839D),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: WaterparkBrand.deepBlue,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TicketVisualTheme {
  const _TicketVisualTheme({
    required this.headline,
    required this.subline,
    required this.footerNote,
    required this.qrLabel,
    required this.textColor,
    required this.baseColor,
    required this.accentColor,
    required this.shadowColor,
    required this.overlayGradient,
    required this.squareOverlayGradient,
    this.backgroundAssetPath,
    this.backgroundGradient,
  });

  final String headline;
  final String subline;
  final String footerNote;
  final String qrLabel;
  final String? backgroundAssetPath;
  final Gradient? backgroundGradient;
  final Color textColor;
  final Color baseColor;
  final Color accentColor;
  final Color shadowColor;
  final Gradient overlayGradient;
  final Gradient squareOverlayGradient;

  static _TicketVisualTheme resolve(String type) {
    final normalizedType = type.trim().toLowerCase();

    return switch (normalizedType) {
      'weekday' => const _TicketVisualTheme(
        headline: 'Weekday Splash Pass',
        subline: 'Smooth weekday entry with the classic family ticket artwork.',
        footerNote:
            'Valid for one visit on Monday to Saturday. Please scan this QR at the gate.',
        qrLabel: 'Scan For Entry',
        backgroundAssetPath: 'assets/tickets/Weekday.png',
        textColor: WaterparkBrand.deepBlue,
        baseColor: Color(0xFF1071BA),
        accentColor: WaterparkBrand.primaryBlue,
        shadowColor: Color(0x22006AB0),
        overlayGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xD9076EB4), Color(0xA63CB9F2), Color(0xC90A2440)],
        ),
        squareOverlayGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x1AFFFFFF), Color(0x66005E9C), Color(0xCC06233E)],
          stops: [0, 0.42, 1],
        ),
      ),
      'weekend' => const _TicketVisualTheme(
        headline: 'Weekend Wave Pass',
        subline:
            'Bright weekend artwork for Sunday, long weekend, and holiday traffic.',
        footerNote:
            'Use this design for high-season entry. Counter confirmation stays required.',
        qrLabel: 'Weekend Gate QR',
        backgroundAssetPath: 'assets/tickets/Weekend.png',
        textColor: WaterparkBrand.deepBlue,
        baseColor: Color(0xFF207AC9),
        accentColor: Color(0xFFE34B5B),
        shadowColor: Color(0x22335E96),
        overlayGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xE6F9FBFF), Color(0xB30D83D5), Color(0xD912355A)],
        ),
        squareOverlayGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x14FFFFFF), Color(0x4D2F84C8), Color(0xD919314D)],
          stops: [0, 0.45, 1],
        ),
      ),
      'group' || 'rombongan' => const _TicketVisualTheme(
        headline: 'Rombongan Adventure Pass',
        subline:
            'Ticket rombongan with artwork matched to the family group design.',
        footerNote:
            'Ideal for rombongan sales and team visits. Present the matching batch at check-in.',
        qrLabel: 'Group Check-In QR',
        backgroundAssetPath: 'assets/tickets/Rombongan.png',
        textColor: WaterparkBrand.deepBlue,
        baseColor: Color(0xFF5D9FD4),
        accentColor: Color(0xFFEF7A97),
        shadowColor: Color(0x22335E96),
        overlayGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xCCEFF8FF), Color(0xAF80D4FF), Color(0xD1284470)],
        ),
        squareOverlayGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x10FFFFFF), Color(0x4D73B8E2), Color(0xD82F4565)],
          stops: [0, 0.42, 1],
        ),
      ),
      'promo' => const _TicketVisualTheme(
        headline: 'Promo Flash Pass',
        subline:
            'A digital-only promo layout with stronger contrast for campaigns and special offers.',
        footerNote:
            'Promo tickets can use a separate campaign rule set while keeping the same scan flow.',
        qrLabel: 'Promo Redeem QR',
        backgroundGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF052847), Color(0xFF0D5DA8), Color(0xFF1CD2C8)],
        ),
        textColor: WaterparkBrand.deepBlue,
        baseColor: Color(0xFF0A4D80),
        accentColor: Color(0xFFFF7A00),
        shadowColor: Color(0x22084478),
        overlayGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xA61E2D4B), Color(0x6650E3C2), Color(0xCC021527)],
        ),
        squareOverlayGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x0DFFFFFF), Color(0x4D0C5B8E), Color(0xD9051930)],
          stops: [0, 0.42, 1],
        ),
      ),
      _ => const _TicketVisualTheme(
        headline: 'Waterpark Entry Pass',
        subline: 'Standard digital ticket artwork for general admission.',
        footerNote: 'Show this ticket to the operator and scan the QR code.',
        qrLabel: 'Entry QR',
        backgroundGradient: WaterparkBrand.oceanGradient,
        textColor: WaterparkBrand.deepBlue,
        baseColor: WaterparkBrand.primaryBlue,
        accentColor: WaterparkBrand.aqua,
        shadowColor: Color(0x220066B6),
        overlayGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x8A0C70BE), Color(0x8032B8F5), Color(0xAD05263E)],
        ),
        squareOverlayGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x14FFFFFF), Color(0x4D1677B1), Color(0xD906243E)],
          stops: [0, 0.42, 1],
        ),
      ),
    };
  }
}

class _TicketMetaBlock extends StatelessWidget {
  const _TicketMetaBlock({
    required this.ticket,
    required this.ticketNumber,
    required this.onUse,
    required this.onReset,
    required this.onVoid,
  });

  final TicketRecord ticket;
  final int ticketNumber;
  final VoidCallback onUse;
  final VoidCallback onReset;
  final VoidCallback onVoid;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Ticket #${ticketNumber.toString().padLeft(3, '0')}',
            style: const TextStyle(
              color: WaterparkBrand.primaryBlue,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                ticket.code,
                style: const TextStyle(
                  color: WaterparkBrand.deepBlue,
                  fontSize: 16,
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
        const Text(
          'Ticket Actions',
          style: TextStyle(
            color: WaterparkBrand.deepBlue,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
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
          DropdownMenuItem<String>(value: type, child: Text(type)),
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
  const TicketStatusPill({required this.label, required this.color, super.key});

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
        style: const TextStyle(color: WaterparkBrand.gray, fontSize: 14),
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
