import 'dart:collection';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:waterpark/core/theme/waterpark_brand.dart';

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
    required this.ticketNumber,
    required this.code,
    required this.status,
    this.scannedAt,
  });

  final int ticketNumber;
  final String code;
  final TicketStatus status;
  final DateTime? scannedAt;

  TicketRecord copyWith({
    TicketStatus? status,
    DateTime? scannedAt,
  }) {
    final nextStatus = status ?? this.status;
    return TicketRecord(
      ticketNumber: ticketNumber,
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
    int startingTicketNumber = 1,
  }) {
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
          ticketNumber: startingTicketNumber + index,
          code: _buildTicketCode(
            type: type,
            visitDate: visitDate,
            ticketNumber: startingTicketNumber + index,
          ),
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
  int get ready =>
      tickets.where((ticket) => ticket.status == TicketStatus.ready).length;
  int get used =>
      tickets.where((ticket) => ticket.status == TicketStatus.used).length;
  int get voided =>
      tickets.where((ticket) => ticket.status == TicketStatus.voided).length;

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

String _buildTicketCode({
  required String type,
  required DateTime visitDate,
  required int ticketNumber,
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
  return '$prefix-$datePart-${ticketNumber.toString().padLeft(4, '0')}';
}

class TicketLookup {
  const TicketLookup({
    required this.batch,
    required this.ticket,
    required this.batchIndex,
    required this.ticketIndex,
  });

  final TicketBatchRecord batch;
  final TicketRecord ticket;
  final int batchIndex;
  final int ticketIndex;
}

enum TicketRedeemStatus { redeemed, alreadyUsed, voided, unknown }

class TicketRedeemResult {
  const TicketRedeemResult({
    required this.status,
    this.lookup,
    this.ticketCode,
    this.ticketStatus,
    this.scannedAt,
    this.batchLabel,
    this.ticketType,
  });

  final TicketRedeemStatus status;
  final TicketLookup? lookup;
  final String? ticketCode;
  final TicketStatus? ticketStatus;
  final DateTime? scannedAt;
  final String? batchLabel;
  final String? ticketType;
}

abstract class TicketRepository {
  Future<List<TicketBatchRecord>> fetchBatches();
  Future<void> createBatch(TicketBatchRecord batch);
  Future<void> registerExistingTickets(TicketBatchRecord batch);
  Future<bool> updateTicketStatus(
    String ticketCode,
    TicketStatus status, {
    DateTime? scannedAt,
  });
  Future<TicketRedeemResult> redeemTicket(String ticketCode);
  Stream<void> watchInventoryChanges();
  void dispose();
}

class TicketInventory extends ChangeNotifier {
  TicketInventory({TicketRepository? repository}) : _repository = repository {
    if (_repository != null) {
      _inventoryChangesSubscription = _repository.watchInventoryChanges().listen((
        _,
      ) {
        _scheduleBackgroundRefresh();
      });
    }
  }

  final TicketRepository? _repository;
  final List<TicketBatchRecord> _batches = [];
  StreamSubscription<void>? _inventoryChangesSubscription;
  Timer? _reloadDebounce;
  bool _isLoading = false;
  String? _errorMessage;

  UnmodifiableListView<TicketBatchRecord> get batches =>
      UnmodifiableListView(_batches);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadBatches() async {
    if (_repository == null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedBatches = await _repository.fetchBatches();
      _batches
        ..clear()
        ..addAll(fetchedBatches);
    } catch (error) {
      _errorMessage = 'Could not load ticket batches. $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _reloadBatchesSilently() async {
    if (_repository == null || _isLoading) {
      return;
    }

    try {
      final fetchedBatches = await _repository.fetchBatches();
      _batches
        ..clear()
        ..addAll(fetchedBatches);
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      // Keep the last known ticket data if a background refresh fails.
    }
  }

  void _scheduleBackgroundRefresh() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 350), () {
      _reloadBatchesSilently();
    });
  }

  Future<void> createBatch({
    required String batchLabel,
    required String type,
    required int quantity,
    required int price,
    required DateTime visitDate,
    required String operator,
  }) async {
    final batch = TicketBatchRecord.create(
      batchLabel: batchLabel,
      type: type,
      quantity: quantity,
      price: price,
      visitDate: visitDate,
      operator: operator,
    );

    if (_repository != null) {
      await _repository.createBatch(batch);
      await _reloadBatchesSilently();
      return;
    }

    _batches.insert(0, batch);
    notifyListeners();
  }

  Future<void> registerExistingTickets({
    required String batchLabel,
    required String type,
    required int price,
    required DateTime visitDate,
    required String operator,
    required int startingTicketNumber,
    required int endingTicketNumber,
  }) async {
    final quantity = (endingTicketNumber - startingTicketNumber) + 1;
    final batch = TicketBatchRecord.create(
      batchLabel: batchLabel,
      type: type,
      quantity: quantity,
      price: price,
      visitDate: visitDate,
      operator: operator,
      startingTicketNumber: startingTicketNumber,
    );

    if (_repository != null) {
      await _repository.registerExistingTickets(batch);
      await _reloadBatchesSilently();
      return;
    }

    final existingIndex = _batches.indexWhere(
      (existingBatch) => existingBatch.batchLabel == batch.batchLabel,
    );
    if (existingIndex == -1) {
      _batches.insert(0, batch);
    } else {
      final existingBatch = _batches[existingIndex];
      final mergedTickets = [...existingBatch.tickets, ...batch.tickets]
        ..sort((a, b) => a.ticketNumber.compareTo(b.ticketNumber));
      _batches[existingIndex] = TicketBatchRecord(
        batchLabel: existingBatch.batchLabel,
        type: batch.type,
        quantity: mergedTickets.length,
        price: batch.price,
        visitDate: batch.visitDate,
        operator: batch.operator,
        tickets: mergedTickets,
      );
    }
    notifyListeners();
  }

  TicketLookup? findTicket(String code) {
    for (var batchIndex = 0; batchIndex < _batches.length; batchIndex++) {
      final batch = _batches[batchIndex];
      for (var ticketIndex = 0; ticketIndex < batch.tickets.length; ticketIndex++) {
        final ticket = batch.tickets[ticketIndex];
        if (ticket.code == code) {
          return TicketLookup(
            batch: batch,
            ticket: ticket,
            batchIndex: batchIndex,
            ticketIndex: ticketIndex,
          );
        }
      }
    }
    return null;
  }

  Future<bool> updateTicketStatus(
    String ticketCode,
    TicketStatus status, {
    DateTime? scannedAt,
  }) async {
    final lookup = findTicket(ticketCode);
    if (_repository != null) {
      final updated = await _repository.updateTicketStatus(
        ticketCode,
        status,
        scannedAt: scannedAt,
      );
      if (!updated) {
        return false;
      }
      await _reloadBatchesSilently();
      return true;
    } else if (lookup == null) {
      return false;
    }

    lookup.batch.tickets[lookup.ticketIndex] = lookup.ticket.copyWith(
      status: status,
      scannedAt: status == TicketStatus.used ? (scannedAt ?? DateTime.now()) : null,
    );
    notifyListeners();
    return true;
  }

  Future<TicketRedeemResult> redeemTicket(String ticketCode) async {
    if (_repository != null) {
      final result = await _repository.redeemTicket(ticketCode);
      await _reloadBatchesSilently();
      final matchedCode = result.ticketCode ?? ticketCode;
      final lookup = findTicket(matchedCode);
      if (lookup != null && result.ticketStatus != null) {
        lookup.batch.tickets[lookup.ticketIndex] = lookup.ticket.copyWith(
          status: result.ticketStatus,
          scannedAt: result.scannedAt,
        );
        notifyListeners();
        return TicketRedeemResult(
          status: result.status,
          lookup: TicketLookup(
            batch: lookup.batch,
            ticket: lookup.batch.tickets[lookup.ticketIndex],
            batchIndex: lookup.batchIndex,
            ticketIndex: lookup.ticketIndex,
          ),
          ticketCode: matchedCode,
          ticketStatus: result.ticketStatus,
          scannedAt: result.scannedAt,
          batchLabel: result.batchLabel,
          ticketType: result.ticketType,
        );
      }

      return result;
    }

    final lookup = findTicket(ticketCode);
    if (lookup == null) {
      return const TicketRedeemResult(status: TicketRedeemStatus.unknown);
    }

    return switch (lookup.ticket.status) {
      TicketStatus.ready => () {
          final scannedAt = DateTime.now();
          lookup.batch.tickets[lookup.ticketIndex] = lookup.ticket.copyWith(
            status: TicketStatus.used,
            scannedAt: scannedAt,
          );
          notifyListeners();
          return TicketRedeemResult(
            status: TicketRedeemStatus.redeemed,
            lookup: TicketLookup(
              batch: lookup.batch,
              ticket: lookup.batch.tickets[lookup.ticketIndex],
              batchIndex: lookup.batchIndex,
              ticketIndex: lookup.ticketIndex,
            ),
            ticketCode: lookup.ticket.code,
            ticketStatus: TicketStatus.used,
            scannedAt: scannedAt,
            batchLabel: lookup.batch.batchLabel,
            ticketType: lookup.batch.type,
          );
        }(),
      TicketStatus.used => TicketRedeemResult(
          status: TicketRedeemStatus.alreadyUsed,
          lookup: lookup,
          ticketCode: lookup.ticket.code,
          ticketStatus: lookup.ticket.status,
          scannedAt: lookup.ticket.scannedAt,
          batchLabel: lookup.batch.batchLabel,
          ticketType: lookup.batch.type,
        ),
      TicketStatus.voided => TicketRedeemResult(
          status: TicketRedeemStatus.voided,
          lookup: lookup,
          ticketCode: lookup.ticket.code,
          ticketStatus: lookup.ticket.status,
          scannedAt: lookup.ticket.scannedAt,
          batchLabel: lookup.batch.batchLabel,
          ticketType: lookup.batch.type,
        ),
    };
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    _inventoryChangesSubscription?.cancel();
    _repository?.dispose();
    super.dispose();
  }
}

class TicketInventoryScope extends InheritedNotifier<TicketInventory> {
  const TicketInventoryScope({
    required TicketInventory inventory,
    required super.child,
    super.key,
  }) : super(notifier: inventory);

  static TicketInventory of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<TicketInventoryScope>();
    assert(scope != null, 'TicketInventoryScope not found in widget tree.');
    return scope!.notifier!;
  }
}
