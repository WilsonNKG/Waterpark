import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waterpark/features/ticketing/domain/ticket_inventory.dart';

class SupabaseTicketRepository implements TicketRepository {
  SupabaseTicketRepository(this._client);

  final SupabaseClient _client;
  static const _batchesTable = 'ticket_batches';
  static const _ticketsTable = 'tickets';

  @override
  Future<void> createBatch(TicketBatchRecord batch) async {
    final batchRow = await _client
        .from(_batchesTable)
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

    final batchId = batchRow['id'] as String;
    final ticketRows = [
      for (var index = 0; index < batch.tickets.length; index++)
        {
          'batch_id': batchId,
          'ticket_number': index + 1,
          'ticket_code': batch.tickets[index].code,
          'qr_payload': batch.tickets[index].code,
          'status': _statusToDb(batch.tickets[index].status),
          'scanned_at': batch.tickets[index].scannedAt?.toIso8601String(),
        },
    ];

    await _client.from(_ticketsTable).insert(ticketRows);
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
        quantity: typedRow['quantity'] as int,
        price: typedRow['price'] as int,
        visitDate: DateTime.parse(typedRow['visit_date'] as String),
        operator: typedRow['operator'] as String,
        tickets: batchTickets
            .map(
              (ticketRow) => TicketRecord(
                code: ticketRow['ticket_code'] as String,
                status: _statusFromDb(ticketRow['status'] as String),
                scannedAt: ticketRow['scanned_at'] == null
                    ? null
                    : DateTime.parse(ticketRow['scanned_at'] as String).toLocal(),
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
