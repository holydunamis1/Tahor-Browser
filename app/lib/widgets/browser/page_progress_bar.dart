import 'package:flutter/widgets.dart';

import '../../core/constants/motion.dart';
import '../../core/theme/theme_builder.dart';

/// A 2 px accent bar that fills as a page loads. When nothing is loading it
/// takes no space at all.
class PageProgressBar extends StatelessWidget {
  const PageProgressBar({
    super.key,
    required this.progress,
    required this.isLoading,
  });

  /// From 0 to 1.
  final double progress;
  final bool isLoading;

  static const double height = 2;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return const SizedBox.shrink();
    }
    final Motion motion = Motion.of(context);
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: AnimatedFractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: progress.clamp(0.02, 1.0).toDouble(),
          duration: motion.press,
          curve: motion.curve,
          child: ColoredBox(color: AppTheme.of(context).palette.accent),
        ),
      ),
    );
  }
}
