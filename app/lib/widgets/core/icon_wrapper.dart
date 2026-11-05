import 'package:flutter/widgets.dart';

import '../../core/constants/icon_sizes.dart';
import '../../core/theme/theme_builder.dart';
import '../icons/semantic_icons.dart';

/// Where an icon sits, which fixes its size.
enum AppIconRole { nav, rowLeading, rowTrailing, hero }

/// The one icon widget. The size comes from the role (or [size]), the weight
/// from the size (bold above 20 px, regular at 20 and below), and the colour
/// defaults to the primary text colour. Icons that point somewhere flip in
/// right-to-left layouts.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.glyph, {
    super.key,
    this.role = AppIconRole.nav,
    this.size,
    this.color,
    this.filled = false,
    this.semanticLabel,
  });

  final AppIconGlyph glyph;
  final AppIconRole role;

  /// Overrides the role's size.
  final double? size;
  final Color? color;

  /// Uses the filled version when the glyph has one.
  final bool filled;

  /// Announced by screen readers. Icons without a label are decorative.
  final String? semanticLabel;

  /// The size of an icon in [role].
  static double sizeOf(AppIconRole role) => switch (role) {
    AppIconRole.nav => IconSizes.nav,
    AppIconRole.rowLeading => IconSizes.rowLeading,
    AppIconRole.rowTrailing => IconSizes.rowTrailing,
    AppIconRole.hero => IconSizes.hero,
  };

  /// The glyph data drawn at [px], for tests and callers that need it.
  IconData dataFor(double px) {
    final IconData? fill = glyph.fill;
    if (filled && fill != null) {
      return fill;
    }
    return IconSizes.weightFor(px) == AppIconWeight.bold
        ? glyph.bold
        : glyph.regular;
  }

  @override
  Widget build(BuildContext context) {
    final double px = size ?? sizeOf(role);
    Widget icon = Icon(
      dataFor(px),
      size: px,
      color: color ?? AppTheme.of(context).palette.textPrimary,
      semanticLabel: semanticLabel,
    );
    if (glyph.mirrorsInRtl && Directionality.of(context) == TextDirection.rtl) {
      icon = Transform.flip(flipX: true, child: icon);
    }
    return icon;
  }
}
