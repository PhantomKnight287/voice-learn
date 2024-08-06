import 'dart:convert';
import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:app/bloc/application/application_bloc.dart';
import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/main.dart';
import 'package:app/models/language.dart';
import 'package:app/models/question.dart';
import 'package:app/models/user.dart';
import 'package:app/screens/questions/complete.dart';
import 'package:app/screens/recall/notes/create.dart';
import 'package:app/utils/error.dart';
import 'package:app/utils/string.dart';
import 'package:async_builder/async_builder.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:vibration/vibration.dart';

class QuestionsScreen extends StatefulWidget {
  final String lessonId;
  const QuestionsScreen({
    super.key,
    required this.lessonId,
  });

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  int _currentStep = 0;
  String _selectedStep = '';
  FlutterTts flutterTts = FlutterTts();
  bool ttsSetup = false;

  late Future<List<Question>> _fetchQuestions;
  final _pageController = PageController();
  final _answerController = TextEditingController();
  final player = AudioPlayer();
  bool? correct;
  bool _valueEntered = false;
  final startDate = DateTime.now().toIso8601String();
  bool _disabled = false;
  double _speed = 0.5;
  String testSentence = "";
  Language? lessonLanguage;
  bool _devModeEnabled = false;
  List<dynamic> voices = [];
  List<dynamic> engines = [];
  String defaultEngine = '';

  @override
  void dispose() {
    super.dispose();
  }

  void _getTTSConfig(
    String locale,
  ) async {
    final voices = await flutterTts.getVoices;
    final engines = Platform.isAndroid ? await flutterTts.getEngines : [];
    final defaultEngine = Platform.isAndroid ? await flutterTts.getDefaultEngine : '';
    final filteredVoices = ((voices == null || voices.isEmpty) ? [] : voices).where((_voice) => (_voice?['locale']).toLowerCase() == locale.toLowerCase()).toList();
    setState(() {
      this.voices = filteredVoices;
      this.engines = engines;
      this.defaultEngine = defaultEngine;
    });
  }

  void _setSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    final speed = prefs.getDouble("tts_speed");

    setState(() {
      _speed = double.parse((speed ?? 0.5).toStringAsFixed(1));
    });
    await flutterTts.setSpeechRate(speed ?? 0.5);
  }

  void _getDevMode() async {
    final prefs = await SharedPreferences.getInstance();
    final dev = prefs.getBool("dev_enabled");
    setState(() {
      _devModeEnabled = dev ?? false;
    });
  }

  void _getLanguages(
    String locale,
  ) async {
    final exists = await flutterTts.isLanguageAvailable(locale);
    if (exists) {
      await flutterTts.setLanguage(locale);
      setState(() {
        ttsSetup = true;
      });
    }
  }

  Future<List<Question>> _fetchQuestionsFuture() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token")!;
    final req = await http.get(
      Uri.parse(
        "$API_URL/questions/${widget.lessonId}",
      ),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    final body = jsonDecode(req.body);
    _getLanguages(
      body['locale'],
    );
    _getTTSConfig(body['locale']);
    testSentence = body['sentence'];
    lessonLanguage = Language.fromJSON(body['language']);
    return (body['questions'] as List).map((q) => Question.toJSON(q)).toList();
  }

  Future<void> _onCorrectAnswer(bool last, String questionId, String answer, {bool submit = true}) async {
    await Future.delayed(
      const Duration(
        milliseconds: 400,
      ),
    );
    setState(() {
      _currentStep = _currentStep + (last ? 0 : 1);
      _selectedStep = "";
    });
    _answerController.text = "";
    FocusManager.instance.primaryFocus?.unfocus();
    if (last == false) {
      _pageController
          .nextPage(
        duration: const Duration(
          milliseconds: 300,
        ),
        curve: Curves.linear,
      )
          .then(
        (value) {
          setState(() {
            correct = null;
          });
        },
      );
    }
    if (submit) {
      _submitAnswer(questionId, answer, last).then(
        (value) async {
          if (last) {
            Navigator.of(context).pushReplacement(
              NoSwipePageRoute(
                builder: (context) {
                  return LessonCompleteScreen(
                    questionId: questionId,
                    showAd: true,
                  );
                },
              ),
            );
          }
        },
      );
    }
  }

  Future<void> _onIncorrectAnswer(
    String correctAnswer,
    String yourAnswer,
    String questionId,
    bool last,
  ) async {
    final userBloc = context.read<UserBloc>();
    final state = userBloc.state;
    if (state.lives >= 1) {
      userBloc.add(
        UserLoggedInEvent.setEmeraldsAndLives(
          state,
          state.emeralds,
          state.lives - 1,
        ),
      );
    }
    _submitAnswer(questionId, yourAnswer, last).then(
      (value) {
        if (last) {}
      },
    );
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) {},
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BASE_MARGIN * 3,
              vertical: BASE_MARGIN * 4,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BASE_MARGIN * 3),
              ),
              height: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Your answer",
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.titleMedium!.fontSize!,
                      fontFamily: "CalSans",
                    ),
                  ),
                  Text(
                    yourAnswer,
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
                    correctAnswer,
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.titleMedium!.fontSize! * 0.7,
                      color: Colors.green,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      if (last) {
                        Navigator.of(context).pushReplacement(
                          NoSwipePageRoute(
                            builder: (context) {
                              return LessonCompleteScreen(
                                questionId: questionId,
                                showAd: true,
                              );
                            },
                          ),
                        );
                      } else {
                        await _onCorrectAnswer(
                          last,
                          questionId,
                          yourAnswer,
                          submit: false,
                        );
                      }
                    },
                    style: ButtonStyle(
                      alignment: Alignment.center,
                      foregroundColor: WidgetStateProperty.all(Colors.black),
                      backgroundColor: WidgetStateProperty.all(
                        PRIMARY_COLOR,
                      ),
                    ),
                    child: Text(
                      last ? "Confirm" : "Next",
                      style: TextStyle(
                        fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      isDismissible: false,
      enableDrag: false,
    );
  }

  Future<void> _submitAnswer(
    String questionId,
    String answer,
    bool last,
  ) async {
    try {
      final userBloc = context.read<UserBloc>();
      final state = userBloc.state;
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token")!;
      final url = Uri.parse(
        "$API_URL/questions/$questionId/answer",
      );
      logger.d("Making request to ${url.toString()}");
      final req = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-type": "application/json",
        },
        body: jsonEncode(
          {
            "answer": answer,
            "last": last,
            "startDate": startDate,
            "endDate": DateTime.now().toIso8601String(),
            "lessonId": widget.lessonId,
          },
        ),
      );
      final body = jsonDecode(req.body);

      if (req.statusCode == 201) {
        logger.d("Answer to question $questionId submitted");
        if (body['correct'] == false) {
          userBloc.add(
            DecreaseUserHeartEvent.decreaseBy(
              state,
            ),
          );
        }
      } else {
        final message = ApiResponseHelper.getErrorMessage(body);
        logger.e("Failed to submit answer: $message");
      }
    } catch (e) {
      logger.e("Caught error while submitting answer: ${e.toString()}");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchQuestions = _fetchQuestionsFuture();
    _setSpeed();
    _getDevMode();
  }

  @override
  Widget build(BuildContext context) {
    final userBloc = context.read<UserBloc>();

    return AsyncBuilder(
        future: _fetchQuestions,
        waiting: (context) => Scaffold(
              appBar: AppBar(
                leading: Shimmer.fromColors(
                  baseColor: Colors.grey.shade400,
                  highlightColor: getSecondaryColor(context),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      radius: 30,
                      child: SizedBox(
                        height: 30,
                        width: 30,
                      ),
                    ),
                  ),
                ),
                actions: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade400,
                    highlightColor: getSecondaryColor(context),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        radius: 30,
                        child: SizedBox(
                          height: 30,
                          width: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
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
                ),
              ),
            ),
        builder: (context, value) {
          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) {
              if (!didPop) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return Builder(builder: (context) {
                      return Dialog(
                        alignment: Alignment.center,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Container(
                          height: 400,
                          padding: const EdgeInsets.all(BASE_MARGIN * 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset("assets/images/cry.gif"),
                              ),
                              const SizedBox(
                                height: BASE_MARGIN * 3,
                              ),
                              Text(
                                "Are you sure?",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(
                                height: BASE_MARGIN * 2,
                              ),
                              Text(
                                "Are you sure you want to quit? You will have to start over again.",
                                style: TextStyle(
                                  fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                ),
                              ),
                              const SizedBox(
                                height: BASE_MARGIN * 4,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                      },
                                      style: ButtonStyle(
                                        alignment: Alignment.center,
                                        foregroundColor: WidgetStateProperty.all(Colors.black),
                                        backgroundColor: WidgetStateProperty.all(Colors.red),
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
                                        "Back",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: BASE_MARGIN * 2,
                                  ),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      style: ButtonStyle(
                                        alignment: Alignment.center,
                                        foregroundColor: WidgetStateProperty.all(Colors.black),
                                        backgroundColor: WidgetStateProperty.all(Colors.green),
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
                                        "Cancel",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    });
                  },
                );
              }
            },
            child: Scaffold(
              appBar: AppBar(
                leading: null,
                leadingWidth: 30,
                title: LayoutBuilder(builder: (context, constraints) {
                  return Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: constraints.maxWidth,
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth,
                            ),
                            height: 15,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: getSecondaryColor(context),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: (_currentStep / (value?.length ?? 10)) * constraints.maxWidth,
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth,
                            ),
                            height: 15,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: PRIMARY_COLOR,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),
                actions: [
                  BlocBuilder<UserBloc, UserState>(
                    bloc: userBloc,
                    builder: (context, state) {
                      return IconButton(
                        onPressed: () {},
                        icon: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              "assets/svgs/heart.svg",
                              width: 25,
                              height: 25,
                            ),
                            const SizedBox(
                              width: BASE_MARGIN * 2,
                            ),
                            state.tier == Tiers.premium
                                ? const Icon(
                                    Icons.all_inclusive_outlined,
                                  )
                                : Text(
                                    state.lives.toString(),
                                    style: TextStyle(
                                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                            const SizedBox(
                              width: BASE_MARGIN * 1,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (_devModeEnabled)
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  DropdownButton<String>(
                                    onChanged: (String? newValue) async {
                                      if (newValue != null) {
                                        final val = jsonDecode(newValue);
                                        logger.t("TTS voice changed to $newValue");
                                        await flutterTts.setVoice({
                                          "name": val['name'],
                                          "locale": val['locale'],
                                        });
                                        final prefs = await SharedPreferences.getInstance();
                                        prefs.setString("TTS_VOICE_${val['locale'].toLowerCase()}", newValue);
                                        await flutterTts.speak("This is a test sentence");
                                      }
                                    },
                                    items: voices.map<DropdownMenuItem<String>>((dynamic value) {
                                      return DropdownMenuItem<String>(
                                        value: jsonEncode(value),
                                        child: Text(
                                          value['name'],
                                        ),
                                      );
                                    }).toList(),
                                    isExpanded: true,
                                    hint: Text('Select Voice'),
                                  ),
                                  SizedBox(height: 16.0),
                                  if (Platform.isAndroid)
                                    DropdownButton<String>(
                                      onChanged: (String? newValue) async {
                                        if (newValue != null) {
                                          await flutterTts.setEngine(newValue);
                                          final prefs = await SharedPreferences.getInstance();
                                          prefs.setString("TTS_ENGINE", newValue);
                                        }
                                      },
                                      items: engines.map<DropdownMenuItem<String>>((dynamic value) {
                                        return DropdownMenuItem<String>(
                                          value: value as String,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      isExpanded: true,
                                      hint: Text('Select Engine'),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      icon: Icon(
                        Icons.settings_rounded,
                        size: 25,
                      ),
                    )
                ],
              ),
              body: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BASE_MARGIN * 2,
                    0,
                    BASE_MARGIN * 2,
                    BASE_MARGIN * 2,
                  ),
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      if (value != null)
                        for (var question in value)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                question.instruction,
                                style: TextStyle(
                                  fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () async {
                                      if (ttsSetup) {
                                        await flutterTts.speak(question.question
                                            .map((q) => q.translation)
                                            .map((translation) => translation == "<empty>" ? "." : translation) // Replace "<empty>" with a period for a pause
                                            .join(" "));
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Please install ${lessonLanguage?.name} in your TTS settings.'),
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
                                  for (var word in question.question) ...{
                                    GestureDetector(
                                      onLongPress: () async {
                                        if (word.word == "<empty>") return;
                                        await HapticFeedback.lightImpact();
                                        if (context.mounted) {
                                          Navigator.of(context).push(NoSwipePageRoute(
                                            builder: (context) {
                                              return CreateNoteScreen(
                                                title: word.word,
                                                description: word.translation,
                                                language: lessonLanguage,
                                              );
                                            },
                                          ));
                                        }
                                      },
                                      child: word.word == "<empty>"
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
                                              message: word.translation,
                                              triggerMode: TooltipTriggerMode.tap,
                                              onTriggered: () async {
                                                if (ttsSetup == false) return;
                                                await flutterTts.speak(word.translation);
                                              },
                                              child: Text(
                                                word.word,
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
                              const Spacer(),
                              if (question.type == QuestionType.sentence) ...{
                                Wrap(
                                  children: [
                                    TextField(
                                      maxLines: 5,
                                      keyboardType: TextInputType.text,
                                      controller: _answerController,
                                      onChanged: (value) {
                                        if (value.isNotEmpty) {
                                          setState(() {
                                            _valueEntered = true;
                                          });
                                        } else {
                                          setState(() {
                                            _valueEntered = false;
                                          });
                                        }
                                      },
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.all(
                                          BASE_MARGIN * 2,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10.0),
                                          borderSide: BorderSide.none,
                                        ),
                                        prefixIconColor: Colors.black,
                                        hintText: "Enter your answer here...",
                                        fillColor: getSecondaryColor(context),
                                        filled: true,
                                        hintStyle: TextStyle(
                                          fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                        ),
                                        errorStyle: TextStyle(
                                          color: Colors.red,
                                          fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              } else ...{
                                ListView.separated(
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final option = question.options[index];
                                    return ListTile(
                                      title: Text(option),
                                      tileColor: getSecondaryColor(context),
                                      splashColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(BASE_MARGIN * 2),
                                        side: _selectedStep == option
                                            ? BorderSide(
                                                color: Colors.green.shade500,
                                                strokeAlign: 2,
                                                style: BorderStyle.solid,
                                                width: 2,
                                              )
                                            : const BorderSide(
                                                color: Colors.transparent,
                                                strokeAlign: 2,
                                                style: BorderStyle.solid,
                                                width: 2,
                                              ),
                                      ),
                                      enableFeedback: true,
                                      enabled: true,
                                      onTap: () async {
                                        await HapticFeedback.lightImpact();
                                        setState(() {
                                          _selectedStep = option;
                                        });
                                        if (ttsSetup) {
                                          await flutterTts.speak(option);
                                        }
                                      },
                                    );
                                  },
                                  shrinkWrap: true,
                                  itemCount: question.options.length,
                                  separatorBuilder: (context, index) {
                                    return const SizedBox(
                                      height: BASE_MARGIN * 2,
                                    );
                                  },
                                ),
                              },
                              const SizedBox(
                                height: BASE_MARGIN * 5,
                              ),
                              SafeArea(
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: Center(
                                        child: CircleAvatar(
                                          radius: 22,
                                          backgroundColor: getSecondaryColor(context),
                                          child: IconButton(
                                            onPressed: () {
                                              FocusManager.instance.primaryFocus?.unfocus();
                                              showModalBottomSheet(
                                                context: context,
                                                builder: (context) {
                                                  return StatefulBuilder(builder: (context, setStateBuilder) {
                                                    return Container(
                                                      padding: const EdgeInsets.all(16.0),
                                                      height: 200,
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          const Text(
                                                            'Select Speed of AI Audio',
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: BASE_MARGIN * 4,
                                                          ),
                                                          Text('Speed: ${(_speed).toStringAsFixed(1)}x'),
                                                          Slider(
                                                            min: 0.1,
                                                            max: 1.0,
                                                            divisions: 9,
                                                            value: _speed,
                                                            onChanged: (value) {
                                                              setStateBuilder(() {
                                                                _speed = double.parse(value.toStringAsFixed(1));
                                                              });
                                                              setState(() {
                                                                _speed = double.parse(value.toStringAsFixed(1));
                                                              });
                                                            },
                                                          ),
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                            children: [
                                                              ElevatedButton(
                                                                onPressed: () async {
                                                                  flutterTts.setSpeechRate(_speed);
                                                                  await flutterTts.speak(testSentence);
                                                                },
                                                                style: ButtonStyle(
                                                                  shape: WidgetStateProperty.all(
                                                                    RoundedRectangleBorder(
                                                                      borderRadius: BorderRadius.circular(
                                                                        10,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  backgroundColor: WidgetStateProperty.all(
                                                                    SECONDARY_BG_COLOR,
                                                                  ),
                                                                ),
                                                                child: const Text(
                                                                  'Preview',
                                                                  style: TextStyle(
                                                                    color: Colors.black,
                                                                  ),
                                                                ),
                                                              ),
                                                              ElevatedButton(
                                                                onPressed: () async {
                                                                  final prefs = await SharedPreferences.getInstance();
                                                                  prefs.setDouble("tts_speed", _speed);
                                                                  Navigator.of(context).pop();
                                                                  await flutterTts.setSpeechRate(_speed);
                                                                  setState(() {});
                                                                },
                                                                style: ButtonStyle(
                                                                  shape: WidgetStateProperty.all(
                                                                    RoundedRectangleBorder(
                                                                      borderRadius: BorderRadius.circular(
                                                                        10,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                child: const Text(
                                                                  'Save',
                                                                  style: TextStyle(
                                                                    color: Colors.black,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  });
                                                },
                                              );
                                            },
                                            icon: Center(
                                              child: Text(
                                                _speed.toString(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          if (_disabled) return;
                                          setState(() {
                                            _disabled = true;
                                          });
                                          final applicationState = context.read<ApplicationBloc>().state;
                                          final hasVibrator = applicationState.hasVibrator;
                                          final hasAmplitude = applicationState.hasAmplitudeControl;
                                          final correctAnswerPatterns = [1, 100];
                                          final correctVibrationIntensities = [1, 128];
                                          final incorrectVibrationPatterns = [1, 100, 50, 100];
                                          final incorrectVibrationIntensities = [1, 128, 1, 128];
                                          if (question.type == QuestionType.sentence) {
                                            if (_answerController.text.isEmpty) {
                                              setState(() {
                                                _disabled = false;
                                              });
                                              return;
                                            }
                                            if (removePunctuation(_answerController.text.trim()).toLowerCase() == removePunctuation(question.correctAnswer.trim()).toLowerCase()) {
                                              if (hasVibrator) {
                                                if (hasAmplitude) {
                                                  Vibration.vibrate(
                                                    pattern: correctAnswerPatterns,
                                                    intensities: correctVibrationIntensities,
                                                  );
                                                } else {
                                                  Vibration.vibrate(
                                                    pattern: correctAnswerPatterns,
                                                  );
                                                }
                                              }
                                              setState(() {
                                                correct = true;
                                              });
                                              await player.play(AssetSource("audios/correct.mp3"));
                                              await _onCorrectAnswer(question.id == value.last.id, question.id, _answerController.text);
                                            } else {
                                              if (hasVibrator) {
                                                if (hasAmplitude) {
                                                  Vibration.vibrate(
                                                    pattern: incorrectVibrationPatterns,
                                                    intensities: incorrectVibrationIntensities,
                                                  );
                                                } else {
                                                  Vibration.vibrate(
                                                    pattern: incorrectVibrationPatterns,
                                                  );
                                                }
                                              }
                                              setState(() {
                                                correct = false;
                                              });
                                              await player.play(AssetSource("audios/incorrect.wav"));
                                              await _onIncorrectAnswer(
                                                removePunctuation(question.correctAnswer.trim()),
                                                _answerController.text.trim(),
                                                question.id,
                                                question.id == value.last.id,
                                              );
                                            }
                                          } else {
                                            if (_selectedStep.isEmpty) {
                                              {
                                                setState(() {
                                                  _disabled = false;
                                                });
                                                return;
                                              }
                                            }

                                            if (_selectedStep == question.correctAnswer) {
                                              print("correct answer");
                                              setState(() {
                                                correct = true;
                                              });

                                              if (hasVibrator) {
                                                if (hasAmplitude) {
                                                  Vibration.vibrate(
                                                    pattern: correctAnswerPatterns,
                                                    intensities: correctVibrationIntensities,
                                                  );
                                                } else {
                                                  Vibration.vibrate(
                                                    pattern: correctAnswerPatterns,
                                                  );
                                                }
                                              }

                                              await player.play(AssetSource("audios/correct.mp3"));
                                              await _onCorrectAnswer(
                                                question.id == value.last.id,
                                                question.id,
                                                _selectedStep,
                                              );
                                            } else {
                                              setState(() {
                                                correct = false;
                                              });
                                              if (hasVibrator) {
                                                if (hasAmplitude) {
                                                  Vibration.vibrate(
                                                    pattern: incorrectVibrationPatterns,
                                                    intensities: incorrectVibrationIntensities,
                                                  );
                                                } else {
                                                  Vibration.vibrate(
                                                    pattern: incorrectVibrationPatterns,
                                                  );
                                                }
                                              }
                                              await player.play(AssetSource("audios/incorrect.wav"));
                                              await _onIncorrectAnswer(
                                                question.correctAnswer,
                                                _selectedStep,
                                                question.id,
                                                question.id == value.last.id,
                                              );
                                            }
                                          }
                                          setState(() {
                                            _disabled = false;
                                          });
                                        },
                                        style: ButtonStyle(
                                          alignment: Alignment.center,
                                          foregroundColor: WidgetStateProperty.all(Colors.black),
                                          backgroundColor: WidgetStateProperty.all(
                                            question.type == QuestionType.select_one
                                                ? _selectedStep.isEmpty
                                                    ? Colors.grey.shade500
                                                    : PRIMARY_COLOR
                                                : _valueEntered == false
                                                    ? Colors.grey.shade500
                                                    : PRIMARY_COLOR,
                                          ),
                                          padding: WidgetStateProperty.resolveWith<EdgeInsetsGeometry>(
                                            (Set<WidgetState> states) {
                                              return const EdgeInsets.all(15);
                                            },
                                          ),
                                          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                          ),
                                        ),
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          transitionBuilder: (child, animation) {
                                            return ScaleTransition(scale: animation, child: child);
                                          },
                                          child: correct == true
                                              ? const Icon(
                                                  Icons.check_rounded,
                                                  color: Colors.green,
                                                  size: 21,
                                                )
                                              : correct == false
                                                  ? const Icon(
                                                      Icons.close,
                                                      color: Colors.red,
                                                      size: 21,
                                                    )
                                                  : Text(
                                                      "Check",
                                                      style: TextStyle(
                                                        fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }
}
