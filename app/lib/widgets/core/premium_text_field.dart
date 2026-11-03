import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/constants/icon_sizes.dart';
import '../../core/constants/spacing.dart';
import '../../core/theme/app_theme_data.dart';
import '../../core/theme/theme_builder.dart';
import '../../l10n/l10n_extensions.dart';
import 'app_text_selection.dart';

/// A single-line text field built on [EditableText]: a 48 high filled
/// surface whose border turns to the focus colour, an optional leading and
/// trailing widget, a clear button while focused, and the app's own
/// selection handles and menu.
class PremiumTextField extends StatefulWidget {
  const PremiumTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText,
    this.semanticLabel,
    this.leading,
    this.trailing,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.onChanged,
    this.obscureText = false,
    this.autofocus = false,
    this.enabled = true,
    this.showClearButton = true,
    this.selectAllOnFocus = false,
    this.contextMenuBuilder,
    this.style,
  });

  final TextEditingController controller;

  /// Pass one to control focus from outside; otherwise the field owns one.
  final FocusNode? focusNode;
  final String? hintText;

  /// What a screen reader announces; defaults to [hintText].
  final String? semanticLabel;
  final Widget? leading;
  final Widget? trailing;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final bool autofocus;
  final bool enabled;
  final bool showClearButton;

  /// Selects the whole text when the field gains focus (the address bar).
  final bool selectAllOnFocus;

  /// Defaults to the Cut, Copy, Paste and Select all menu.
  final EditableTextContextMenuBuilder? contextMenuBuilder;
  final TextStyle? style;

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  final GlobalKey<EditableTextState> _editableKey =
      GlobalKey<EditableTextState>();
  final AppTextSelectionControls _controls = AppTextSelectionControls();
  FocusNode? _ownedFocus;
  late final _FieldGestures _gestures = _FieldGestures(this);
  bool _hadFocus = false;

  FocusNode get _focus =>
      widget.focusNode ?? (_ownedFocus ??= FocusNode(debugLabel: 'field'));

  @override
  GlobalKey<EditableTextState> get editableTextKey => _editableKey;

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => widget.enabled && !widget.obscureText;

  @override
  void initState() {
    super.initState();
    _hadFocus = _focus.hasFocus;
    _focus.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(PremiumTextField old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownedFocus)?.removeListener(_onFocusChanged);
      _focus.addListener(_onFocusChanged);
    }
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    _ownedFocus?.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    final bool focused = _focus.hasFocus;
    if (focused && !_hadFocus && widget.selectAllOnFocus) {
      widget.controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.controller.text.length,
      );
    }
    _hadFocus = focused;
    setState(() {});
  }

  void _onTextChanged() => setState(() {});

  void _requestKeyboard() => _editableKey.currentState?.requestKeyboard();

  void _clear() {
    widget.controller.clear();
    widget.onChanged?.call('');
    _requestKeyboard();
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final bool focused = _focus.hasFocus;
    final bool empty = widget.controller.text.isEmpty;
    final TextStyle base = (widget.style ?? theme.text.body).copyWith(
      color: theme.palette.textPrimary,
    );
    final String? hint = widget.hintText;

    final Widget editable = EditableText(
      key: _editableKey,
      controller: widget.controller,
      focusNode: _focus,
      style: base,
      cursorColor: theme.palette.accent,
      backgroundCursorColor: theme.palette.bgTertiary,
      selectionColor: theme.palette.accent.withValues(alpha: 0.28),
      selectionControls: selectionEnabled ? _controls : null,
      contextMenuBuilder:
          widget.contextMenuBuilder ??
          (BuildContext context, EditableTextState state) =>
              appContextMenuBuilder(context, state),
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      obscureText: widget.obscureText,
      autocorrect: !widget.obscureText,
      enableSuggestions: !widget.obscureText,
      autofocus: widget.autofocus,
      readOnly: !widget.enabled,
      maxLines: 1,
      cursorWidth: 2,
      cursorRadius: const Radius.circular(1),
      rendererIgnoresPointer: true,
      enableInteractiveSelection: selectionEnabled,
    );

    final bool showClear =
        widget.showClearButton && widget.enabled && focused && !empty;

    return Semantics(
      container: true,
      label: widget.semanticLabel ?? hint,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: IconSizes.minHitTarget),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.palette.bgSecondary,
            borderRadius: theme.radii.inputRadius,
            border: Border.all(
              color: focused
                  ? theme.palette.borderFocus
                  : theme.palette.borderSubtle,
              width: focused ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: Spacing.m,
            ),
            child: Row(
              children: <Widget>[
                if (widget.leading != null) ...<Widget>[
                  widget.leading!,
                  const SizedBox(width: Spacing.s),
                ],
                Expanded(
                  child: Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: <Widget>[
                      if (hint != null && empty)
                        IgnorePointer(
                          child: Text(
                            hint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: base.copyWith(
                              color: theme.palette.textTertiary,
                            ),
                          ),
                        ),
                      _gestures.buildGestureDetector(
                        behavior: HitTestBehavior.translucent,
                        child: editable,
                      ),
                    ],
                  ),
                ),
                if (showClear) ...<Widget>[
                  const SizedBox(width: Spacing.s),
                  _ClearButton(
                    label: context.l10n.fieldClear,
                    color: theme.palette.textTertiary,
                    onTap: _clear,
                  ),
                ],
                if (widget.trailing != null) ...<Widget>[
                  const SizedBox(width: Spacing.s),
                  widget.trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldGestures extends TextSelectionGestureDetectorBuilder {
  _FieldGestures(this._state) : super(delegate: _state);

  final _PremiumTextFieldState _state;

  @override
  void onSingleTapUp(TapDragUpDetails details) {
    super.onSingleTapUp(details);
    _state._requestKeyboard();
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: IconSizes.minHitTarget - Spacing.m,
          height: IconSizes.minHitTarget,
          child: Center(
            child: CustomPaint(
              size: const Size.square(18),
              painter: _ClearPainter(color),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClearPainter extends CustomPainter {
  const _ClearPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    canvas.drawCircle(c, size.width / 2, Paint()..color = color);
    final Paint cross = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    const double d = 3.2;
    canvas.drawLine(c + const Offset(-d, -d), c + const Offset(d, d), cross);
    canvas.drawLine(c + const Offset(-d, d), c + const Offset(d, -d), cross);
  }

  @override
  bool shouldRepaint(_ClearPainter old) => old.color != color;
}
