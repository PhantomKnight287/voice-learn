import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/screens/recall/notes/create.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BackwardCompatibleWordRendering extends StatelessWidget {
  final List<dynamic> text;
  final bool isSentByMe;

  const BackwardCompatibleWordRendering({
    super.key,
    required this.text,
    required this.isSentByMe,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        for (var word in text) ...{
          _buildWordWidget(context, word),
          SizedBox(width: BASE_MARGIN.toDouble()),
        },
      ],
    );
  }

  Widget _buildWordWidget(BuildContext context, dynamic word) {
    if (word is String) {
      return GestureDetector(
        onLongPress: () async {
          await HapticFeedback.lightImpact();
          if (context.mounted) {
            Navigator.of(context).push(NoSwipePageRoute(
              builder: (context) => CreateNoteScreen(title: word),
            ));
          }
        },
        child: Text(
          word,
          style: TextStyle(
            color: isSentByMe ? Colors.black : null,
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dashed,
          ),
        ),
      );
    } else if (word is Map<String, dynamic>) {
      final String wordText = word['word'] ?? word['response'] ?? '';
      final String? translation = word['translation'];

      if (translation != null) {
        return GestureDetector(
          onLongPress: () async {
            if (wordText == "<empty>") return;
            await HapticFeedback.lightImpact();
            if (context.mounted) {
              Navigator.of(context).push(
                NoSwipePageRoute(
                  builder: (context) => CreateNoteScreen(
                    title: wordText,
                    description: translation,
                  ),
                ),
              );
            }
          },
          child: Tooltip(
            message: translation,
            triggerMode: TooltipTriggerMode.tap,
            child: Text(
              wordText,
              style: const TextStyle(
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dashed,
              ),
            ),
          ),
        );
      } else {
        return Text(
          wordText,
          style: TextStyle(
            color: isSentByMe ? Colors.black : null,
          ),
        );
      }
    } else {
      // Handle unexpected types gracefully
      return const SizedBox.shrink();
    }
  }
}
