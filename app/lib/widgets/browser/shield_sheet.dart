import 'package:flutter/widgets.dart';

import '../../core/app_scope.dart';
import '../../core/constants/route_names.dart';
import '../../core/constants/spacing.dart';
import '../../core/theme/theme_builder.dart';
import '../../l10n/l10n_extensions.dart';
import '../core/premium_bottom_sheet.dart';
import '../core/premium_card.dart';
import '../icons/semantic_icons.dart';
import '../settings/setting_switch.dart';

/// The sheet the shield opens: the site, one switch for ad blocking on it, and
/// a way to the full ad blocking screen. Replaced by the full site settings
/// sheet in the web-compatibility batch.
Future<void> showShieldSheet({
  required BuildContext context,
  required AppDependencies deps,
  required String host,
}) {
  return showPremiumBottomSheet<void>(
    context: context,
    title: context.l10n.shieldSheetTitle,
    builder: (BuildContext sheetContext) {
      final l10n = sheetContext.l10n;
      final theme = AppTheme.of(sheetContext);
      return ListenableBuilder(
        listenable: deps.adblock,
        builder: (BuildContext context, Widget? _) {
          return Padding(
            padding: AppInsets.symmetric(
              horizontal: Spacing.m,
              vertical: Spacing.s,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  host,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text.callout.copyWith(
                    color: theme.palette.textSecondary,
                  ),
                ),
                SettingSwitch(
                  title: l10n.shieldSwitch,
                  subtitle: deps.adblock.enabled ? null : l10n.shieldGlobalOff,
                  glyph: AppIcons.shieldCheck,
                  value: deps.siteSettings.forHost(host).adblockEnabled,
                  onChanged: (bool on) =>
                      deps.siteSettings.setAdblock(host, enabled: on),
                ),
                const SizedBox(height: Spacing.s),
                PremiumCard(
                  label: l10n.shieldMoreSettings,
                  leading: AppIcons.settings,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).pushNamed<void>(RouteNames.adblock);
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
