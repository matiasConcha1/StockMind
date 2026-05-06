import 'dart:math';

String generateBarcodeValue() {
  final random = Random();
  final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  final suffix = List.generate(4, (_) => random.nextInt(10)).join();
  return '$timestamp$suffix';
}

String generateQrCodeValue({
  required String productId,
  required String barcode,
}) {
  return productId.isNotEmpty ? productId : barcode;
}

