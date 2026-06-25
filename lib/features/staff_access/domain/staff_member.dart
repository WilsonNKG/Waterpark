List<String> buildStaffRoleOptions(Iterable<String> roles) {
  final uniqueRoles = <String>{};

  for (final role in roles) {
    final normalized = role.trim();
    if (normalized.isEmpty) {
      continue;
    }
    uniqueRoles.add(normalized);
  }

  final sortedRoles = uniqueRoles.toList()..sort();
  return sortedRoles;
}

class StaffMember {
  const StaffMember({
    required this.id,
    required this.staffCode,
    required this.name,
    required this.role,
    this.qrPayload,
    this.createdAt,
  });

  final String id;
  final String staffCode;
  final String name;
  final String role;
  final String? qrPayload;
  final DateTime? createdAt;

  bool get hasQr => qrPayload != null && qrPayload!.isNotEmpty;

  String get status => hasQr ? 'QR Ready' : 'No QR';

  StaffMember copyWith({
    String? id,
    String? staffCode,
    String? name,
    String? role,
    String? qrPayload,
    bool clearQr = false,
    DateTime? createdAt,
  }) {
    return StaffMember(
      id: id ?? this.id,
      staffCode: staffCode ?? this.staffCode,
      name: name ?? this.name,
      role: role ?? this.role,
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
      qrPayload: map['qr_payload'] as String?,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
    );
  }
}

class StaffDraft {
  const StaffDraft({required this.name, required this.role});

  final String name;
  final String role;
}
