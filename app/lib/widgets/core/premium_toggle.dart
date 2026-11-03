import 'package:flutter/widgets.dart';

import '../../core/constants/icon_sizes.dart';
import '../../core/constants/motion.dart';
import '../../core/theme/theme_builder.dart';

/// An on/off switch drawn with a painter: a 51 x 31 track and a white thumb,
/// inside a hit area that is at least 48 high.
class PremiumToggle extends StatelessWidget {
  const PremiumToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;

  /// Null disables the switch.
  final ValueChanged<bool>? onChanged;

  /// What a screen reader announces; usually the row's title.
  final String? semanticLabel;

  static const double trackWidth = 51;
  static const double trackHeight = 31;
  static const Color thumbColor = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final Motion motion = Motion.of(context);
    final bool enabled = onChanged != null;
    final Color off = Color.alphaBlend(
      theme.palette.textTertiary.withValues(alpha: 0.35),
      theme.palette.bgPrimary,
    );

    void toggle() => onChanged!(!value);

    return Semantics(
      label: semanticLabel,
      toggled: value,
      enabled: enabled,
      onTap: enabled ? toggle : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? toggle : null,
        child: SizedBox(
          width: trackWidth,
          height: IconSizes.minHitTarget,
          child: Center(
            child: Opacity(
              opacity: enabled ? 1 : 0.4,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: value ? 1 : 0),
                duration: motion.press,
                curve: motion.curve,
                builder: (BuildContext context, double progress, Widget? _) {
                  return CustomPaint(
                    size: const Size(trackWidth, trackHeight),
                    painter: _TogglePainter(
                      progress: progress,
                      offColor: off,
                      onColor: theme.palette.accent,
                      withShadow: !theme.isDark,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TogglePainter extends CustomPainter {
  const _TogglePainter({
    required this.progress,
    required this.offColor,
    required this.onColor,
    required this.withShadow,
  });

  final double progress;
  final Color offColor;
  final Color onColor;
  final bool withShadow;

  static const double _inset = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint track = Paint()
      ..color = Color.lerp(offColor, onColor, progress)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(size.height / 2),
      ),
      track,
    );
    final double radius = size.height / 2 - _inset;
    final double left = _inset + radius;
    final double right = size.width - _inset - radius;
    final Offset center = Offset(
      left + (right - left) * progress,
      size.height / 2,
    );
    if (withShadow) {
      canvas.drawCircle(
        center.translate(0, 1.5),
        radius,
        Paint()
          ..color = const Color(0x33000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = PremiumToggle.thumbColor,
    );
  }

  @override
  bool shouldRepaint(_TogglePainter old) =>
      old.progress != progress ||
      old.offColor != offColor ||
      old.onColor != onColor ||
      old.withShadow != withShadow;
}
