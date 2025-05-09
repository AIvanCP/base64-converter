import 'package:flutter/material.dart';

/// A button with animated gradient background that changes color on hover/tap.
class AnimatedGradientButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final List<Color> colors;
  final double width;
  final double height;

  const AnimatedGradientButton({
    Key? key,
    required this.text,
    this.icon,
    required this.onPressed,
    required this.colors,
    this.width = double.infinity,
    this.height = 50,
  }) : super(key: key);

  @override
  State<AnimatedGradientButton> createState() => _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<AnimatedGradientButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
          _controller.forward();
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
          _controller.reverse();
        });
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (!_isHovered) {
            setState(() {
              _isHovered = true;
              _controller.forward();
            });
          }
        },
        onTapUp: (_) {
          if (_isHovered) {
            setState(() {
              _isHovered = false;
              _controller.reverse();
            });
          }
        },
        onTapCancel: () {
          if (_isHovered) {
            setState(() {
              _isHovered = false;
              _controller.reverse();
            });
          }
        },
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isHovered
                      ? widget.colors.map((color) => color.withOpacity(0.8)).toList()
                      : widget.colors,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.colors.first.withOpacity(_animation.value * 0.3),
                    blurRadius: 10 + (10 * _animation.value),
                    spreadRadius: 1 + (2 * _animation.value),
                    offset: Offset(0, 4 * (1 - _animation.value)),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  splashColor: Colors.white.withOpacity(0.2),
                  highlightColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          widget.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
