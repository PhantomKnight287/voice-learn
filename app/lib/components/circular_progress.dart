import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';

class CircularProgressAnimated extends StatefulWidget {
  final double maxItems;
  final double currentItems;
  final Color? color;
  final Color? bgColor;
  final bool animate;
  final Widget? child;
  const CircularProgressAnimated({
    super.key,
    required this.maxItems,
    required this.currentItems,
    this.color,
    this.bgColor,
    this.animate = false,
    this.child,
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
    if (widget.animate) {
      controller.forward();
    }
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
                value: (widget.animate ? animation.value : widget.currentItems) / widget.maxItems,
                strokeWidth: 3,
                backgroundColor: widget.bgColor ?? (AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.grey.shade300 : Colors.grey.shade400),
                color: widget.color ?? (AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.green.shade500 : Colors.green),
              ),
            ),
            widget.child != null
                ? widget.child!
                : Text(
                    widget.maxItems.toInt().toString(),
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                      fontWeight: Theme.of(context).textTheme.titleMedium!.fontWeight,
                      color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                    ),
                  )
          ],
        );
      },
    );
  }
}
