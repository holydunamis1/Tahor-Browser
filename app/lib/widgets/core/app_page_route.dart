import 'package:flutter/widgets.dart';

import '../../core/constants/motion.dart';

/// A full-screen page route: the new page fades in while sliding 20 px from
/// the end side (350 ms in, 280 ms out), and an edge swipe from the start
/// side goes back on both platforms. Under reduce-motion it is instant.
class AppPageRoute<T> extends PageRoute<T> {
  AppPageRoute({required this.builder, super.settings});

  final WidgetBuilder builder;

  /// How far the page slides while fading, in logical pixels.
  static const double slideDistance = 20;

  /// Width of the strip along the start edge that starts a back swipe.
  static const double edgeWidth = 24;

  /// The route's own animation, so the edge swipe can drive it.
  AnimationController? get dragController => controller;

  Motion get _motion {
    final BuildContext? context = navigator?.context;
    return context == null ? Motion.standard : Motion.of(context);
  }

  @override
  Duration get transitionDuration => _motion.push;

  @override
  Duration get reverseTransitionDuration => _motion.pop;

  @override
  bool get opaque => true;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final Motion motion = Motion.of(context);
    final Animation<double> eased = animation.drive(
      CurveTween(curve: motion.curve),
    );
    final double direction = Directionality.of(context) == TextDirection.rtl
        ? -1
        : 1;
    return _EdgeSwipeBack<T>(
      route: this,
      child: FadeTransition(
        opacity: eased,
        child: AnimatedBuilder(
          animation: eased,
          builder: (BuildContext context, Widget? child) {
            return Transform.translate(
              offset: Offset(direction * slideDistance * (1 - eased.value), 0),
              child: child,
            );
          },
          child: child,
        ),
      ),
    );
  }
}

class _EdgeSwipeBack<T> extends StatefulWidget {
  const _EdgeSwipeBack({required this.route, required this.child});

  final AppPageRoute<T> route;
  final Widget child;

  @override
  State<_EdgeSwipeBack<T>> createState() => _EdgeSwipeBackState<T>();
}

class _EdgeSwipeBackState<T> extends State<_EdgeSwipeBack<T>> {
  bool _tracking = false;

  bool get _enabled {
    final NavigatorState? navigator = widget.route.navigator;
    return navigator != null &&
        widget.route.isCurrent &&
        navigator.canPop() &&
        !navigator.userGestureInProgress &&
        widget.route.dragController != null;
  }

  double get _direction =>
      Directionality.of(context) == TextDirection.rtl ? -1 : 1;

  void _start(DragStartDetails details) {
    if (!_enabled) {
      return;
    }
    _tracking = true;
    widget.route.navigator!.didStartUserGesture();
  }

  void _update(DragUpdateDetails details) {
    if (!_tracking) {
      return;
    }
    final double width = context.size?.width ?? 1;
    final double delta = (details.primaryDelta ?? 0) * _direction;
    widget.route.dragController!.value -= delta / width;
  }

  void _end(DragEndDetails details) {
    if (!_tracking) {
      return;
    }
    final double width = context.size?.width ?? 1;
    final double velocity = (details.primaryVelocity ?? 0) * _direction / width;
    _finish(velocity.abs() >= 1 ? velocity > 0 : null);
  }

  void _cancel() {
    if (_tracking) {
      _finish(false);
    }
  }

  /// [pop] is null when the position alone decides.
  void _finish(bool? pop) {
    _tracking = false;
    final AnimationController controller = widget.route.dragController!;
    final NavigatorState navigator = widget.route.navigator!;
    final bool goBack = pop ?? controller.value < 0.5;
    if (goBack) {
      navigator.pop();
    } else {
      controller.animateTo(
        1,
        duration: Motion.of(context).push,
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
    return Stack(
      children: <Widget>[
        widget.child,
        PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          width: AppPageRoute.edgeWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: _start,
            onHorizontalDragUpdate: _update,
            onHorizontalDragEnd: _end,
            onHorizontalDragCancel: _cancel,
          ),
        ),
      ],
    );
  }
}
