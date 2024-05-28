import 'package:flutter/material.dart';

class AnimatedProgressIndicator extends StatefulWidget {
  final double percentage;
  final Color backgroundColor;
  final Color progressColor;
  final double height;
  final double width;
  final double borderRadius;

  const AnimatedProgressIndicator({
    super.key,
    required this.percentage,
    this.backgroundColor = Colors.grey,
    this.progressColor = Colors.blueAccent,
    this.height = 10,
    this.width = 300,
    this.borderRadius = 12,
  });

  @override
  State<AnimatedProgressIndicator> createState() => _AnimatedProgressIndicatorState();
}

class _AnimatedProgressIndicatorState extends State<AnimatedProgressIndicator> {
  double _width = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _width = widget.percentage * widget.width;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 300,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: widget.backgroundColor,
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          width: _width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: widget.progressColor,
          ),
        ),
      ],
    );
  }
}
