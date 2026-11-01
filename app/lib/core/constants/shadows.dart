import 'package:flutter/widgets.dart';

/// The only shadows the interface may use. Dark mode has none.
@immutable
class AppShadows {
  const AppShadows({required this.subtle, required this.sheet});

  /// A faint lift for raised surfaces.
  final List<BoxShadow> subtle;

  /// The shadow above a bottom sheet.
  final List<BoxShadow> sheet;

  static const AppShadows light = AppShadows(
    subtle: <BoxShadow>[
      BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
    ],
    sheet: <BoxShadow>[
      BoxShadow(
        color: Color(0x1F000000),
        blurRadius: 24,
        offset: Offset(0, -4),
      ),
    ],
  );

  static const AppShadows dark = AppShadows(
    subtle: <BoxShadow>[],
    sheet: <BoxShadow>[],
  );
}
