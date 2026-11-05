import 'package:flutter/widgets.dart';

import '../../core/constants/spacing.dart';
import '../../core/theme/theme_builder.dart';
import '../../l10n/l10n_extensions.dart';
import 'app_modal_route.dart';

/// The surface of a bottom sheet: a drag handle, an optional title, rounded
/// top corners, and padding for the safe area and the keyboard.
class PremiumBottomSheet extends StatelessWidget {
  const PremiumBottomSheet({super.key, required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final MediaQueryData media = MediaQuery.of(context);
    final double bottom = media.viewInsets.bottom > 0
        ? media.viewInsets.bottom
        : media.padding.bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.palette.bgPrimary,
        borderRadius: theme.radii.sheetRadius,
        border: Border.all(color: theme.palette.borderSubtle),
        boxShadow: theme.shadows.sheet,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Padding(
                  padding: AppInsets.symmetric(vertical: Spacing.s),
                  child: SizedBox(
                    width: Spacing.xl + Spacing.xs,
                    height: Spacing.xs,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.palette.textTertiary.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: theme.radii.pill(Spacing.xs),
                      ),
                    ),
                  ),
                ),
              ),
              if (title != null)
                Padding(
                  padding: AppInsets.only(
                    start: Spacing.m,
                    end: Spacing.m,
                    bottom: Spacing.s,
                  ),
                  child: Semantics(
                    header: true,
                    child: Text(
                      title!,
                      textAlign: TextAlign.center,
                      style: theme.text.title2.copyWith(
                        color: theme.palette.textPrimary,
                      ),
                    ),
                  ),
                ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows [child] in a [PremiumBottomSheet] above everything else.
Future<T?> showPremiumBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  bool isDismissible = true,
}) {
  return showAppSheet<T>(
    context: context,
    dismissLabel: context.l10n.dismiss,
    isDismissible: isDismissible,
    builder: (BuildContext context) =>
        PremiumBottomSheet(title: title, child: builder(context)),
  );
}
