import 'dart:typed_data';

import 'qr_download_stub.dart'
    if (dart.library.html) 'qr_download_web.dart' as qr_download;

Future<void> downloadQrImage({
  required Uint8List bytes,
  required String fileName,
}) {
  return qr_download.downloadQrImage(bytes: bytes, fileName: fileName);
}
