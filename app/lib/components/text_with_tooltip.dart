import 'package:flutter/cupertino.dart';
import 'package:super_tooltip/super_tooltip.dart';

class TextWithTooltip extends StatefulWidget {
  final Widget text;
  final Widget toolTip;

  const TextWithTooltip({
    super.key,
    required this.text,
    required this.toolTip,
  });

  @override
  State<TextWithTooltip> createState() => _TextWithTooltipState();
}

class _TextWithTooltipState extends State<TextWithTooltip> {
  final _controller = SuperTooltipController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (_controller.isVisible) {
          await _controller.hideTooltip();
        } else {
          await _controller.showTooltip();
        }
      },
      child: SuperTooltip(
        showBarrier: false,
        controller: _controller,
        content: widget.toolTip,
        child: widget.text,
        arrowTipDistance: 5,
      ),
    );
  }
}
