import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

Future<void> downloadQrImage({
  required Uint8List bytes,
  required String fileName,
}) async {
  final base64Data = base64Encode(bytes);
  final url = 'data:image/png;base64,$base64Data';
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
}
