import 'package:flutter/widgets.dart';

import '../core/app_scope.dart';
import '../core/constants/app_constants.dart';
import '../core/models/app_settings.dart';
import '../l10n/l10n_extensions.dart';
import '../widgets/core/app_scaffold.dart';
import '../widgets/core/screen_nav_bar.dart';
import '../widgets/core/section_header.dart';
import '../widgets/icons/semantic_icons.dart';
import '../widgets/settings/setting_choice_tile.dart';

/// Settings. Other sections arrive with the batches that need them.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    final l10n = context.l10n;
    return AppScaffold(
      top: ScreenNavBar(
        title: l10n.settingsTitle,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ValueListenableBuilder<AppSettings>(
        valueListenable: deps.settings,
        builder: (BuildContext context, AppSettings settings, Widget? _) {
          return ListView(
            children: <Widget>[
              SectionHeader(l10n.settingsAppearance),
              SettingChoiceTile<AppThemeMode>(
                title: l10n.settingsTheme,
                glyph: AppIcons.moon,
                value: settings.themeMode,
                choices: <SettingChoice<AppThemeMode>>[
                  SettingChoice<AppThemeMode>(
                    value: AppThemeMode.system,
                    label: l10n.themeSystem,
                  ),
                  SettingChoice<AppThemeMode>(
                    value: AppThemeMode.light,
                    label: l10n.themeLight,
                  ),
                  SettingChoice<AppThemeMode>(
                    value: AppThemeMode.dark,
                    label: l10n.themeDark,
                  ),
                ],
                onChanged: deps.settings.setThemeMode,
              ),
              SectionHeader(l10n.settingsSearch),
              SettingChoiceTile<String>(
                title: l10n.settingsSearchEngine,
                glyph: AppIcons.search,
                value: settings.searchEngineId,
                choices: <SettingChoice<String>>[
                  for (final SearchEngine e in AppConstants.searchEngines)
                    SettingChoice<String>(value: e.id, label: e.name),
                ],
                onChanged: deps.settings.setSearchEngine,
              ),
            ],
          );
        },
      ),
    );
  }
}
