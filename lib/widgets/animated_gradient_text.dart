import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A widget that displays text with animated gradient effect.
class AnimatedGradientText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final List<Color> colors;
  final Duration animationDuration;

  const AnimatedGradientText({
    Key? key,
    required this.text,
    required this.style,
    required this.colors,
    this.animationDuration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<AnimatedGradientText> createState() => _AnimatedGradientTextState();
}

class _AnimatedGradientTextState extends State<AnimatedGradientText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    )..repeat(reverse: true);
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
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: widget.colors,
              stops: [
                _calculateGradientPosition(0),
                _calculateGradientPosition(1),
                _calculateGradientPosition(2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: GradientRotation(
                (2 * math.pi) * _controller.value,
              ),
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: widget.style,
          ),
        );
      },
    );
  }

  double _calculateGradientPosition(int index) {
    final position = (index / 2) + (_controller.value / 2);
    return position > 1.0 ? position - 1.0 : position;
  }
}
