import 'dart:typed_data';

import 'package:universal_html/html.dart' as html;

class WebFileDownloader {
  const WebFileDownloader._();

  static void downloadBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
    anchor.remove();
  }
}
