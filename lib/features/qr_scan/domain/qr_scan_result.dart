import 'package:waterpark/features/staff_access/domain/staff_member.dart';

enum QrScanStatus {
  idle,
  validStaff,
  validTicket,
  alreadyUsedTicket,
  voidedTicket,
  unknownTicket,
  unknownStaff,
  invalidFormat,
  tamperedData,
  scanError,
}

class QrScanResult {
  const QrScanResult({
    required this.status,
    required this.title,
    required this.message,
    this.rawValue,
    this.staffMember,
    this.ticketCode,
    this.ticketBatchLabel,
    this.ticketType,
    this.ticketStatusLabel,
    this.scannedAt,
  });

  const QrScanResult.idle()
    : status = QrScanStatus.idle,
      title = 'Ready to Scan',
      message =
          'Point the camera at a staff QR code. The scanner will verify the code against the staff database.',
      rawValue = null,
      staffMember = null,
      ticketCode = null,
      ticketBatchLabel = null,
      ticketType = null,
      ticketStatusLabel = null,
      scannedAt = null;

  final QrScanStatus status;
  final String title;
  final String message;
  final String? rawValue;
  final StaffMember? staffMember;
  final String? ticketCode;
  final String? ticketBatchLabel;
  final String? ticketType;
  final String? ticketStatusLabel;
  final DateTime? scannedAt;

  bool get isResolved => status != QrScanStatus.idle;
}
