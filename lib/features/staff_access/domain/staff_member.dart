const kCanteenTenantRole = 'Canteen Tenant';
const kStandTenantRole = 'Stand Tenant';

enum StaffType { officialStaff, canteenTenant, standTenant }

extension StaffTypeX on StaffType {
  String get dbValue => switch (this) {
    StaffType.officialStaff => 'official_staff',
    StaffType.canteenTenant => 'canteen_tenant',
    StaffType.standTenant => 'stand_tenant',
  };

  String get label => switch (this) {
    StaffType.officialStaff => 'Official Staff',
    StaffType.canteenTenant => 'Canteen Tenant',
    StaffType.standTenant => 'Stand Tenant',
  };

  bool get requiresUnitNumber => this != StaffType.officialStaff;

  String get fixedRole => switch (this) {
    StaffType.officialStaff => '',
    StaffType.canteenTenant => kCanteenTenantRole,
    StaffType.standTenant => kStandTenantRole,
  };

  String get unitLabel => switch (this) {
    StaffType.officialStaff => '',
    StaffType.canteenTenant => 'Canteen Number',
    StaffType.standTenant => 'Stand Number',
  };

  String assignmentLabel(int? unitNumber, {String? role}) => switch (this) {
    StaffType.officialStaff => role ?? '-',
    StaffType.canteenTenant => 'Canteen ${unitNumber ?? '-'}',
    StaffType.standTenant => 'Stand ${unitNumber ?? '-'}',
  };
}

StaffType staffTypeFromDb(String? value) {
  return switch (value) {
    'canteen_guard' || 'canteen_tenant' => StaffType.canteenTenant,
    'stand_guard' || 'stand_tenant' => StaffType.standTenant,
    _ => StaffType.officialStaff,
  };
}

List<String> buildStaffRoleOptions(Iterable<String> roles) {
  final uniqueRoles = <String>{};

  for (final role in roles) {
    final normalized = role.trim();
    if (normalized.isEmpty) {
      continue;
    }
    uniqueRoles.add(normalized);
  }

  return uniqueRoles.toList()..sort();
}

List<String> buildOfficialRoleOptions(Iterable<String> roles) {
  return buildStaffRoleOptions(
    roles.where(
      (role) => role != kCanteenTenantRole && role != kStandTenantRole,
    ),
  );
}

class StaffMember {
  const StaffMember({
    required this.id,
    required this.staffCode,
    required this.name,
    required this.role,
    required this.staffType,
    this.unitNumber,
    this.qrPayload,
    this.createdAt,
  });

  final String id;
  final String staffCode;
  final String name;
  final String role;
  final StaffType staffType;
  final int? unitNumber;
  final String? qrPayload;
  final DateTime? createdAt;

  bool get hasQr => qrPayload != null && qrPayload!.isNotEmpty;
  String get status => hasQr ? 'QR Ready' : 'No QR';
  String get groupLabel => staffType.label;
  String get assignmentLabel =>
      staffType.assignmentLabel(unitNumber, role: role);
  String get shortDescriptor => '$groupLabel • $assignmentLabel';
  String get qrUnitValue => unitNumber?.toString() ?? '';

  StaffMember copyWith({
    String? id,
    String? staffCode,
    String? name,
    String? role,
    StaffType? staffType,
    int? unitNumber,
    bool clearUnitNumber = false,
    String? qrPayload,
    bool clearQr = false,
    DateTime? createdAt,
  }) {
    return StaffMember(
      id: id ?? this.id,
      staffCode: staffCode ?? this.staffCode,
      name: name ?? this.name,
      role: role ?? this.role,
      staffType: staffType ?? this.staffType,
      unitNumber: clearUnitNumber ? null : (unitNumber ?? this.unitNumber),
      qrPayload: clearQr ? null : (qrPayload ?? this.qrPayload),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory StaffMember.fromMap(Map<String, dynamic> map) {
    return StaffMember(
      id: map['id'] as String,
      staffCode: map['staff_code'] as String,
      name: map['name'] as String,
      role: map['role'] as String,
      staffType: staffTypeFromDb(map['staff_type'] as String?),
      unitNumber: map['unit_number'] as int?,
      qrPayload: map['qr_payload'] as String?,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
    );
  }
}

class StaffDraft {
  const StaffDraft({
    required this.name,
    required this.staffType,
    required this.role,
    this.unitNumber,
  });

  final String name;
  final StaffType staffType;
  final String role;
  final int? unitNumber;
}
