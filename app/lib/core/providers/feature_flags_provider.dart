import 'package:flutter/foundation.dart';

import '../blocklist/blocklist_service.dart';

/// The features the signed manifest can switch off for everyone.
enum FeatureFlag { blocklistRefresh, tier3Downloads, reader, translation, cast }

/// Kill switches. Every feature is on unless the verified manifest in use says
/// otherwise; nothing is fetched separately, so a flag only changes with a list.
class FeatureFlagsProvider extends ChangeNotifier {
  FeatureFlagsProvider(this._blocklist) {
    _blocklist.addListener(notifyListeners);
  }

  final BlocklistService _blocklist;

  bool isEnabled(FeatureFlag flag) => _blocklist.flags[flag.name] ?? true;

  @override
  void dispose() {
    _blocklist.removeListener(notifyListeners);
    super.dispose();
  }
}
