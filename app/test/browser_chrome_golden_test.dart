import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/theme/dark_theme.dart';
import 'package:tahorbrowser/core/theme/light_theme.dart';
import 'package:tahorbrowser/widgets/browser/address_bar.dart';
import 'package:tahorbrowser/widgets/browser/browser_menu_sheet.dart';
import 'package:tahorbrowser/widgets/browser/browser_nav_bar.dart';
import 'package:tahorbrowser/widgets/browser/page_progress_bar.dart';
import 'package:tahorbrowser/widgets/core/premium_dialog.dart';
import 'package:tahorbrowser/widgets/icons/semantic_icons.dart';
import 'package:tahorbrowser/widgets/settings/setting_switch.dart';
import 'package:tahorbrowser/widgets/settings/setting_tile.dart';

import 'support/golden_helpers.dart';

Widget chromeSheet() {
  Widget nav({required bool loading, required bool back}) => BrowserNavBar(
    canGoBack: back,
    canGoForward: false,
    isLoading: loading,
    onBack: () {},
    onForward: () {},
    onReload: () {},
    onStop: () {},
    onMenu: () {},
  );

  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AddressBar(url: '', onSubmitted: (String _) {}),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AddressBar(
            url: 'https://www.example.com/article',
            onSubmitted: (String _) {},
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AddressBar(
            url: 'http://old.example.org/',
            onSubmitted: (String _) {},
          ),
        ),
        const SizedBox(height: 8),
        const PageProgressBar(progress: 0.6, isLoading: true),
        const SizedBox(height: 16),
        nav(loading: false, back: true),
        nav(loading: true, back: false),
        const SizedBox(height: 16),
        SettingTile(
          title: 'Search engine',
          value: 'DuckDuckGo',
          glyph: AppIcons.search,
          onTap: () {},
        ),
        SettingSwitch(
          title: 'Save history',
          subtitle: 'Off by default',
          glyph: AppIcons.history,
          value: false,
          onChanged: (bool _) {},
        ),
        SettingSwitch(
          title: 'HTTPS only',
          glyph: AppIcons.lock,
          value: true,
          onChanged: (bool _) {},
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 420,
          child: BrowserMenuSheet(
            actions: <MenuAction>[
              MenuAction(
                id: 'reload',
                label: 'Reload',
                glyph: AppIcons.reload,
                group: MenuGroup.quick,
                onSelected: () {},
              ),
              MenuAction(
                id: 'bookmark',
                label: 'Bookmark',
                glyph: AppIcons.bookmark,
                group: MenuGroup.quick,
                onSelected: () {},
              ),
              MenuAction(
                id: 'share',
                label: 'Share',
                glyph: AppIcons.share,
                group: MenuGroup.quick,
                onSelected: () {},
              ),
              MenuAction(
                id: 'external',
                label: 'Open in system browser',
                glyph: AppIcons.openExternal,
                group: MenuGroup.page,
                onSelected: () {},
              ),
              MenuAction(
                id: 'settings',
                label: 'Settings',
                glyph: AppIcons.settings,
                group: MenuGroup.app,
                onSelected: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: PremiumDialog(
            title: 'Clear browsing data?',
            message: 'This cannot be undone.',
            primary: DialogAction(label: 'Clear', onPressed: _noop),
            secondary: DialogAction(label: 'Cancel', onPressed: _noop),
          ),
        ),
      ],
    ),
  );
}

void _noop() {}

void main() {
  for (final GoldenVariant v in GoldenVariant.values) {
    testWidgets('browser chrome, ${v.name}', (WidgetTester tester) async {
      await pumpGolden(
        tester,
        chromeSheet(),
        theme: v == GoldenVariant.dark ? darkTheme : lightTheme,
        direction: v.direction,
        textScale: v.textScale,
      );
      await expectLater(
        find.byKey(goldenBoundary),
        matchesGoldenFile('goldens/chrome_${v.name}.png'),
      );
    });
  }
}
