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
    final row = await _client
        .from(_table)
        .insert({
          'name': draft.name,
          'role': draft.role,
          'category': draft.category.key,
          'shift': draft.shift,
        })
        .select()
        .single();

    return StaffMember.fromMap(row);
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
}
