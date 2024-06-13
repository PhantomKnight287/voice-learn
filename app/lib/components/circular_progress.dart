import 'package:flutter/material.dart';

class CircularProgressAnimated extends StatefulWidget {
  final double maxItems;
  final double currentItems;
  final Color? color;
  final Color? bgColor;
  const CircularProgressAnimated({
    super.key,
    required this.maxItems,
    required this.currentItems,
    this.color,
    this.bgColor,
  });

  @override
  State<CircularProgressAnimated> createState() => _CircularProgressAnimatedState();
}

class _CircularProgressAnimatedState extends State<CircularProgressAnimated> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1000,
      ),
    );
    animation = Tween<double>(
      begin: 0,
      end: widget.currentItems.toDouble(),
    ).animate(
      controller,
    );
    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: animation.value / widget.maxItems,
                  strokeWidth: 3,
                  backgroundColor: widget.bgColor ?? Colors.grey.shade300,
                  color: widget.color ?? Colors.green.shade500,
                ),
              ),
              Text(
                widget.maxItems.toInt().toString(),
                style: Theme.of(context).textTheme.titleMedium,
              )
            ],
          );
        });
  }
}
