import 'dart:convert';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/screens/questions/report.dart';
import 'package:app/screens/recall/notes/create.dart';
import 'package:app/utils/error.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class LessonStatsScreen extends StatefulWidget {
  final String lessonId;

  const LessonStatsScreen({
    super.key,
    required this.lessonId,
  });

  @override
  State<LessonStatsScreen> createState() => _LessonStatsScreenState();
}

class _LessonStatsScreenState extends State<LessonStatsScreen> {
  FlutterTts flutterTts = FlutterTts();
  bool ttsSetup = false;
  Future<dynamic> _fetchDetailedLessonStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final req = await http.get(
      Uri.parse(
        "$API_URL/lessons/${widget.lessonId}/detailed-stats",
      ),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    final body = jsonDecode(req.body);
    if (req.statusCode != 200) {
      throw ApiResponseHelper.getErrorMessage(body);
    }

    return body;
  }

  void _setupTTS(
    String locale,
  ) async {
    final exists = await flutterTts.isLanguageAvailable(locale);
    if (exists && mounted && !ttsSetup) {
      await flutterTts.setLanguage(locale);
      setState(() {
        ttsSetup = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: BOTTOM(context),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            top: BASE_MARGIN * 0,
            bottom: BASE_MARGIN * 4,
            left: BASE_MARGIN * 4,
            right: BASE_MARGIN * 4,
          ),
          child: QueryBuilder<dynamic, dynamic>(
            'detailed_stats_${widget.lessonId}',
            _fetchDetailedLessonStats,
            builder: (context, query) {
              if (query.isLoading) {
                return _buildLoader();
              }
              if (query.hasError) {
                return Center(
                  child: Text(
                    query.error.toString(),
                  ),
                );
              }
              final data = query.data;
              if (data == null) return _buildLoader();
              _setupTTS(data['locale']);
              return ListView.separated(
                itemBuilder: (context, index) {
                  final question = data['questions'][index];
                  final answer = question['answers'][0];
                  final correct = answer['type'] == "correct";
                  final color = correct ? Colors.green : Colors.red;
                  final item = ListTile(
                    tileColor: getSecondaryColor(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                    ),
                    trailing: const SizedBox(
                      width: BASE_MARGIN * 2,
                    ),
                    leading: Padding(
                      padding: const EdgeInsets.only(
                        left: BASE_MARGIN * 2,
                      ),
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: color.withOpacity(
                            0.2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            (index + 1).toString(),
                            style: TextStyle(
                              color: color.withOpacity(
                                1,
                              ),
                              fontWeight: FontWeight.bold,
                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                            ),
                          ),
                        ),
                      ),
                    ),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.all(
                              BASE_MARGIN * 4,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      question['instruction'],
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 1.3,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.start,
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            if (ttsSetup)
                                              IconButton(
                                                onPressed: () async {
                                                  if (ttsSetup) {
                                                    await flutterTts.speak(question['question'].map((q) => q['translation']).join(" "));
                                                  }
                                                },
                                                style: ButtonStyle(
                                                  padding: WidgetStateProperty.all(
                                                    EdgeInsets.zero,
                                                  ),
                                                ),
                                                icon: const HeroIcon(
                                                  HeroIcons.speakerWave,
                                                ),
                                              ),
                                          ],
                                        ),
                                        Expanded(
                                          child: Wrap(
                                            children: [
                                              for (var word in question['question']) ...{
                                                GestureDetector(
                                                  onLongPress: () async {
                                                    if (word['word'] == "<empty>") return;
                                                    await HapticFeedback.lightImpact();
                                                    if (context.mounted) {
                                                      Navigator.of(context).push(
                                                        NoSwipePageRoute(
                                                          builder: (context) {
                                                            return CreateNoteScreen(
                                                              title: word['word'],
                                                              description: word['translation'],
                                                            );
                                                          },
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: word['word'] == "<empty>"
                                                      ? RichText(
                                                          text: TextSpan(
                                                            children: [
                                                              const TextSpan(text: "\u00A0"),
                                                              TextSpan(
                                                                text: "      ",
                                                                style: TextStyle(
                                                                  fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                                                                  decoration: TextDecoration.underline,
                                                                  decorationColor: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
                                                                ),
                                                              ),
                                                              const TextSpan(text: "\u00A0"),
                                                            ],
                                                          ),
                                                        )
                                                      : Tooltip(
                                                          message: word['translation'],
                                                          triggerMode: TooltipTriggerMode.tap,
                                                          onTriggered: () async {
                                                            if (ttsSetup == false) return;
                                                            await flutterTts.speak(word.translation);
                                                          },
                                                          child: Text(
                                                            word['word'],
                                                            style: TextStyle(
                                                              decoration: TextDecoration.underline,
                                                              decorationStyle: TextDecorationStyle.dashed,
                                                              fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                                                            ),
                                                          ),
                                                        ),
                                                ),
                                                SizedBox(
                                                  width: BASE_MARGIN.toDouble(),
                                                ),
                                              },
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: BASE_MARGIN * 2,
                                    ),
                                    if (correct)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            "Answer",
                                            style: TextStyle(
                                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 1.2,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            answer['answer'],
                                            style: TextStyle(
                                              fontSize: Theme.of(context).textTheme.titleMedium!.fontSize! * 0.8,
                                              color: Colors.green,
                                              fontFamily: "CalSans",
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (!correct)
                                      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                        Text(
                                          "Your answer",
                                          style: TextStyle(
                                            fontSize: Theme.of(context).textTheme.titleMedium!.fontSize!,
                                            fontFamily: "CalSans",
                                          ),
                                        ),
                                        Text(
                                          answer['answer'],
                                          style: TextStyle(
                                            fontSize: Theme.of(context).textTheme.titleMedium!.fontSize! * 0.7,
                                            color: Colors.red,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: BASE_MARGIN * 4,
                                        ),
                                        Text(
                                          "Correct Answer",
                                          style: TextStyle(
                                            fontSize: Theme.of(context).textTheme.titleMedium!.fontSize!,
                                            fontFamily: "CalSans",
                                          ),
                                        ),
                                        Text(
                                          question['correctAnswer'],
                                          style: TextStyle(
                                            fontSize: Theme.of(context).textTheme.titleMedium!.fontSize! * 0.7,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ]),
                                    const SizedBox(
                                      height: BASE_MARGIN * 2,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        style: ButtonStyle(
                                          alignment: Alignment.center,
                                          foregroundColor: WidgetStateProperty.all(Colors.black),
                                          padding: WidgetStateProperty.resolveWith<EdgeInsetsGeometry>(
                                            (Set<WidgetState> states) {
                                              return const EdgeInsets.all(15);
                                            },
                                          ),
                                          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          "Close",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: IconButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            NoSwipePageRoute(
                                              builder: (context) {
                                                return ReportScreen(
                                                  questionId: question['id'],
                                                );
                                              },
                                            ),
                                          );
                                        },
                                        icon: const HeroIcon(
                                          HeroIcons.flag,
                                          color: Colors.red,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                        enableDrag: true,
                        showDragHandle: true,
                      );
                    },
                    title: Text(
                      question['instruction'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: RichText(
                      text: TextSpan(
                        children: question['question'].map<InlineSpan>((ques) {
                          if (ques['word'] == "<empty>") {
                            return TextSpan(
                              children: [
                                const TextSpan(text: "\u00A0"), // Non-breaking space before
                                TextSpan(
                                  text: "      ", // Six spaces to represent an empty word
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    decorationColor: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
                                  ),
                                ),
                                const TextSpan(text: "\u00A0"), // Non-breaking space after
                              ],
                              style: TextStyle(
                                color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
                              ),
                            );
                          } else {
                            return TextSpan(
                              text: ques['word'],
                              style: TextStyle(
                                color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
                              ),
                            );
                          }
                        }).toList(),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    contentPadding: EdgeInsets.zero,
                  );

                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: BASE_MARGIN * 2,
                        ),
                        Text(
                          data['name'],
                          style: TextStyle(
                            fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "${data['questionsCount']} questions",
                        ),
                        const SizedBox(
                          height: BASE_MARGIN * 2,
                        ),
                        item
                      ],
                    );
                  }
                  return item;
                },
                separatorBuilder: (context, index) {
                  return const SizedBox(
                    height: BASE_MARGIN * 2,
                  );
                },
                shrinkWrap: true,
                itemCount: data['questions'].length,
              );
            },
          ),
        ),
      ),
    );
  }

  Column _buildLoader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: BASE_MARGIN * 2,
        ),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade400,
          child: Container(
            height: 20,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(
          height: BASE_MARGIN * 2,
        ),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade400,
          child: Container(
            height: 10,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(
          height: BASE_MARGIN * 12,
        ),
        ListView.separated(
          itemBuilder: (context, index) {
            return Row(
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade400,
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(
                  width: BASE_MARGIN * 2,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade400,
                      child: Container(
                        height: 20,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: BASE_MARGIN * 2,
                    ),
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade400,
                      child: Container(
                        height: 10,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          itemCount: 8,
          shrinkWrap: true,
          separatorBuilder: (context, index) {
            return const SizedBox(
              height: BASE_MARGIN * 4,
            );
          },
        ),
      ],
    );
  }
}
