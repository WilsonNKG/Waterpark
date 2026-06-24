import 'package:waterpark/features/staff_access/domain/staff_member.dart';

enum QrScanStatus {
  idle,
  validStaff,
  unknownStaff,
  invalidFormat,
  tamperedData,
}

class QrScanResult {
  const QrScanResult({
    required this.status,
    required this.title,
    required this.message,
    this.rawValue,
    this.staffMember,
  });

  const QrScanResult.idle()
    : status = QrScanStatus.idle,
      title = 'Ready to Scan',
      message =
          'Point the camera at a staff QR code. The scanner will verify the code against the staff database.',
      rawValue = null,
      staffMember = null;

  final QrScanStatus status;
  final String title;
  final String message;
  final String? rawValue;
  final StaffMember? staffMember;

  bool get isResolved => status != QrScanStatus.idle;
}
