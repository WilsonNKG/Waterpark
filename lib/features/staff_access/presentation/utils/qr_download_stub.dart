import 'dart:typed_data';

Future<void> downloadQrImage({
  required Uint8List bytes,
  required String fileName,
}) async {
  throw UnsupportedError('QR download is only available on web right now.');
}
