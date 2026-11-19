import 'package:flutter/widgets.dart';

import '../../core/constants/spacing.dart';
import '../../core/providers/feedback_provider.dart';
import '../../core/theme/theme_builder.dart';
import '../icons/semantic_icons.dart';
import 'icon_wrapper.dart';

/// One feedback message: an icon and a line of text on a raised pill.
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({super.key, required this.message});

  final FeedbackMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final Color tint = message.isError
        ? theme.palette.error
        : theme.palette.success;
    return Semantics(
      liveRegion: true,
      label: message.text,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.palette.bgSecondary,
            borderRadius: theme.radii.buttonRadius,
            border: Border.all(color: theme.palette.borderSubtle),
            boxShadow: theme.shadows.subtle,
          ),
          child: Padding(
            padding: AppInsets.symmetric(
              horizontal: Spacing.m,
              vertical: Spacing.s,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppIcon(
                  message.isError ? AppIcons.warning : AppIcons.checkCircle,
                  role: AppIconRole.rowLeading,
                  color: tint,
                ),
                const SizedBox(width: Spacing.s),
                Flexible(
                  child: Text(
                    message.text,
                    style: theme.text.callout.copyWith(
                      color: theme.palette.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws the message of [provider], if any, at the top of its child, under the
/// status bar. Tapping it dismisses it.
class FeedbackLayer extends StatelessWidget {
  const FeedbackLayer({super.key, required this.provider, required this.child});

  final FeedbackProvider provider;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: Directionality.of(context),
      children: <Widget>[
        child,
        ValueListenableBuilder<FeedbackMessage?>(
          valueListenable: provider,
          builder: (BuildContext context, FeedbackMessage? message, Widget? _) {
            if (message == null) {
              return const SizedBox.shrink();
            }
            return Positioned(
              top: MediaQuery.paddingOf(context).top + Spacing.s,
              left: Spacing.m,
              right: Spacing.m,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: provider.dismiss,
                child: Center(child: FeedbackBanner(message: message)),
              ),
            );
          },
        ),
      ],
    );
  }
}
