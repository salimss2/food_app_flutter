import 'package:flutter/material.dart';

class AddToCartAnimator {
  static void animate({
    required BuildContext context,
    required GlobalKey sourceKey,
    required GlobalKey targetKey,
    required Widget imageWidget,
    Duration duration = const Duration(milliseconds: 800),
    VoidCallback? onComplete,
  }) {
    final RenderBox? sourceBox =
        sourceKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? targetBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;

    if (sourceBox == null || targetBox == null) {
      if (onComplete != null) onComplete();
      return;
    }

    final sourceSize = sourceBox.size;
    final sourcePosition = sourceBox.localToGlobal(Offset.zero);
    final targetPosition = targetBox.localToGlobal(Offset.zero);

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return _FlyAnimation(
          sourcePosition: sourcePosition,
          targetPosition: targetPosition,
          sourceSize: sourceSize,
          imageWidget: imageWidget,
          duration: duration,
          onComplete: () {
            overlayEntry.remove();
            if (onComplete != null) onComplete();
          },
        );
      },
    );

    Overlay.of(context).insert(overlayEntry);
  }
}

class _FlyAnimation extends StatefulWidget {
  final Offset sourcePosition;
  final Offset targetPosition;
  final Size sourceSize;
  final Widget imageWidget;
  final Duration duration;
  final VoidCallback onComplete;

  const _FlyAnimation({
    required this.sourcePosition,
    required this.targetPosition,
    required this.sourceSize,
    required this.imageWidget,
    required this.duration,
    required this.onComplete,
  });

  @override
  State<_FlyAnimation> createState() => _FlyAnimationState();
}

class _FlyAnimationState extends State<_FlyAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    // Shrinks the image to 20% size as it flies towards the cart
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = _controller.value;
        final Offset start = widget.sourcePosition;
        final Offset end = widget.targetPosition;

        // Control point for quadratic bezier (creates the arcing motion upwards/rightwards)
        final Offset controlPoint = Offset(
          start.dx + (end.dx - start.dx) / 2 + 150,
          start.dy + (end.dy - start.dy) / 2 - 100,
        );

        // Quadratic bezier interpolation algorithm
        final double dx =
            (1 - t) * (1 - t) * start.dx +
            2 * (1 - t) * t * controlPoint.dx +
            t * t * end.dx;
        final double dy =
            (1 - t) * (1 - t) * start.dy +
            2 * (1 - t) * t * controlPoint.dy +
            t * t * end.dy;

        return Positioned(
          left: dx,
          top: dy,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: widget.sourceSize.width,
              height: widget.sourceSize.height,
              child: widget.imageWidget,
            ),
          ),
        );
      },
    );
  }
}
