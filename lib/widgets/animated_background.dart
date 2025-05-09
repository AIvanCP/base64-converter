import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final double particleSize;
  final int numberOfParticles;

  const AnimatedBackground({
    Key? key,
    required this.child,
    required this.colors,
    this.particleSize = 40.0,
    this.numberOfParticles = 20,
  }) : super(key: key);

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;
  late final List<Offset> _positions;
  late final List<double> _sizes;
  late final List<Color> _particleColors;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations and positions
    _controllers = List.generate(
      widget.numberOfParticles,
      (index) => AnimationController(
        duration: Duration(seconds: 10 + (index % 5)),
        vsync: this,
      ),
    );

    _animations = List.generate(
      widget.numberOfParticles,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _controllers[index],
          curve: Curves.easeInOut,
        ),
      ),
    );

    _positions = List.generate(
      widget.numberOfParticles,
      (index) => Offset(
        (index * 50) % 300,
        (index * 30) % 300,
      ),
    );

    _sizes = List.generate(
      widget.numberOfParticles,
      (index) => widget.particleSize * (0.3 + (index % 3) * 0.2),
    );

    _particleColors = List.generate(
      widget.numberOfParticles,
      (index) => widget.colors[index % widget.colors.length].withOpacity(0.1),
    );

    // Start animations with different delay for each particle
    for (int i = 0; i < widget.numberOfParticles; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background particles
        ...List.generate(widget.numberOfParticles, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              // Generate different movement pattern for each particle
              final dx = (index % 2 == 0)
                  ? _animations[index].value * 100
                  : (1 - _animations[index].value) * 100;
              final dy = (index % 3 == 0)
                  ? _animations[index].value * 80
                  : (1 - _animations[index].value) * 80;

              return Positioned(
                left: (_positions[index].dx + dx) % MediaQuery.of(context).size.width,
                top: (_positions[index].dy + dy) % MediaQuery.of(context).size.height,
                child: Opacity(
                  opacity: 0.3 + (_animations[index].value * 0.3),
                  child: Container(
                    width: _sizes[index] * (0.8 + _animations[index].value * 0.4),
                    height: _sizes[index] * (0.8 + _animations[index].value * 0.4),
                    decoration: BoxDecoration(
                      color: _particleColors[index],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _particleColors[index].withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
        
        // Content
        widget.child,
      ],
    );
  }
}
