import 'package:flutter/material.dart';

/// Reusable Pulsing Dot Widget for live status indicators
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingDot({
    super.key,
    this.color = const Color(0xFF10B981),
    this.size = 10.0,
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: _animation.value),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _animation.value * 0.6),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Reusable Bouncing Icon Widget for alerts
class BouncingAlertIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const BouncingAlertIcon({
    super.key,
    this.icon = Icons.warning_amber_rounded,
    this.color = const Color(0xFFF59E0B),
    this.size = 24.0,
  });

  @override
  State<BouncingAlertIcon> createState() => _BouncingAlertIconState();
}

class _BouncingAlertIconState extends State<BouncingAlertIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Icon(
            widget.icon,
            color: widget.color,
            size: widget.size,
          ),
        );
      },
    );
  }
}

/// Reusable Spinning Loader Widget
class SpinningLoader extends StatefulWidget {
  final Color color;
  final double size;

  const SpinningLoader({
    super.key,
    this.color = const Color(0xFF0F9D58),
    this.size = 28.0,
  });

  @override
  State<SpinningLoader> createState() => _SpinningLoaderState();
}

class _SpinningLoaderState extends State<SpinningLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(widget.color),
        ),
      ),
    );
  }
}

/// Reusable Fade + Scale entrance wrapper for modals/dialogs
class FadeScaleModal extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const FadeScaleModal({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 250),
  });

  @override
  State<FadeScaleModal> createState() => _FadeScaleModalState();
}

class _FadeScaleModalState extends State<FadeScaleModal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
