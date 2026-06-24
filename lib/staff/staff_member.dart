import 'package:flutter/material.dart';
import 'package:waterpark/core/waterpark_brand.dart';

enum StaffCategory {
  management(
    key: 'management',
    label: 'Management',
    description: 'Manager, admin, finance, HR',
    color: WaterparkBrand.primaryBlue,
    icon: Icons.apartment_rounded,
  ),
  operations(
    key: 'operations',
    label: 'Operations',
    description: 'Pool, rides, lifeguard, cashier',
    color: WaterparkBrand.aqua,
    icon: Icons.pool_rounded,
  ),
  security(
    key: 'security',
    label: 'Security',
    description: 'Gate check and perimeter control',
    color: WaterparkBrand.accentRed,
    icon: Icons.shield_outlined,
  ),
  support(
    key: 'support',
    label: 'Support',
    description: 'Cleaning, maintenance, utilities',
    color: WaterparkBrand.warning,
    icon: Icons.build_circle_outlined,
  ),
  seasonal(
    key: 'seasonal',
    label: 'Seasonal',
    description: 'Temporary crew for peak days',
    color: Color(0xFF7A67EE),
    icon: Icons.event_available_rounded,
  );

  const StaffCategory({
    required this.key,
    required this.label,
    required this.description,
    required this.color,
    required this.icon,
  });

  final String key;
  final String label;
  final String description;
  final Color color;
  final IconData icon;

  static StaffCategory fromKey(String key) {
    return StaffCategory.values.firstWhere(
      (value) => value.key == key,
      orElse: () => StaffCategory.operations,
    );
  }
}

class StaffMember {
  const StaffMember({
    required this.id,
    required this.staffCode,
    required this.name,
    required this.role,
    required this.category,
    required this.shift,
    this.qrPayload,
    this.createdAt,
  });

  final String id;
  final String staffCode;
  final String name;
  final String role;
  final StaffCategory category;
  final String shift;
  final String? qrPayload;
  final DateTime? createdAt;

  bool get hasQr => qrPayload != null && qrPayload!.isNotEmpty;

  String get status => hasQr ? 'QR Ready' : 'No QR';

  StaffMember copyWith({
    String? id,
    String? staffCode,
    String? name,
    String? role,
    StaffCategory? category,
    String? shift,
    String? qrPayload,
    bool clearQr = false,
    DateTime? createdAt,
  }) {
    return StaffMember(
      id: id ?? this.id,
      staffCode: staffCode ?? this.staffCode,
      name: name ?? this.name,
      role: role ?? this.role,
      category: category ?? this.category,
      shift: shift ?? this.shift,
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
      category: StaffCategory.fromKey(map['category'] as String),
      shift: map['shift'] as String,
      qrPayload: map['qr_payload'] as String?,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'name': name,
      'role': role,
      'category': category.key,
      'shift': shift,
      'qr_payload': qrPayload,
    };
  }
}

class StaffDraft {
  const StaffDraft({
    required this.name,
    required this.role,
    required this.category,
    required this.shift,
  });

  final String name;
  final String role;
  final StaffCategory category;
  final String shift;
}
