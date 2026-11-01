/// Icon weights. Phosphor ships fixed weights.
enum AppIconWeight { regular, bold }

/// Icon sizes in logical pixels and the touch-target minimum.
abstract final class IconSizes {
  static const double nav = 24;
  static const double rowLeading = 22;
  static const double rowTrailing = 20;
  static const double hero = 32;

  /// The square container around an icon in browser chrome.
  static const double chipContainer = 40;

  /// Every interactive element is at least this large in both directions.
  static const double minHitTarget = 48;

  /// Icons at this size or smaller use the regular weight.
  static const double regularWeightMax = 20;

  /// Bold for chrome icons; regular at 20 px and below.
  static AppIconWeight weightFor(double size) =>
      size <= regularWeightMax ? AppIconWeight.regular : AppIconWeight.bold;
}
