import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/error/error_taxonomy.dart';
import 'package:tahorbrowser/core/theme/dark_theme.dart';
import 'package:tahorbrowser/core/theme/light_theme.dart';
import 'package:tahorbrowser/widgets/core/empty_state.dart';
import 'package:tahorbrowser/widgets/core/error_state.dart';
import 'package:tahorbrowser/widgets/core/icon_chip.dart';
import 'package:tahorbrowser/widgets/core/premium_card.dart';
import 'package:tahorbrowser/widgets/core/premium_chip.dart';
import 'package:tahorbrowser/widgets/core/premium_row.dart';
import 'package:tahorbrowser/widgets/core/premium_toggle.dart';
import 'package:tahorbrowser/widgets/core/primary_button.dart';
import 'package:tahorbrowser/widgets/core/section_header.dart';
import 'package:tahorbrowser/widgets/icons/semantic_icons.dart';

import 'support/golden_helpers.dart';

/// Every component once, so one picture shows the whole kit.
Widget componentSheet() {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SectionHeader('Appearance'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: <Widget>[
              PremiumCard(
                leading: AppIcons.settings,
                label: 'Search engine',
                value: 'DuckDuckGo',
                onTap: () {},
              ),
              const SizedBox(height: 8),
              PremiumCard(
                label: 'Save history',
                value: 'Off',
                trailing: PremiumToggle(value: true, onChanged: (bool _) {}),
              ),
            ],
          ),
        ),
        const SectionHeader('Library'),
        PremiumRow(
          leading: AppIcons.bookmark,
          title: 'Bookmarks',
          subtitle: '12 saved',
          onTap: () {},
        ),
        PremiumRow(
          leading: AppIcons.download,
          title: 'Downloads',
          onTap: () {},
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            children: <Widget>[
              const PremiumChip(label: 'Last hour', selected: true),
              const PremiumChip(label: 'Last 24 hours'),
              PremiumChip(
                label: 'All time',
                glyph: AppIcons.check,
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: <Widget>[
              IconChip(
                glyph: AppIcons.back,
                semanticLabel: 'Back',
                onTap: () {},
              ),
              IconChip(glyph: AppIcons.forward, semanticLabel: 'Forward'),
              IconChip(
                glyph: AppIcons.shield,
                semanticLabel: 'Shield',
                selected: true,
                filled: true,
                onTap: () {},
              ),
              IconChip(
                glyph: AppIcons.tabs,
                semanticLabel: 'Tabs',
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: <Widget>[
              PrimaryButton(label: 'Continue', onPressed: () {}),
              const SizedBox(height: 8),
              const PrimaryButton(label: 'Disabled', onPressed: null),
              TextActionButton(label: 'Not now', onPressed: () {}),
            ],
          ),
        ),
        const EmptyState(
          glyph: AppIcons.history,
          title: 'No history yet',
          subtitle: 'History is off by default.',
        ),
        SizedBox(
          height: 560,
          child: ErrorState(
            error: const NetworkError.offline(),
            onRetry: () {},
          ),
        ),
      ],
    ),
  );
}

void main() {
  for (final GoldenVariant v in GoldenVariant.values) {
    testWidgets('component sheet, ${v.name}', (WidgetTester tester) async {
      await pumpGolden(
        tester,
        componentSheet(),
        theme: v == GoldenVariant.dark ? darkTheme : lightTheme,
        direction: v.direction,
        textScale: v.textScale,
      );
      await expectLater(
        find.byKey(goldenBoundary),
        matchesGoldenFile('goldens/components_${v.name}.png'),
      );
    });
  }
}
