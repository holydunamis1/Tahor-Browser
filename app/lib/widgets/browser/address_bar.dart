import 'package:flutter/widgets.dart';

import '../../core/constants/icon_sizes.dart';
import '../../core/constants/spacing.dart';
import '../../core/theme/theme_builder.dart';
import '../../core/utils/url_utils.dart';
import '../../l10n/l10n_extensions.dart';
import '../core/app_text_selection.dart';
import '../core/icon_wrapper.dart';
import '../core/premium_text_field.dart';
import '../icons/semantic_icons.dart';

/// The address bar: a 48 high pill. Unfocused it shows the page's host;
/// focused it shows the full address, selected, ready to be replaced.
/// Pressing the keyboard's Go (or Paste and go) calls [onSubmitted].
class AddressBar extends StatefulWidget {
  const AddressBar({
    super.key,
    required this.url,
    required this.onSubmitted,
    this.focusNode,
    this.trailing,
  });

  /// The address of the page showing; empty for a blank tab.
  final String url;

  /// Called with whatever was typed. The caller decides what it means.
  final ValueChanged<String> onSubmitted;

  /// Pass one to focus the bar from elsewhere (the start page's search).
  final FocusNode? focusNode;

  /// Actions at the end, such as the shield.
  final Widget? trailing;

  @override
  State<AddressBar> createState() => _AddressBarState();
}

class _AddressBarState extends State<AddressBar> {
  late final TextEditingController _controller = TextEditingController(
    text: _display(widget.url),
  );
  FocusNode? _ownedFocus;

  FocusNode get _focus =>
      widget.focusNode ??
      (_ownedFocus ??= FocusNode(debugLabel: 'address-bar'));

  static String _display(String url) => url.isEmpty ? '' : displayHostOf(url);

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(AddressBar old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownedFocus)?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
    // A page change replaces what is shown, unless the person is typing.
    if (old.url != widget.url && !_focus.hasFocus) {
      _controller.text = _display(widget.url);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _ownedFocus?.dispose();
    _controller.dispose();
    super.dispose();
  }

  // This runs before the field's own focus listener (it was added first), so
  // the full address is in place when the field selects it.
  void _onFocus() {
    _controller.text = _focus.hasFocus ? widget.url : _display(widget.url);
  }

  void _submit(String text) {
    widget.onSubmitted(text);
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = AppTheme.of(context);
    return PremiumTextField(
      controller: _controller,
      focusNode: _focus,
      hintText: l10n.addressBarHint,
      semanticLabel: l10n.addressBarLabel,
      leading: _SecurityIndicator(url: widget.url),
      trailing: widget.trailing,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.go,
      autocorrect: false,
      selectAllOnFocus: true,
      borderRadius: theme.radii.pill(IconSizes.minHitTarget),
      onSubmitted: _submit,
      contextMenuBuilder: (BuildContext context, EditableTextState state) =>
          appContextMenuBuilder(context, state, onPasteAndGo: _submit),
    );
  }
}

/// What the address bar says about the page's connection, from its scheme
/// only: a lock for https, a plain "Not secure" for http, a search icon for
/// a blank tab.
class _SecurityIndicator extends StatelessWidget {
  const _SecurityIndicator({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final String scheme = (Uri.tryParse(url)?.scheme ?? '').toLowerCase();
    if (scheme == 'http') {
      return Text(
        context.l10n.addressNotSecure,
        maxLines: 1,
        style: theme.text.caption.copyWith(
          color: theme.palette.warning,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return AppIcon(
      scheme == 'https' ? AppIcons.lock : AppIcons.search,
      role: AppIconRole.rowTrailing,
      color: theme.palette.textTertiary,
    );
  }
}

/// The gap between the bar and the content around it.
const double addressBarGap = Spacing.s;
