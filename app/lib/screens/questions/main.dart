import 'dart:convert';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/question.dart';
import 'package:app/screens/questions/complete.dart';
import 'package:app/utils/string.dart';
import 'package:async_builder/async_builder.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

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
        headers: {"Authorization": "Bearer $token"});
    final body = jsonDecode(req.body);
    _getLanguages(body['locale']);
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
        (value) {
          if (last) {
            Navigator.of(context).pushReplacement(
              CupertinoPageRoute(
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
    bool submitted = false;
    userBloc.add(
      DecreaseUserHeartEvent(
        id: state.id,
        name: state.name,
        createdAt: state.createdAt,
        paths: state.paths,
        updatedAt: state.updatedAt,
        token: state.token,
        emeralds: state.emeralds,
        lives: state.lives - 1,
        xp: state.xp,
        streaks: state.streaks,
      ),
    );
    _submitAnswer(questionId, yourAnswer, last).then(
      (value) {
        if (last) {
          submitted = true;
        }
      },
    );
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
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
                    fontSize: Theme.of(context).textTheme.titleMedium!.fontSize! * 0.7,
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
                    fontSize: Theme.of(context).textTheme.titleMedium!.fontSize! * 0.7,
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
                        CupertinoPageRoute(
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
      final req = await http.post(
        Uri.parse("$API_URL/questions/$questionId/answer"),
        headers: {"Authorization": "Bearer $token", "Content-type": "application/json"},
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
      print(body);

      if (req.statusCode == 201) {
        userBloc.add(
          DecreaseUserHeartEvent(
            id: state.id,
            name: state.name,
            createdAt: state.createdAt,
            paths: state.paths,
            updatedAt: state.updatedAt,
            token: state.token,
            emeralds: body['emeralds'],
            lives: body['lives'],
            xp: body['xp'],
            streaks: body['streaks'] ?? last == true ? state.streaks + 1 : state.streaks,
            isStreakActive: body['isStreakActive'] ?? state.isStreakActive,
          ),
        );
      } else {}
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchQuestions = _fetchQuestionsFuture();
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
                  highlightColor: SECONDARY_BG_COLOR,
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
                    highlightColor: SECONDARY_BG_COLOR,
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
                              color: Colors.grey.shade300,
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
                          children: [
                            SvgPicture.asset(
                              "assets/svgs/heart.svg",
                              width: 25,
                              height: 25,
                            ),
                            const SizedBox(
                              width: BASE_MARGIN * 2,
                            ),
                            Text(
                              state.lives.toString(),
                              style: TextStyle(
                                fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
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
                                  if (ttsSetup)
                                    IconButton(
                                      onPressed: () async {
                                        await flutterTts.speak(question.question.map((q) => q.word).join(" "));
                                      },
                                      icon: const HeroIcon(
                                        HeroIcons.speakerWave,
                                      ),
                                    ),
                                  for (var word in question.question) ...{
                                    Tooltip(
                                      message: word.translation,
                                      triggerMode: TooltipTriggerMode.tap,
                                      onTriggered: () async {
                                        if (ttsSetup == false) return;
                                        await flutterTts.speak(word.word);
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
                                        fillColor: SECONDARY_BG_COLOR,
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
                                  itemBuilder: (context, index) {
                                    final option = question.options[index];
                                    return ListTile(
                                      title: Text(option),
                                      tileColor: SECONDARY_BG_COLOR,
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
                                            : BorderSide.none,
                                      ),
                                      enableFeedback: true,
                                      enabled: true,
                                      onTap: () async {
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
                              ElevatedButton(
                                onPressed: () async {
                                  if (question.type == QuestionType.sentence) {
                                    if (_answerController.text.isEmpty) return;
                                    if (removePunctuation(_answerController.text.trim()).toLowerCase() == removePunctuation(question.correctAnswer.trim()).toLowerCase()) {
                                      setState(() {
                                        correct = true;
                                      });
                                      await player.play(AssetSource("audios/correct.mp3"));
                                      await _onCorrectAnswer(question.id == value.last.id, question.id, _answerController.text);
                                    } else {
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
                                    if (_selectedStep.isEmpty) return;

                                    if (_selectedStep == question.correctAnswer) {
                                      setState(() {
                                        correct = true;
                                      });
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
                                      await player.play(AssetSource("audios/incorrect.wav"));
                                      await _onIncorrectAnswer(
                                        question.correctAnswer,
                                        _selectedStep,
                                        question.id,
                                        question.id == value.last.id,
                                      );
                                    }
                                  }
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
                                        )
                                      : correct == false
                                          ? const Icon(
                                              Icons.close,
                                              color: Colors.red,
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
