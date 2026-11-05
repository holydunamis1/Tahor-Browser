import 'package:flutter/widgets.dart';

import '../../core/constants/spacing.dart';
import '../../core/theme/theme_builder.dart';
import '../../l10n/l10n_extensions.dart';
import 'app_modal_route.dart';
import 'primary_button.dart';

/// One button of a dialog.
@immutable
class DialogAction {
  const DialogAction({
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onPressed;

  /// Draws a secondary action in the error colour.
  final bool destructive;
}

/// A dialog: a title, an optional message or content, a filled primary
/// action and an optional text secondary action.
class PremiumDialog extends StatelessWidget {
  const PremiumDialog({
    super.key,
    required this.title,
    required this.primary,
    this.message,
    this.content,
    this.secondary,
  });

  final String title;
  final String? message;

  /// Extra content between the message and the buttons.
  final Widget? content;
  final DialogAction primary;
  final DialogAction? secondary;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.palette.bgPrimary,
        borderRadius: theme.radii.dialogRadius,
        border: Border.all(color: theme.palette.borderSubtle),
        boxShadow: theme.shadows.subtle,
      ),
      child: Padding(
        padding: AppInsets.all(Spacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.text.title2.copyWith(
                  color: theme.palette.textPrimary,
                ),
              ),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: Spacing.s),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.text.body.copyWith(
                  color: theme.palette.textSecondary,
                ),
              ),
            ],
            if (content != null) ...<Widget>[
              const SizedBox(height: Spacing.m),
              content!,
            ],
            const SizedBox(height: Spacing.l),
            PrimaryButton(label: primary.label, onPressed: primary.onPressed),
            if (secondary != null) ...<Widget>[
              const SizedBox(height: Spacing.xs),
              TextActionButton(
                label: secondary!.label,
                onPressed: secondary!.onPressed,
                destructive: secondary!.destructive,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows [builder]'s dialog in the centre of the screen.
Future<T?> showPremiumDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
}) {
  return showAppDialog<T>(
    context: context,
    dismissLabel: context.l10n.dismiss,
    isDismissible: isDismissible,
    builder: builder,
  );
}

/// Asks a yes or no question. True means the primary action was chosen; a
/// dismissed dialog counts as no.
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String confirmLabel,
  required String cancelLabel,
  String? message,
  bool destructive = false,
}) async {
  final bool? result = await showPremiumDialog<bool>(
    context: context,
    builder: (BuildContext context) => PremiumDialog(
      title: title,
      message: message,
      primary: DialogAction(
        label: confirmLabel,
        onPressed: () => Navigator.of(context).pop(true),
      ),
      secondary: DialogAction(
        label: cancelLabel,
        destructive: destructive,
        onPressed: () => Navigator.of(context).pop(false),
      ),
    ),
  );
  return result ?? false;
}
