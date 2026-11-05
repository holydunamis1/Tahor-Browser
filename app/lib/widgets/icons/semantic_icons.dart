import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// One icon in the weights the interface uses. This file is the only place
/// that names glyphs from the icon package; everything else asks for an
/// [AppIcons] entry.
@immutable
class AppIconGlyph {
  const AppIconGlyph({
    required this.regular,
    required this.bold,
    this.fill,
    this.mirrorsInRtl = false,
  });

  /// Used at 20 px and below.
  final IconData regular;

  /// Used for chrome icons above 20 px.
  final IconData bold;

  /// The filled version, for states such as a saved bookmark.
  final IconData? fill;

  /// True for icons that point somewhere (arrows, chevrons) and must flip in
  /// right-to-left layouts.
  final bool mirrorsInRtl;
}

/// Semantic names for the glyphs the app draws.
abstract final class AppIcons {
  static const AppIconGlyph back = AppIconGlyph(
    regular: PhosphorIconsRegular.arrowLeft,
    bold: PhosphorIconsBold.arrowLeft,
    mirrorsInRtl: true,
  );
  static const AppIconGlyph forward = AppIconGlyph(
    regular: PhosphorIconsRegular.arrowRight,
    bold: PhosphorIconsBold.arrowRight,
    mirrorsInRtl: true,
  );
  static const AppIconGlyph chevron = AppIconGlyph(
    regular: PhosphorIconsRegular.caretRight,
    bold: PhosphorIconsBold.caretRight,
    mirrorsInRtl: true,
  );
  static const AppIconGlyph chevronDown = AppIconGlyph(
    regular: PhosphorIconsRegular.caretDown,
    bold: PhosphorIconsBold.caretDown,
  );
  static const AppIconGlyph reload = AppIconGlyph(
    regular: PhosphorIconsRegular.arrowClockwise,
    bold: PhosphorIconsBold.arrowClockwise,
  );
  static const AppIconGlyph close = AppIconGlyph(
    regular: PhosphorIconsRegular.x,
    bold: PhosphorIconsBold.x,
  );
  static const AppIconGlyph closeCircle = AppIconGlyph(
    regular: PhosphorIconsRegular.xCircle,
    bold: PhosphorIconsBold.xCircle,
    fill: PhosphorIconsFill.xCircle,
  );
  static const AppIconGlyph search = AppIconGlyph(
    regular: PhosphorIconsRegular.magnifyingGlass,
    bold: PhosphorIconsBold.magnifyingGlass,
  );
  static const AppIconGlyph shield = AppIconGlyph(
    regular: PhosphorIconsRegular.shield,
    bold: PhosphorIconsBold.shield,
    fill: PhosphorIconsFill.shield,
  );
  static const AppIconGlyph shieldCheck = AppIconGlyph(
    regular: PhosphorIconsRegular.shieldCheck,
    bold: PhosphorIconsBold.shieldCheck,
    fill: PhosphorIconsFill.shieldCheck,
  );
  static const AppIconGlyph shieldOff = AppIconGlyph(
    regular: PhosphorIconsRegular.shieldSlash,
    bold: PhosphorIconsBold.shieldSlash,
    fill: PhosphorIconsFill.shieldSlash,
  );
  static const AppIconGlyph share = AppIconGlyph(
    regular: PhosphorIconsRegular.export,
    bold: PhosphorIconsBold.export,
  );
  static const AppIconGlyph settings = AppIconGlyph(
    regular: PhosphorIconsRegular.gearSix,
    bold: PhosphorIconsBold.gearSix,
  );
  static const AppIconGlyph menu = AppIconGlyph(
    regular: PhosphorIconsRegular.dotsThree,
    bold: PhosphorIconsBold.dotsThree,
  );
  static const AppIconGlyph add = AppIconGlyph(
    regular: PhosphorIconsRegular.plus,
    bold: PhosphorIconsBold.plus,
  );
  static const AppIconGlyph remove = AppIconGlyph(
    regular: PhosphorIconsRegular.minus,
    bold: PhosphorIconsBold.minus,
  );
  static const AppIconGlyph check = AppIconGlyph(
    regular: PhosphorIconsRegular.check,
    bold: PhosphorIconsBold.check,
  );
  static const AppIconGlyph checkCircle = AppIconGlyph(
    regular: PhosphorIconsRegular.checkCircle,
    bold: PhosphorIconsBold.checkCircle,
    fill: PhosphorIconsFill.checkCircle,
  );
  static const AppIconGlyph warning = AppIconGlyph(
    regular: PhosphorIconsRegular.warning,
    bold: PhosphorIconsBold.warning,
    fill: PhosphorIconsFill.warning,
  );
  static const AppIconGlyph info = AppIconGlyph(
    regular: PhosphorIconsRegular.info,
    bold: PhosphorIconsBold.info,
  );
  static const AppIconGlyph lock = AppIconGlyph(
    regular: PhosphorIconsRegular.lock,
    bold: PhosphorIconsBold.lock,
  );
  static const AppIconGlyph tabs = AppIconGlyph(
    regular: PhosphorIconsRegular.squaresFour,
    bold: PhosphorIconsBold.squaresFour,
  );
  static const AppIconGlyph bookmark = AppIconGlyph(
    regular: PhosphorIconsRegular.bookmarkSimple,
    bold: PhosphorIconsBold.bookmarkSimple,
    fill: PhosphorIconsFill.bookmarkSimple,
  );
  static const AppIconGlyph history = AppIconGlyph(
    regular: PhosphorIconsRegular.clockCounterClockwise,
    bold: PhosphorIconsBold.clockCounterClockwise,
  );
  static const AppIconGlyph download = AppIconGlyph(
    regular: PhosphorIconsRegular.downloadSimple,
    bold: PhosphorIconsBold.downloadSimple,
  );
  static const AppIconGlyph delete = AppIconGlyph(
    regular: PhosphorIconsRegular.trash,
    bold: PhosphorIconsBold.trash,
  );
  static const AppIconGlyph copy = AppIconGlyph(
    regular: PhosphorIconsRegular.copy,
    bold: PhosphorIconsBold.copy,
  );
  static const AppIconGlyph globe = AppIconGlyph(
    regular: PhosphorIconsRegular.globe,
    bold: PhosphorIconsBold.globe,
  );
  static const AppIconGlyph home = AppIconGlyph(
    regular: PhosphorIconsRegular.house,
    bold: PhosphorIconsBold.house,
  );
  static const AppIconGlyph qrCode = AppIconGlyph(
    regular: PhosphorIconsRegular.qrCode,
    bold: PhosphorIconsBold.qrCode,
  );
  static const AppIconGlyph translate = AppIconGlyph(
    regular: PhosphorIconsRegular.translate,
    bold: PhosphorIconsBold.translate,
  );
  static const AppIconGlyph offline = AppIconGlyph(
    regular: PhosphorIconsRegular.wifiSlash,
    bold: PhosphorIconsBold.wifiSlash,
  );
  static const AppIconGlyph privateTab = AppIconGlyph(
    regular: PhosphorIconsRegular.detective,
    bold: PhosphorIconsBold.detective,
    fill: PhosphorIconsFill.detective,
  );
  static const AppIconGlyph print = AppIconGlyph(
    regular: PhosphorIconsRegular.printer,
    bold: PhosphorIconsBold.printer,
  );
  static const AppIconGlyph textSize = AppIconGlyph(
    regular: PhosphorIconsRegular.textAa,
    bold: PhosphorIconsBold.textAa,
  );
  static const AppIconGlyph fingerprint = AppIconGlyph(
    regular: PhosphorIconsRegular.fingerprint,
    bold: PhosphorIconsBold.fingerprint,
  );
  static const AppIconGlyph desktop = AppIconGlyph(
    regular: PhosphorIconsRegular.desktop,
    bold: PhosphorIconsBold.desktop,
  );
  static const AppIconGlyph mobile = AppIconGlyph(
    regular: PhosphorIconsRegular.deviceMobile,
    bold: PhosphorIconsBold.deviceMobile,
  );
  static const AppIconGlyph link = AppIconGlyph(
    regular: PhosphorIconsRegular.link,
    bold: PhosphorIconsBold.link,
  );
  static const AppIconGlyph eye = AppIconGlyph(
    regular: PhosphorIconsRegular.eye,
    bold: PhosphorIconsBold.eye,
  );
  static const AppIconGlyph eyeOff = AppIconGlyph(
    regular: PhosphorIconsRegular.eyeSlash,
    bold: PhosphorIconsBold.eyeSlash,
  );
  static const AppIconGlyph moon = AppIconGlyph(
    regular: PhosphorIconsRegular.moon,
    bold: PhosphorIconsBold.moon,
  );
  static const AppIconGlyph sun = AppIconGlyph(
    regular: PhosphorIconsRegular.sun,
    bold: PhosphorIconsBold.sun,
  );
  static const AppIconGlyph folder = AppIconGlyph(
    regular: PhosphorIconsRegular.folder,
    bold: PhosphorIconsBold.folder,
  );
  static const AppIconGlyph edit = AppIconGlyph(
    regular: PhosphorIconsRegular.pencilSimple,
    bold: PhosphorIconsBold.pencilSimple,
  );
  static const AppIconGlyph openExternal = AppIconGlyph(
    regular: PhosphorIconsRegular.arrowSquareOut,
    bold: PhosphorIconsBold.arrowSquareOut,
  );
  static const AppIconGlyph reader = AppIconGlyph(
    regular: PhosphorIconsRegular.bookOpenText,
    bold: PhosphorIconsBold.bookOpenText,
  );
  static const AppIconGlyph star = AppIconGlyph(
    regular: PhosphorIconsRegular.star,
    bold: PhosphorIconsBold.star,
    fill: PhosphorIconsFill.star,
  );
}
