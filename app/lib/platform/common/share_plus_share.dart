import 'package:share_plus/share_plus.dart' as plus;

import '../../core/contracts/share.dart';

/// [Share] over `share_plus`.
class SharePlusShare implements Share {
  SharePlusShare({Future<void> Function(plus.ShareParams params)? share})
    : _share = share ?? _systemShare;

  final Future<void> Function(plus.ShareParams params) _share;

  static Future<void> _systemShare(plus.ShareParams params) async {
    await plus.SharePlus.instance.share(params);
  }

  @override
  Future<void> shareUrl(Uri url, {String? title}) async {
    try {
      await _share(plus.ShareParams(uri: url, title: title, subject: title));
    } on Exception {
      // Sharing is best effort: a closed or unavailable sheet is not an error.
    }
  }
}
