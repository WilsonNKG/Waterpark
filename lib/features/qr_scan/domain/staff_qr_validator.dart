import 'package:waterpark/features/qr_scan/domain/qr_scan_result.dart';
import 'package:waterpark/features/staff_access/domain/staff_member.dart';

class StaffQrValidator {
  const StaffQrValidator();

  QrScanResult validate({
    required String rawValue,
    required List<StaffMember> staffMembers,
  }) {
    final normalized = rawValue.trim();
    final parts = normalized.split('|');

    if (parts.length < 4 || parts.first != 'STAFF') {
      return QrScanResult(
        status: QrScanStatus.invalidFormat,
        title: 'Invalid QR',
        message:
            'This QR code does not match the expected staff format. It may belong to a different system.',
        rawValue: normalized,
      );
    }

    final staffCode = parts[1];
    final scannedName = parts[2];
    final scannedRole = parts[3];

    final matchedStaff = staffMembers
        .where((member) => member.staffCode == staffCode)
        .cast<StaffMember?>()
        .firstWhere((member) => member != null, orElse: () => null);

    if (matchedStaff == null) {
      return QrScanResult(
        status: QrScanStatus.unknownStaff,
        title: 'Unknown Staff QR',
        message:
            'The QR format is valid, but the staff code was not found in the database.',
        rawValue: normalized,
      );
    }

    final nameMatches = matchedStaff.name == scannedName;
    final roleMatches = matchedStaff.role == scannedRole;

    if (!nameMatches || !roleMatches) {
      return QrScanResult(
        status: QrScanStatus.tamperedData,
        title: 'QR Data Mismatch',
        message:
            'The staff code exists, but the embedded staff details do not match the current database record.',
        rawValue: normalized,
        staffMember: matchedStaff,
      );
    }

    return QrScanResult(
      status: QrScanStatus.validStaff,
      title: 'Staff Verified',
      message:
          '${matchedStaff.name} is a valid staff member with role ${matchedStaff.role}.',
      rawValue: normalized,
      staffMember: matchedStaff,
    );
  }
}
