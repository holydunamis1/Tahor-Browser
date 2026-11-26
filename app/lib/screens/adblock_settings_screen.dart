import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/app_scope.dart';
import '../core/blocklist/blocklist_service.dart';
import '../core/constants/spacing.dart';
import '../core/theme/theme_builder.dart';
import '../core/utils/formatters.dart';
import '../l10n/l10n_extensions.dart';
import '../widgets/core/app_scaffold.dart';
import '../widgets/core/icon_chip.dart';
import '../widgets/core/premium_card.dart';
import '../widgets/core/premium_row.dart';
import '../widgets/core/primary_button.dart';
import '../widgets/core/screen_nav_bar.dart';
import '../widgets/core/section_header.dart';
import '../widgets/icons/semantic_icons.dart';
import '../widgets/settings/setting_switch.dart';

/// Ad blocking: the global switch, which filter list is in use and when it was
/// last checked, an Update button with an explicit result, the weekly check,
/// the sites where blocking is off, and what blocking does not do.
class AdblockSettingsScreen extends StatefulWidget {
  const AdblockSettingsScreen({super.key});

  @override
  State<AdblockSettingsScreen> createState() => _AdblockSettingsScreenState();
}

class _AdblockSettingsScreenState extends State<AdblockSettingsScreen> {
  bool _updating = false;

  Future<void> _update(AppDependencies deps) async {
    // Read before the await: the context may not be usable afterwards.
    final l10n = context.l10n;
    setState(() => _updating = true);
    final RefreshOutcome outcome = await deps.adblock.refreshNow();
    if (mounted) {
      setState(() => _updating = false);
    }
    switch (outcome) {
      case RefreshOutcome.updated:
        deps.feedback.show(l10n.adblockUpdated);
      case RefreshOutcome.upToDate:
        deps.feedback.show(l10n.adblockUpToDate);
      case RefreshOutcome.failed:
        deps.feedback.show(l10n.adblockUpdateFailed, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppDependencies deps = AppScope.of(context);
    final l10n = context.l10n;
    final theme = AppTheme.of(context);
    return AppScaffold(
      top: ScreenNavBar(
        title: l10n.adblockTitle,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          deps.adblock,
          deps.blocklist,
          deps.settings,
        ]),
        builder: (BuildContext context, Widget? _) {
          final BlocklistStatus status = deps.blocklist.value;
          final String locale = Localizations.localeOf(context).toString();
          final String source = switch (status.source) {
            BlocklistSource.bundled => l10n.adblockSourceBundled,
            BlocklistSource.downloaded => l10n.adblockSourceDownloaded,
            BlocklistSource.none => l10n.adblockSourceNone,
          };
          final List<String> exceptions = deps.siteSettings.adblockExceptions;
          return ListView(
            padding: AppInsets.symmetric(vertical: Spacing.s),
            children: <Widget>[
              SettingSwitch(
                title: l10n.adblockSwitch,
                subtitle: l10n.adblockSwitchHint,
                glyph: AppIcons.shieldCheck,
                value: deps.settings.value.adblockEnabled,
                onChanged: deps.settings.setAdblockEnabled,
              ),
              SectionHeader(l10n.adblockListSection),
              PremiumCard(
                label: l10n.adblockListVersion,
                value: '${status.version}',
                showChevron: false,
              ),
              PremiumCard(
                label: l10n.adblockListRules,
                value: formatNumber(status.ruleCount, locale: locale),
                showChevron: false,
              ),
              PremiumCard(
                label: l10n.adblockListSource,
                value: source,
                showChevron: false,
              ),
              PremiumCard(
                label: l10n.adblockChecked,
                value: status.checkedAt == null
                    ? l10n.adblockNeverChecked
                    : formatDate(status.checkedAt!, locale: locale),
                showChevron: false,
              ),
              Padding(
                padding: AppInsets.all(Spacing.m),
                child: deps.adblock.canRefresh
                    ? PrimaryButton(
                        label: _updating
                            ? l10n.adblockUpdating
                            : l10n.adblockUpdateNow,
                        glyph: AppIcons.reload,
                        onPressed: _updating
                            ? null
                            : () => unawaited(_update(deps)),
                      )
                    : Text(
                        l10n.adblockUpdatesPaused,
                        style: theme.text.footnote.copyWith(
                          color: theme.palette.textSecondary,
                        ),
                      ),
              ),
              SettingSwitch(
                title: l10n.adblockWeekly,
                subtitle: l10n.adblockWeeklyHint,
                glyph: AppIcons.reload,
                value: deps.settings.value.blocklistAutoUpdate,
                onChanged: deps.settings.setBlocklistAutoUpdate,
              ),
              SectionHeader(l10n.adblockExceptions),
              if (exceptions.isEmpty)
                Padding(
                  padding: AppInsets.symmetric(
                    horizontal: Spacing.m,
                    vertical: Spacing.s,
                  ),
                  child: Text(
                    l10n.adblockExceptionsEmpty,
                    style: theme.text.footnote.copyWith(
                      color: theme.palette.textSecondary,
                    ),
                  ),
                )
              else
                for (final String host in exceptions)
                  PremiumRow(
                    key: ValueKey<String>('exception-$host'),
                    title: host,
                    trailing: IconChip(
                      glyph: AppIcons.close,
                      semanticLabel: l10n.adblockExceptionRemove(host),
                      onTap: () =>
                          deps.siteSettings.setAdblock(host, enabled: true),
                    ),
                  ),
              Padding(
                padding: AppInsets.all(Spacing.m),
                child: Text(
                  l10n.adblockLimits,
                  style: theme.text.footnote.copyWith(
                    color: theme.palette.textSecondary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
