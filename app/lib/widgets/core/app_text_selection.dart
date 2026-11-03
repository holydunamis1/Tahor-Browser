import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/constants/icon_sizes.dart';
import '../../core/constants/spacing.dart';
import '../../core/theme/app_theme_data.dart';
import '../../core/theme/theme_builder.dart';
import '../../l10n/l10n_extensions.dart';

/// Called with the clipboard text when the person chooses Paste and go.
typedef PasteAndGoCallback = void Function(String text);

/// The selection handles: a stick the height of the text line with a ball on
/// one end, drawn in the accent colour.
///
/// `EditableText` shows no selection handles unless it is given controls.
class AppTextSelectionControls extends TextSelectionControls {
  AppTextSelectionControls();

  static const double _radius = 6;
  static const double _stickWidth = 2;
  static const double _touchWidth = 40;

  @override
  Size getHandleSize(double textLineHeight) =>
      Size(_touchWidth, textLineHeight + _radius * 2);

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    switch (type) {
      case TextSelectionHandleType.left:
      case TextSelectionHandleType.collapsed:
        // The ball is above the line; the stick ends at the line's bottom.
        return Offset(_touchWidth / 2, textLineHeight + _radius * 2);
      case TextSelectionHandleType.right:
        // The ball is below the line; the stick ends at the line's bottom.
        return Offset(_touchWidth / 2, textLineHeight);
    }
  }

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) {
    final Color color = AppTheme.of(context).palette.accent;
    return SizedBox.fromSize(
      size: getHandleSize(textLineHeight),
      child: CustomPaint(
        painter: _HandlePainter(
          ballAtTop: type != TextSelectionHandleType.right,
          lineHeight: textLineHeight,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) => const SizedBox.shrink();
}

class _HandlePainter extends CustomPainter {
  const _HandlePainter({
    required this.ballAtTop,
    required this.lineHeight,
    required this.color,
  });

  final bool ballAtTop;
  final double lineHeight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double r = AppTextSelectionControls._radius;
    const double w = AppTextSelectionControls._stickWidth;
    final double cx = size.width / 2;
    final Paint paint = Paint()..color = color;
    final double stickTop = ballAtTop ? r * 2 : 0;
    canvas.drawRect(Rect.fromLTWH(cx - w / 2, stickTop, w, lineHeight), paint);
    canvas.drawCircle(Offset(cx, ballAtTop ? r : lineHeight + r), r, paint);
  }

  @override
  bool shouldRepaint(_HandlePainter old) =>
      old.ballAtTop != ballAtTop ||
      old.lineHeight != lineHeight ||
      old.color != color;
}

class _MenuAction {
  const _MenuAction(this.label, this.onPressed);

  final String label;
  final VoidCallback onPressed;
}

/// The Cut, Copy, Paste and Select all menu, drawn with the app's tokens.
/// Pass [onPasteAndGo] to add a Paste and go action after Paste.
Widget appContextMenuBuilder(
  BuildContext context,
  EditableTextState state, {
  PasteAndGoCallback? onPasteAndGo,
}) {
  final l10n = context.l10n;
  final List<_MenuAction> actions = <_MenuAction>[];
  for (final ContextMenuButtonItem item in state.contextMenuButtonItems) {
    final VoidCallback? onPressed = item.onPressed;
    final String? label = switch (item.type) {
      ContextMenuButtonType.cut => l10n.menuCut,
      ContextMenuButtonType.copy => l10n.menuCopy,
      ContextMenuButtonType.paste => l10n.menuPaste,
      ContextMenuButtonType.selectAll => l10n.menuSelectAll,
      _ => null,
    };
    if (label == null || onPressed == null) {
      continue;
    }
    actions.add(_MenuAction(label, onPressed));
    if (item.type == ContextMenuButtonType.paste && onPasteAndGo != null) {
      actions.add(
        _MenuAction(l10n.menuPasteAndGo, () async {
          final ClipboardData? data = await Clipboard.getData(
            Clipboard.kTextPlain,
          );
          state.hideToolbar();
          final String? text = data?.text;
          if (text != null && text.isNotEmpty) {
            onPasteAndGo(text);
          }
        }),
      );
    }
  }
  if (actions.isEmpty) {
    return const SizedBox.shrink();
  }
  final TextSelectionToolbarAnchors anchors = state.contextMenuAnchors;
  return CustomSingleChildLayout(
    delegate: TextSelectionToolbarLayoutDelegate(
      anchorAbove: anchors.primaryAnchor - const Offset(0, Spacing.s),
      anchorBelow:
          (anchors.secondaryAnchor ?? anchors.primaryAnchor) +
          const Offset(0, Spacing.s),
    ),
    child: _Toolbar(actions: actions, theme: AppTheme.of(context)),
  );
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.actions, required this.theme});

  final List<_MenuAction> actions;
  final AppThemeData theme;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];
    for (int i = 0; i < actions.length; i++) {
      if (i > 0) {
        children.add(
          SizedBox(
            width: 1,
            height: IconSizes.chipContainer - Spacing.s,
            child: ColoredBox(color: theme.palette.borderSubtle),
          ),
        );
      }
      children.add(_MenuButton(action: actions[i], theme: theme));
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.palette.bgSecondary,
        borderRadius: theme.radii.inputRadius,
        border: Border.all(color: theme.palette.borderSubtle),
        boxShadow: theme.shadows.subtle,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _MenuButton extends StatefulWidget {
  const _MenuButton({required this.action, required this.theme});

  final _MenuAction action;
  final AppThemeData theme;

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          setState(() => _pressed = false);
          widget.action.onPressed();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: IconSizes.minHitTarget,
            minWidth: IconSizes.minHitTarget,
          ),
          child: Opacity(
            opacity: _pressed ? 0.5 : 1,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: Spacing.m,
              ),
              child: Center(
                widthFactor: 1,
                child: Text(
                  widget.action.label,
                  style: widget.theme.text.callout.copyWith(
                    color: widget.theme.palette.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
