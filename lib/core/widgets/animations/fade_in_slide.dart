import 'package:flutter/material.dart';

class FadeInSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double offset;
  final Curve curve;
  final Duration delay;

  const FadeInSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.offset = 30.0,
    this.curve = Curves.easeOutCubic,
    this.delay = Duration.zero,
  });

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Interval(0.0, 1.0, curve: widget.curve)),
    );
    _slide = Tween<Offset>(begin: Offset(0, widget.offset / 100), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
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
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _slide.value.dy * 100),
            child: widget.child,
          ),
        );
      },
    );
  }
}
