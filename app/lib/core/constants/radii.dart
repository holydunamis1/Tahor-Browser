import 'package:flutter/widgets.dart';

/// Corner radii: card 16, hero 20, chip 8, button 12, input 12, sheet 20
/// (top corners only), dialog 16, and a pill of half its height.
@immutable
class AppRadii {
  const AppRadii({
    this.card = 16,
    this.hero = 20,
    this.chip = 8,
    this.button = 12,
    this.input = 12,
    this.sheet = 20,
    this.dialog = 16,
  });

  final double card;
  final double hero;
  final double chip;
  final double button;
  final double input;
  final double sheet;
  final double dialog;

  static const AppRadii standard = AppRadii();

  BorderRadius get cardRadius => BorderRadius.all(Radius.circular(card));
  BorderRadius get heroRadius => BorderRadius.all(Radius.circular(hero));
  BorderRadius get chipRadius => BorderRadius.all(Radius.circular(chip));
  BorderRadius get buttonRadius => BorderRadius.all(Radius.circular(button));
  BorderRadius get inputRadius => BorderRadius.all(Radius.circular(input));
  BorderRadius get dialogRadius => BorderRadius.all(Radius.circular(dialog));

  /// Sheets round their top corners only.
  BorderRadius get sheetRadius =>
      BorderRadius.vertical(top: Radius.circular(sheet));

  /// A pill: half of [height].
  BorderRadius pill(double height) =>
      BorderRadius.all(Radius.circular(height / 2));
}
