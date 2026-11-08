import 'dart:typed_data';

import 'package:image/image.dart' as image_codec;

Uint8List sanitizePostImage(Uint8List bytes) {
  final decoded = image_codec.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('No se pudo procesar esa foto.');
  }

  final oriented = image_codec.bakeOrientation(decoded);
  final pixels = oriented.getBytes(order: image_codec.ChannelOrder.rgb);
  final clean = image_codec.Image.fromBytes(
    width: oriented.width,
    height: oriented.height,
    bytes: pixels.buffer,
    bytesOffset: pixels.offsetInBytes,
    numChannels: 3,
    order: image_codec.ChannelOrder.rgb,
  );
  return Uint8List.fromList(image_codec.encodeJpg(clean, quality: 82));
}
