import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waterpark/features/staff_access/domain/staff_member.dart';

abstract class StaffRepository {
  Future<List<StaffMember>> fetchStaff();
  Future<StaffMember> createStaff(StaffDraft draft);
  Future<void> deleteStaff(String id);
  Future<StaffMember> saveQr(String id, String qrPayload);
  Future<StaffMember> deleteQr(String id);

  factory StaffRepository.create() {
    try {
      return SupabaseStaffRepository(Supabase.instance.client);
    } catch (_) {
      throw StateError(
        'Supabase is not initialized. Start the app with your Supabase configuration.',
      );
    }
  }
}

class SupabaseStaffRepository implements StaffRepository {
  SupabaseStaffRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'staff_members';

  @override
  Future<StaffMember> createStaff(StaffDraft draft) async {
    try {
      final row = await _client
          .from(_table)
          .insert({'name': draft.name, 'role': draft.role})
          .select()
          .single();

      return StaffMember.fromMap(row);
    } on PostgrestException catch (error) {
      if (!_needsLegacySchemaRetry(error)) {
        rethrow;
      }

      final row = await _client
          .from(_table)
          .insert(_buildLegacyInsertPayload(draft))
          .select()
          .single();

      return StaffMember.fromMap(row);
    }
  }

  @override
  Future<void> deleteStaff(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  @override
  Future<StaffMember> deleteQr(String id) async {
    final row = await _client
        .from(_table)
        .update({'qr_payload': null})
        .eq('id', id)
        .select()
        .single();

    return StaffMember.fromMap(row);
  }

  @override
  Future<List<StaffMember>> fetchStaff() async {
    final rows = await _client
        .from(_table)
        .select()
        .order('staff_number', ascending: true);

    return rows.map(StaffMember.fromMap).toList();
  }

  @override
  Future<StaffMember> saveQr(String id, String qrPayload) async {
    final row = await _client
        .from(_table)
        .update({'qr_payload': qrPayload})
        .eq('id', id)
        .select()
        .single();

    return StaffMember.fromMap(row);
  }

  bool _needsLegacySchemaRetry(PostgrestException error) {
    final details = error.details?.toString() ?? '';
    final payload = '${error.message} $details'.toLowerCase();

    return error.code == '23502' &&
        (payload.contains('"category"') || payload.contains('"shift"'));
  }

  Map<String, Object> _buildLegacyInsertPayload(StaffDraft draft) {
    return {
      'name': draft.name,
      'role': draft.role,
      'category': _legacyCategoryForRole(draft.role),
      'shift': _legacyShiftForRole(draft.role),
    };
  }

  String _legacyCategoryForRole(String role) {
    final normalized = role.trim().toLowerCase();

    if (normalized.contains('security')) {
      return 'security';
    }

    if (normalized.contains('clean') ||
        normalized.contains('maint') ||
        normalized.contains('support')) {
      return 'support';
    }

    if (normalized.contains('weekend') ||
        normalized.contains('seasonal') ||
        normalized.contains('temporary')) {
      return 'seasonal';
    }

    if (normalized.contains('manager') ||
        normalized.contains('admin') ||
        normalized.contains('finance') ||
        normalized.contains('hr')) {
      return 'management';
    }

    return 'operations';
  }

  String _legacyShiftForRole(String role) {
    final normalized = role.trim().toLowerCase();

    if (normalized.contains('security') || normalized.contains('clean')) {
      return 'Flexible';
    }

    if (normalized.contains('weekend') || normalized.contains('seasonal')) {
      return 'Weekend';
    }

    return 'General';
  }
}
