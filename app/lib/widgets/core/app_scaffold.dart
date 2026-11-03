import 'package:flutter/widgets.dart';

import '../../core/theme/theme_builder.dart';

/// What happens to the bottom chrome while the keyboard is open.
enum BottomChromeBehavior {
  /// The chrome leaves the layout so it is never pushed up by the keyboard.
  /// It stays mounted, so its state survives. This is the default.
  hideWithKeyboard,

  /// The chrome sits directly above the keyboard (for example a find bar).
  stayAboveKeyboard,
}

/// The frame of every screen: the background colour, the safe area on all
/// edges, a [top] and a [bottom] chrome slot, and a [body] that fills the rest.
///
/// The layout is stable under the keyboard: the body ends at the keyboard
/// edge, and bottom chrome never gets pushed up and then re-expands.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.top,
    this.bottom,
    this.backgroundColor,
    this.bottomBehavior = BottomChromeBehavior.hideWithKeyboard,
  });

  final Widget body;
  final Widget? top;
  final Widget? bottom;
  final Color? backgroundColor;
  final BottomChromeBehavior bottomBehavior;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final EdgeInsets safe = media.padding;
    final double keyboard = media.viewInsets.bottom;
    final bool keyboardUp = keyboard > 0;
    final bool showBottom =
        !keyboardUp || bottomBehavior == BottomChromeBehavior.stayAboveKeyboard;
    final Widget? bottomSlot = bottom;

    return ColoredBox(
      color: backgroundColor ?? AppTheme.of(context).palette.bgPrimary,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          safe.left,
          safe.top,
          safe.right,
          keyboardUp ? keyboard : safe.bottom,
        ),
        // The insets are consumed here so nothing below applies them twice.
        child: MediaQuery(
          data: media.copyWith(
            padding: EdgeInsets.zero,
            viewPadding: EdgeInsets.zero,
            viewInsets: EdgeInsets.zero,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ?top,
              Expanded(child: body),
              if (bottomSlot != null)
                Visibility(
                  visible: showBottom,
                  maintainState: true,
                  child: bottomSlot,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
