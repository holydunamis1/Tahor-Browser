import 'package:flutter/widgets.dart';

import '../../core/constants/motion.dart';
import '../../core/theme/theme_builder.dart';

/// What a modal route presents.
enum AppModalKind {
  /// Slides up from the bottom and can be dragged down to dismiss.
  sheet,

  /// Fades in at the centre.
  dialog,
}

/// The route behind sheets and dialogs. The surface itself (colour, corners,
/// padding) is drawn by the content; this route supplies the scrim, the
/// motion and the drag to dismiss.
class AppModalRoute<T> extends PopupRoute<T> {
  AppModalRoute({
    required this.builder,
    required this.kind,
    required this.scrimColor,
    this.dismissLabel,
    this.isDismissible = true,
    this.enableDrag = true,
    super.settings,
  });

  final WidgetBuilder builder;
  final AppModalKind kind;
  final Color scrimColor;
  final String? dismissLabel;
  final bool isDismissible;

  /// Sheets only: whether a downward drag dismisses.
  final bool enableDrag;

  /// The widest a sheet or dialog grows on large screens.
  static const double maxSheetWidth = 560;
  static const double maxDialogWidth = 420;

  /// The route's own animation, so a drag can drive it.
  AnimationController? get dragController => controller;

  Motion get _motion {
    final BuildContext? context = navigator?.context;
    return context == null ? Motion.standard : Motion.of(context);
  }

  @override
  Duration get transitionDuration =>
      kind == AppModalKind.sheet ? _motion.sheet : _motion.theme;

  @override
  Duration get reverseTransitionDuration => transitionDuration;

  @override
  Color? get barrierColor => scrimColor;

  @override
  bool get barrierDismissible => isDismissible;

  @override
  String? get barrierLabel => dismissLabel;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final Widget content = Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: builder(context),
    );
    if (kind == AppModalKind.dialog) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxDialogWidth),
            child: content,
          ),
        ),
      );
    }
    final Animation<Offset> slide = animation.drive(
      Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).chain(CurveTween(curve: Motion.of(context).curve)),
    );
    return Align(
      alignment: AlignmentDirectional.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxSheetWidth),
        child: SlideTransition(
          position: slide,
          child: enableDrag && isDismissible
              ? _SheetDragHandler<T>(route: this, child: content)
              : content,
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (kind == AppModalKind.sheet) {
      return child;
    }
    return FadeTransition(
      opacity: animation.drive(CurveTween(curve: Motion.of(context).curve)),
      child: child,
    );
  }
}

/// Moves the route's own animation while a finger drags the sheet, so the
/// sheet follows the finger one to one.
class _SheetDragHandler<T> extends StatefulWidget {
  const _SheetDragHandler({required this.route, required this.child});

  final AppModalRoute<T> route;
  final Widget child;

  @override
  State<_SheetDragHandler<T>> createState() => _SheetDragHandlerState<T>();
}

class _SheetDragHandlerState<T> extends State<_SheetDragHandler<T>> {
  bool _tracking = false;

  /// A downward fling faster than this closes the sheet, in px per second.
  static const double flingVelocity = 700;

  void _start(DragStartDetails details) {
    final NavigatorState? navigator = widget.route.navigator;
    if (navigator == null ||
        widget.route.dragController == null ||
        navigator.userGestureInProgress) {
      return;
    }
    _tracking = true;
    navigator.didStartUserGesture();
  }

  void _update(DragUpdateDetails details) {
    if (!_tracking) {
      return;
    }
    final double height = context.size?.height ?? 1;
    widget.route.dragController!.value -= (details.primaryDelta ?? 0) / height;
  }

  void _end(DragEndDetails details) {
    if (_tracking) {
      _finish((details.primaryVelocity ?? 0) > flingVelocity);
    }
  }

  void _cancel() {
    if (_tracking) {
      _finish(false);
    }
  }

  void _finish(bool fling) {
    _tracking = false;
    final AnimationController controller = widget.route.dragController!;
    final NavigatorState navigator = widget.route.navigator!;
    if (fling || controller.value < 0.6) {
      navigator.pop();
    } else {
      controller.animateTo(
        1,
        duration: Motion.of(context).sheet,
        curve: Motion.of(context).curve,
      );
    }
    void settled(AnimationStatus status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.removeStatusListener(settled);
        navigator.didStopUserGesture();
      }
    }

    if (controller.isCompleted || controller.isDismissed) {
      navigator.didStopUserGesture();
    } else {
      controller.addStatusListener(settled);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: _start,
      onVerticalDragUpdate: _update,
      onVerticalDragEnd: _end,
      onVerticalDragCancel: _cancel,
      child: widget.child,
    );
  }
}

/// Shows a bottom sheet above everything, including other routes.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? dismissLabel,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    AppModalRoute<T>(
      builder: builder,
      kind: AppModalKind.sheet,
      scrimColor: AppTheme.of(context).palette.scrim,
      dismissLabel: dismissLabel,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
    ),
  );
}

/// Shows a dialog in the centre of the screen.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? dismissLabel,
  bool isDismissible = true,
}) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    AppModalRoute<T>(
      builder: builder,
      kind: AppModalKind.dialog,
      scrimColor: AppTheme.of(context).palette.scrim,
      dismissLabel: dismissLabel,
      isDismissible: isDismissible,
    ),
  );
}
