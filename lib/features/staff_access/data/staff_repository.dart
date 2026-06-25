import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waterpark/features/staff_access/domain/staff_member.dart';

abstract class StaffRepository {
  Future<List<StaffMember>> fetchStaff();
  Future<List<String>> fetchRoles();
  Future<String> createRole(String role);
  Future<void> deleteRole(String role);
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
  static const _staffTable = 'staff_members';
  static const _rolesTable = 'staff_roles';

  @override
  Future<String> createRole(String role) async {
    final normalizedRole = role.trim();
    final row = await _client
        .from(_rolesTable)
        .upsert({'role_name': normalizedRole}, onConflict: 'role_name')
        .select('role_name')
        .single();

    return row['role_name'] as String;
  }

  @override
  Future<StaffMember> createStaff(StaffDraft draft) async {
    final row = await _client
        .from(_staffTable)
        .insert({
          'name': draft.name,
          'role': draft.role,
          'staff_type': draft.staffType.dbValue,
          'unit_number': draft.unitNumber,
        })
        .select()
        .single();

    return StaffMember.fromMap(row);
  }

  @override
  Future<void> deleteStaff(String id) async {
    await _client.from(_staffTable).delete().eq('id', id);
  }

  @override
  Future<void> deleteRole(String role) async {
    await _client.from(_rolesTable).delete().eq('role_name', role);
  }

  @override
  Future<StaffMember> deleteQr(String id) async {
    final row = await _client
        .from(_staffTable)
        .update({'qr_payload': null})
        .eq('id', id)
        .select()
        .single();

    return StaffMember.fromMap(row);
  }

  @override
  Future<List<StaffMember>> fetchStaff() async {
    final rows = await _client
        .from(_staffTable)
        .select()
        .order('staff_number', ascending: true);

    return rows.map(StaffMember.fromMap).toList();
  }

  @override
  Future<List<String>> fetchRoles() async {
    final rows = await _client
        .from(_rolesTable)
        .select('role_name')
        .order('role_name', ascending: true);

    return rows
        .map((row) => (row['role_name'] as String?)?.trim() ?? '')
        .where((role) => role.isNotEmpty)
        .toList();
  }

  @override
  Future<StaffMember> saveQr(String id, String qrPayload) async {
    final row = await _client
        .from(_staffTable)
        .update({'qr_payload': qrPayload})
        .eq('id', id)
        .select()
        .single();

    return StaffMember.fromMap(row);
  }
}
