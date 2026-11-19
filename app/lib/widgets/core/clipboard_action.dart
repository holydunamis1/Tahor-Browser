import 'package:flutter/services.dart';

/// Puts [text] on the clipboard. Returns false when the system refuses.
Future<bool> copyToClipboard(String text) async {
  try {
    await Clipboard.setData(ClipboardData(text: text));
    return true;
  } on PlatformException {
    return false;
  }
}
