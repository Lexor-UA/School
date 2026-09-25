import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

class ChatImageHelper {
  /// Maximum characters for Base64 Data URI in Firestore to stay safely below the 1MB (1,048,576 byte) document limit.
  static const int maxBase64Length = 700000;

  /// Ensures that image bytes encoded to Base64 Data URI do not exceed the Firestore 1MB document limit.
  /// If the initial Base64 exceeds [maxBase64Length], it progressively downscales the image using [dart:ui.instantiateImageCodec].
  static Future<String> toSafeDataUri(Uint8List bytes) async {
    String base64String = base64Encode(bytes);
    String dataUri = 'data:image/jpeg;base64,$base64String';

    if (dataUri.length <= maxBase64Length) {
      return dataUri;
    }

    debugPrint('Chat image Data URI is ${dataUri.length} chars (exceeds $maxBase64Length). Progressively downscaling via dart:ui...');

    // Progressively downscale (720 -> 560 -> 400 -> 300) until safely under limit
    int currentWidth = 720;
    while (dataUri.length > maxBase64Length && currentWidth >= 280) {
      try {
        final downscaledBytes = await _resizeImage(bytes, targetWidth: currentWidth);
        if (downscaledBytes != null) {
          final newBase64 = base64Encode(downscaledBytes);
          final newUri = 'data:image/png;base64,$newBase64';
          if (newUri.length < dataUri.length) {
            dataUri = newUri;
          }
        }
      } catch (e) {
        debugPrint('Failed to downscale image to $currentWidth: $e');
      }
      currentWidth -= 160;
    }

    return dataUri;
  }

  static Future<Uint8List?> _resizeImage(Uint8List bytes, {required int targetWidth}) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: targetWidth,
    );
    final frameInfo = await codec.getNextFrame();
    final byteData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}
