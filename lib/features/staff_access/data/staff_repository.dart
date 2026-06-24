import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waterpark/core/config/app_config.dart';
import 'package:waterpark/features/staff_access/domain/staff_member.dart';

abstract class StaffRepository {
  Future<List<StaffMember>> fetchStaff();
  Future<StaffMember> createStaff(StaffDraft draft);
  Future<void> deleteStaff(String id);
  Future<StaffMember> saveQr(String id, String qrPayload);
  Future<StaffMember> deleteQr(String id);

  factory StaffRepository.create() {
    if (AppConfig.hasSupabase) {
      return SupabaseStaffRepository(Supabase.instance.client);
    }
    return LocalStaffRepository();
  }
}

class LocalStaffRepository implements StaffRepository {
  final List<StaffMember> _staffMembers = [
    StaffMember(
      id: 'local-1',
      staffCode: 'STF-001',
      name: 'Anita Prameswari',
      role: 'Operations Supervisor',
      category: StaffCategory.operations,
      shift: 'Morning',
      qrPayload: 'STAFF|STF-001|Anita Prameswari|operations|Morning',
    ),
    StaffMember(
      id: 'local-2',
      staffCode: 'STF-002',
      name: 'Budi Hartono',
      role: 'Gate Validation Lead',
      category: StaffCategory.security,
      shift: 'Morning',
      qrPayload: 'STAFF|STF-002|Budi Hartono|security|Morning',
    ),
    StaffMember(
      id: 'local-3',
      staffCode: 'STF-003',
      name: 'Clara Wibowo',
      role: 'Finance Admin',
      category: StaffCategory.management,
      shift: 'Office',
    ),
    StaffMember(
      id: 'local-4',
      staffCode: 'STF-004',
      name: 'Dimas Saputra',
      role: 'Lifeguard',
      category: StaffCategory.operations,
      shift: 'Afternoon',
    ),
    StaffMember(
      id: 'local-5',
      staffCode: 'STF-005',
      name: 'Eka Lestari',
      role: 'Cleaning Crew',
      category: StaffCategory.support,
      shift: 'Split',
      qrPayload: 'STAFF|STF-005|Eka Lestari|support|Split',
    ),
    StaffMember(
      id: 'local-6',
      staffCode: 'STF-006',
      name: 'Farhan Maulana',
      role: 'Weekend Crew',
      category: StaffCategory.seasonal,
      shift: 'Weekend',
    ),
  ];

  @override
  Future<StaffMember> createStaff(StaffDraft draft) async {
    final nextNumber =
        _staffMembers
            .map(
              (member) => int.tryParse(member.staffCode.split('-').last) ?? 0,
            )
            .fold<int>(0, (current, next) => next > current ? next : current) +
        1;

    final created = StaffMember(
      id: 'local-$nextNumber',
      staffCode: 'STF-${nextNumber.toString().padLeft(3, '0')}',
      name: draft.name,
      role: draft.role,
      category: draft.category,
      shift: draft.shift,
    );

    _staffMembers.add(created);
    return created;
  }

  @override
  Future<void> deleteStaff(String id) async {
    _staffMembers.removeWhere((member) => member.id == id);
  }

  @override
  Future<StaffMember> deleteQr(String id) async {
    final index = _staffMembers.indexWhere((member) => member.id == id);
    final updated = _staffMembers[index].copyWith(clearQr: true);
    _staffMembers[index] = updated;
    return updated;
  }

  @override
  Future<List<StaffMember>> fetchStaff() async {
    return List<StaffMember>.from(_staffMembers);
  }

  @override
  Future<StaffMember> saveQr(String id, String qrPayload) async {
    final index = _staffMembers.indexWhere((member) => member.id == id);
    final updated = _staffMembers[index].copyWith(qrPayload: qrPayload);
    _staffMembers[index] = updated;
    return updated;
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
