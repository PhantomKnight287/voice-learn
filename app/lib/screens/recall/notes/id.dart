import 'dart:convert';

import 'package:app/constants/main.dart';
import 'package:app/main.dart';
import 'package:app/utils/error.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

class NoteScreen extends StatefulWidget {
  final String id;
  const NoteScreen({
    super.key,
    required this.id,
  });

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  FlutterTts flutterTts = FlutterTts();
  bool ttsSetup = false;
  bool answerRevealed = false;
  Future<dynamic> _fetchNote() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse("$API_URL/recalls/notes/${widget.id}");
    logger.t("Requesting ${url.toString()}");
    final req = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    final body = jsonDecode(req.body);
    if (req.statusCode != 200) {
      final message = ApiResponseHelper.getErrorMessage(body);
      logger.e("Failed to fetch note info: $message");
      throw message;
    }
    logger.t("Fetched Note with id: ${widget.id}");
    return body;
  }

  void _setupTTS(
    String locale,
  ) async {
    final exists = await flutterTts.isLanguageAvailable(locale);
    if (exists && !ttsSetup) {
      await flutterTts.setLanguage(locale);
      setState(() {
        ttsSetup = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(
            BASE_MARGIN * 3,
          ),
          child: QueryBuilder<dynamic, dynamic>(
            'note_${widget.id}',
            _fetchNote,
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
              if (data['locale'] != null) {
                _setupTTS(data['locale']);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (data['locale'] != null)
                        IconButton(
                          onPressed: () async {
                            if (ttsSetup) {
                              await flutterTts.speak(
                                data['title'],
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please install ${data['language']['name']} in your TTS settings.'),
                                  duration: const Duration(
                                    seconds: 3,
                                  ),
                                ),
                              );
                            }
                          },
                          icon: HeroIcon(
                            HeroIcons.speakerWave,
                          ),
                        ),
                      Text(
                        data['title'],
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                        ),
                      ),
                    ],
                  ),
                  if (answerRevealed)
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (data['locale'] != null)
                          IconButton(
                            onPressed: () async {
                              if (ttsSetup) {
                                await flutterTts.speak(
                                  data['description'],
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Please install ${data['language']['name']} in your TTS settings.'),
                                    duration: const Duration(
                                      seconds: 3,
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const HeroIcon(
                              HeroIcons.speakerWave,
                            ),
                          ),
                        Text(
                          data['description'],
                          style: TextStyle(
                            fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                          ),
                        ),
                      ],
                    ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        answerRevealed = !answerRevealed;
                      });
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
                    child: Text(
                      answerRevealed ? "Hide Answer" : "Reveal Answer",
                      style: TextStyle(
                        fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
            refreshConfig: RefreshConfig.withDefaults(
              context,
              refreshOnMount: true,
              staleDuration: Duration(
                seconds: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Column _buildLoader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: double.infinity,
            height: 20.0,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(
                10,
              ),
            ),
          ),
        ),
        const SizedBox(
          height: BASE_MARGIN * 5,
        ),
        const Divider(),
        const SizedBox(
          height: BASE_MARGIN * 5,
        ),
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: double.infinity,
            height: 20.0,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(
                10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
