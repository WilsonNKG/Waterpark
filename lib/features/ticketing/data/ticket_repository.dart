import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waterpark/features/ticketing/domain/ticket_inventory.dart';

class SupabaseTicketRepository implements TicketRepository {
  SupabaseTicketRepository(this._client) {
    _inventoryChannel = _client
        .channel('public:ticket_inventory')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _batchesTable,
          callback: (_) => _inventoryChangesController.add(null),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _ticketsTable,
          callback: (_) => _inventoryChangesController.add(null),
        )
        .subscribe();
  }

  final SupabaseClient _client;
  static const _batchesTable = 'ticket_batches';
  static const _ticketsTable = 'tickets';
  final StreamController<void> _inventoryChangesController =
      StreamController<void>.broadcast();
  late final RealtimeChannel _inventoryChannel;

  @override
  Future<void> createBatch(TicketBatchRecord batch) async {
    await _saveBatchWithTickets(batch, allowExistingBatch: false);
  }

  @override
  Future<void> registerExistingTickets(TicketBatchRecord batch) async {
    await _saveBatchWithTickets(batch, allowExistingBatch: true);
  }

  @override
  Future<List<TicketBatchRecord>> fetchBatches() async {
    final batchRows = await _client
        .from(_batchesTable)
        .select()
        .order('created_at', ascending: false);

    final ticketRows = await _client
        .from(_ticketsTable)
        .select()
        .order('ticket_number', ascending: true);

    final ticketsByBatchId = <String, List<Map<String, dynamic>>>{};
    for (final row in ticketRows) {
      final typedRow = Map<String, dynamic>.from(row);
      final batchId = typedRow['batch_id'] as String;
      ticketsByBatchId.putIfAbsent(batchId, () => []).add(typedRow);
    }

    return batchRows.map((row) {
      final typedRow = Map<String, dynamic>.from(row);
      final batchId = typedRow['id'] as String;
      final batchTickets = ticketsByBatchId[batchId] ?? const [];
      return TicketBatchRecord(
        batchLabel: typedRow['batch_label'] as String,
        type: typedRow['ticket_type'] as String,
        quantity: batchTickets.length,
        price: typedRow['price'] as int,
        visitDate: DateTime.parse(typedRow['visit_date'] as String),
        operator: typedRow['operator'] as String,
        tickets: batchTickets
            .map(
              (ticketRow) => TicketRecord(
                ticketNumber: ticketRow['ticket_number'] as int,
                code: ticketRow['ticket_code'] as String,
                status: _statusFromDb(ticketRow['status'] as String),
                scannedAt: ticketRow['scanned_at'] == null
                    ? null
                    : DateTime.parse(
                        ticketRow['scanned_at'] as String,
                      ).toLocal(),
              ),
            )
            .toList(),
      );
    }).toList();
  }

  @override
  Future<TicketRedeemResult> redeemTicket(String ticketCode) async {
    final result = await _client.rpc(
      'redeem_ticket',
      params: {'p_scanned_code': ticketCode},
    );

    final rows = (result as List).cast<Map<String, dynamic>>();
    if (rows.isEmpty) {
      return const TicketRedeemResult(status: TicketRedeemStatus.unknown);
    }

    final row = rows.first;
    return switch (row['scan_result'] as String) {
      'accepted' => TicketRedeemResult(
        status: TicketRedeemStatus.redeemed,
        ticketCode: row['ticket_code'] as String?,
        ticketStatus: _statusFromDb(row['status'] as String? ?? 'used'),
        scannedAt: row['scanned_at'] == null
            ? null
            : DateTime.parse(row['scanned_at'] as String).toLocal(),
        batchLabel: row['batch_label'] as String?,
        ticketType: row['ticket_type'] as String?,
      ),
      'already_used' => TicketRedeemResult(
        status: TicketRedeemStatus.alreadyUsed,
        ticketCode: row['ticket_code'] as String?,
        ticketStatus: _statusFromDb(row['status'] as String? ?? 'used'),
        scannedAt: row['scanned_at'] == null
            ? null
            : DateTime.parse(row['scanned_at'] as String).toLocal(),
        batchLabel: row['batch_label'] as String?,
        ticketType: row['ticket_type'] as String?,
      ),
      'void' => TicketRedeemResult(
        status: TicketRedeemStatus.voided,
        ticketCode: row['ticket_code'] as String?,
        ticketStatus: _statusFromDb(row['status'] as String? ?? 'void'),
        scannedAt: row['scanned_at'] == null
            ? null
            : DateTime.parse(row['scanned_at'] as String).toLocal(),
        batchLabel: row['batch_label'] as String?,
        ticketType: row['ticket_type'] as String?,
      ),
      _ => const TicketRedeemResult(status: TicketRedeemStatus.unknown),
    };
  }

  @override
  Future<bool> updateTicketStatus(
    String ticketCode,
    TicketStatus status, {
    DateTime? scannedAt,
  }) async {
    final updatedRows = await _client
        .from(_ticketsTable)
        .update({
          'status': _statusToDb(status),
          'scanned_at': status == TicketStatus.used
              ? (scannedAt ?? DateTime.now()).toUtc().toIso8601String()
              : null,
          'voided_at': status == TicketStatus.voided
              ? DateTime.now().toUtc().toIso8601String()
              : null,
        })
        .eq('ticket_code', ticketCode)
        .select('ticket_code');

    return updatedRows.isNotEmpty;
  }

  @override
  Stream<void> watchInventoryChanges() => _inventoryChangesController.stream;

  @override
  void dispose() {
    _inventoryChangesController.close();
    _client.removeChannel(_inventoryChannel);
  }
}

extension on SupabaseTicketRepository {
  Future<void> _saveBatchWithTickets(
    TicketBatchRecord batch, {
    required bool allowExistingBatch,
  }) async {
    final existingBatchRows = await _client
        .from(SupabaseTicketRepository._batchesTable)
        .select('id, quantity')
        .eq('batch_label', batch.batchLabel)
        .limit(1);

    String batchId;
    var createdNewBatch = false;
    final hasExistingBatch = existingBatchRows.isNotEmpty;

    if (hasExistingBatch) {
      final existingBatch = Map<String, dynamic>.from(existingBatchRows.first);
      batchId = existingBatch['id'] as String;

      if (!allowExistingBatch) {
        throw StateError(
          'Batch ${batch.batchLabel} already exists. Use the legacy ticket registration flow for old paper tickets.',
        );
      }

      final currentQuantity = existingBatch['quantity'] as int;
      await _client
          .from(SupabaseTicketRepository._batchesTable)
          .update({
            'ticket_type': batch.type,
            'visit_date': batch.visitDate.toIso8601String().split('T').first,
            'quantity': currentQuantity + batch.quantity,
            'price': batch.price,
            'operator': batch.operator,
          })
          .eq('id', batchId);
    } else {
      final batchRow = await _client
          .from(SupabaseTicketRepository._batchesTable)
          .insert({
            'batch_label': batch.batchLabel,
            'ticket_type': batch.type,
            'visit_date': batch.visitDate.toIso8601String().split('T').first,
            'quantity': batch.quantity,
            'price': batch.price,
            'operator': batch.operator,
          })
          .select('id')
          .single();
      batchId = batchRow['id'] as String;
      createdNewBatch = true;
    }

    final ticketRows = [
      for (final ticket in batch.tickets)
        {
          'batch_id': batchId,
          'ticket_number': ticket.ticketNumber,
          'ticket_code': ticket.code,
          'qr_payload': ticket.code,
          'status': _statusToDb(ticket.status),
          'scanned_at': ticket.scannedAt?.toUtc().toIso8601String(),
        },
    ];

    try {
      await _client
          .from(SupabaseTicketRepository._ticketsTable)
          .insert(ticketRows);
    } on PostgrestException catch (error) {
      if (createdNewBatch) {
        await _client
            .from(SupabaseTicketRepository._batchesTable)
            .delete()
            .eq('id', batchId);
      }

      if (error.code == '23505') {
        throw StateError(
          'Generated ticket codes already exist. Please use a different batch label, or refresh the page if this batch was already partially created.',
        );
      }

      rethrow;
    } catch (_) {
      if (createdNewBatch) {
        await _client
            .from(SupabaseTicketRepository._batchesTable)
            .delete()
            .eq('id', batchId);
      }
      rethrow;
    }
  }
}

TicketRepository createTicketRepository() {
  try {
    return SupabaseTicketRepository(Supabase.instance.client);
  } catch (_) {
    throw StateError(
      'Supabase is not initialized. Start the app with your Supabase configuration.',
    );
  }
}

String _statusToDb(TicketStatus status) {
  return switch (status) {
    TicketStatus.ready => 'ready',
    TicketStatus.used => 'used',
    TicketStatus.voided => 'void',
  };
}

TicketStatus _statusFromDb(String value) {
  return switch (value) {
    'ready' => TicketStatus.ready,
    'used' => TicketStatus.used,
    'void' => TicketStatus.voided,
    _ => TicketStatus.ready,
  };
}
