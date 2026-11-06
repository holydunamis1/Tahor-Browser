import 'package:flutter/widgets.dart';

import '../../core/constants/icon_sizes.dart';
import '../../core/constants/motion.dart';

/// Press feedback by opacity, with no ripple, and a hit area of at least
/// 48 x 48. Everything tappable in the app is built on this.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.pressedOpacity = 0.5,
    this.dimWhenDisabled = true,
    this.minSize = IconSizes.minHitTarget,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Replaces the text inside [child] for screen readers.
  final String? semanticLabel;
  final double pressedOpacity;

  /// Fades the child while there is no tap action.
  final bool dimWhenDisabled;
  final double minSize;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _set(bool pressed) {
    if (_pressed != pressed && mounted) {
      setState(() => _pressed = pressed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Motion motion = Motion.of(context);
    final double opacity = !_enabled
        ? (widget.dimWhenDisabled ? 0.4 : 1)
        : (_pressed ? widget.pressedOpacity : 1);
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => _set(true) : null,
        onTapUp: _enabled ? (_) => _set(false) : null,
        onTapCancel: _enabled ? () => _set(false) : null,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.minSize,
            minHeight: widget.minSize,
          ),
          child: AnimatedOpacity(
            opacity: opacity,
            duration: motion.press,
            curve: motion.curve,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
