import 'dart:convert';

import 'package:app/constants/main.dart';
import 'package:app/models/language.dart';
import 'package:app/models/knowledge.dart';
import 'package:app/models/reason.dart';
import 'package:app/screens/loading/learning.dart';
import 'package:app/utils/error.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingQuestionsScreen extends StatefulWidget {
  const OnboardingQuestionsScreen({
    super.key,
  });

  @override
  State<OnboardingQuestionsScreen> createState() => _OnboardingQuestionsScreenState();
}

class _OnboardingQuestionsScreenState extends State<OnboardingQuestionsScreen> with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentStep = 1;
  final int _maxSteps = 4;
  late Future<List<Language>> _languagesFuture;
  bool _loading = false;
  String _selectedLanguageId = "";
  List<Language> languages = [];
  Language? _selectedLanguage;
  Knowledge? _selectedKnowledge;
  Reason? _selectedReason;
  Reason? _hearAbout;

  final disabledButtonColor = WidgetStateProperty.all(
    const Color(0xffffdf80),
  );

  List<Knowledge> _getKnowledge(String languageName) {
    return [
      Knowledge(
        message: "I'm completely new to $languageName",
        icon: SvgPicture.asset("assets/svgs/new.svg"),
      ),
      Knowledge(
        message: "I know some words and phrases",
        icon: SvgPicture.asset("assets/svgs/beginner.svg"),
      ),
      Knowledge(
        message: "I can have simple conversations",
        icon: SvgPicture.asset("assets/svgs/intermediate.svg"),
      ),
      Knowledge(
        message: "I am intermediate or higher",
        icon: SvgPicture.asset("assets/svgs/expert.svg"),
      ),
    ].toList();
  }

  List<Reason> _getReasons() {
    return [
      Reason(
        icon: SvgPicture.asset("assets/svgs/fun.svg"),
        reason: "Just for fun",
      ),
      Reason(
        reason: "Connect with people",
        icon: SvgPicture.asset("assets/svgs/people.svg"),
      ),
      Reason(
        reason: "For my education",
        icon: SvgPicture.asset("assets/svgs/study.svg"),
      ),
      Reason(
        reason: "Prepare for travel",
        icon: SvgPicture.asset("assets/svgs/plane.svg"),
      ),
      Reason(
        reason: "For my career",
        icon: SvgPicture.asset("assets/svgs/career.svg"),
      ),
      Reason(
        reason: "Other",
        icon: SvgPicture.asset("assets/svgs/other.svg"),
      ),
    ].toList();
  }

  List<Reason> _getHearAbout() {
    return [
      Reason(
        icon: SvgPicture.asset("assets/svgs/website.svg"),
        reason: "VoiceLearn.tech",
      ),
      Reason(
        reason: "Friends",
        icon: SvgPicture.asset("assets/svgs/people.svg"),
      ),
      Reason(
        reason: "App Store",
        icon: SvgPicture.asset("assets/svgs/google-play.svg"),
      ),
      Reason(
        reason: "News/article/blog",
        icon: SvgPicture.asset("assets/svgs/news.svg"),
      ),
      Reason(
        reason: "For my career",
        icon: SvgPicture.asset("assets/svgs/career.svg"),
      ),
      Reason(
        reason: "Other",
        icon: SvgPicture.asset("assets/svgs/other.svg"),
      ),
    ].toList();
  }

  @override
  void initState() {
    super.initState();
    _languagesFuture = _fetchLanguages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<List<Language>> _fetchLanguages() async {
    final req = await http.get(
      Uri.parse('$API_URL/languages'),
    );
    final body = await jsonDecode(req.body);
    final res = body.map<Language>((dynamic lang) => Language.fromJSON(lang)).toList();
    setState(() {
      languages = res;
    });
    return res;
  }

  void _completeOnBoarding() async {
    setState(() {
      _loading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token")!;

    final req = await http.post(Uri.parse("$API_URL/onboarding"),
        body: jsonEncode({
          "reason": _selectedReason?.reason,
          "languageId": _selectedLanguageId,
          "knowledge": _selectedKnowledge?.message,
          "analytics": _hearAbout?.reason,
        }),
        headers: {
          "authorization": "Bearer $token",
          "content-type": "application/json",
        });
    final body = jsonDecode(req.body);
    setState(() {
      _loading = false;
    });
    if (req.statusCode != 201) {
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("An Error Occurred"),
        description: Text(
          ApiResponseHelper.getErrorMessage(body),
        ),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(
        builder: (context) => LearningPathLoadingScreen(
          pathId: body['id'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        excludeHeaderSemantics: true,
        title: LayoutBuilder(builder: (context, constraints) {
          return Stack(
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
                width: (_currentStep / _maxSteps) * constraints.maxWidth,
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
          );
        }),
        leading: _currentStep > 1
            ? GestureDetector(
                onTap: () {
                  if (_currentStep == 0) return;
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.linear,
                  );
                  setState(() {
                    _currentStep--;
                  });
                },
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: _currentStep == 0 ? Colors.transparent : null,
                ),
              )
            : null,
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BASE_MARGIN * 4,
              0,
              BASE_MARGIN * 4,
              0,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: PageView(
                onPageChanged: (value) {
                  setState(() {
                    _currentStep = value + 1;
                  });
                },
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  FutureBuilder(
                    future: _languagesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No languages found.'));
                      } else {
                        final languages = snapshot.data!;

                        return ListView.separated(
                          separatorBuilder: (context, index) {
                            return const SizedBox(
                              height: BASE_MARGIN * 4,
                            );
                          },
                          shrinkWrap: true,
                          itemCount: languages.length,
                          padding: const EdgeInsets.all(0),
                          itemBuilder: (context, index) {
                            final language = languages[index];
                            final tile = ListTile(
                              onTap: () {
                                setState(() {
                                  _selectedLanguageId = language.id;
                                  _selectedLanguage = language;
                                });
                              },
                              splashColor: Colors.transparent,
                              tileColor: SECONDARY_BG_COLOR,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: _selectedLanguageId == language.id
                                    ? BorderSide(
                                        color: Colors.green.shade500,
                                        strokeAlign: 2,
                                        style: BorderStyle.solid,
                                        width: 2,
                                      )
                                    : BorderSide.none,
                              ),
                              title: Text(
                                language.name,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                ),
                              ),
                              leading: Image.network(
                                language.flagUrl,
                                width: 50,
                                height: 50,
                              ),
                            );
                            if (index == 0) {
                              return Column(
                                children: [
                                  Text(
                                    "What would you like to learn?",
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(
                                    height: BASE_MARGIN * 6,
                                  ),
                                  tile
                                ],
                              );
                            }
                            if (index == snapshot.data!.length - 1) {
                              return Column(
                                children: [
                                  tile,
                                  const SizedBox(
                                    height: 100,
                                  ),
                                ],
                              );
                            }
                            return tile;
                          },
                        );
                      }
                    },
                  ),
                  Column(
                    children: [
                      Text(
                        "How much ${_selectedLanguage?.name} do you know?",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 4,
                      ),
                      for (var item in _getKnowledge(_selectedLanguage?.name ?? "")) ...[
                        ListTile(
                          title: Text(
                            item.message,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                            ),
                          ),
                          leading: item.icon,
                          onTap: () {
                            setState(() {
                              _selectedKnowledge = item;
                            });
                          },
                          splashColor: Colors.transparent,
                          tileColor: SECONDARY_BG_COLOR,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: _selectedKnowledge?.message == item.message
                                ? BorderSide(
                                    color: Colors.green.shade500,
                                    strokeAlign: 2,
                                    style: BorderStyle.solid,
                                    width: 2,
                                  )
                                : BorderSide.none,
                          ),
                        ),
                        const SizedBox(
                          height: BASE_MARGIN * 4,
                        ),
                      ],
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        "Why are you learning ${_selectedLanguage?.name}?",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 4,
                      ),
                      for (var item in _getReasons()) ...[
                        ListTile(
                          title: Text(
                            item.reason,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                            ),
                          ),
                          leading: SizedBox(
                            height: 40,
                            width: 50,
                            child: item.icon,
                          ),
                          onTap: () {
                            setState(() {
                              _selectedReason = item;
                            });
                          },
                          splashColor: Colors.transparent,
                          tileColor: SECONDARY_BG_COLOR,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: _selectedReason?.reason == item.reason
                                ? BorderSide(
                                    color: Colors.green.shade500,
                                    strokeAlign: 2,
                                    style: BorderStyle.solid,
                                    width: 2,
                                  )
                                : BorderSide.none,
                          ),
                        ),
                        const SizedBox(
                          height: BASE_MARGIN * 4,
                        ),
                      ],
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        "How did you hear about Voice Learn?",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 4,
                      ),
                      for (var item in _getHearAbout()) ...[
                        ListTile(
                          title: Text(
                            item.reason,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                            ),
                          ),
                          leading: SizedBox(
                            height: 40,
                            width: 50,
                            child: item.icon,
                          ),
                          onTap: () {
                            setState(() {
                              _hearAbout = item;
                            });
                          },
                          splashColor: Colors.transparent,
                          tileColor: SECONDARY_BG_COLOR,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: _hearAbout?.reason == item.reason
                                ? BorderSide(
                                    color: Colors.green.shade500,
                                    strokeAlign: 2,
                                    style: BorderStyle.solid,
                                    width: 2,
                                  )
                                : BorderSide.none,
                          ),
                        ),
                        const SizedBox(
                          height: BASE_MARGIN * 4,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: SECONDARY_TEXT_COLOR,
                  blurRadius: 5,
                  blurStyle: BlurStyle.outer,
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(BASE_MARGIN * 2),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentStep == 1 && _selectedLanguageId.isEmpty) {
                      return;
                    }
                    if (_currentStep == 2 && _selectedKnowledge == null) {
                      return;
                    }
                    if (_currentStep == 3 && _selectedReason == null) {
                      return;
                    }
                    if (_currentStep == 4) {
                      if (_hearAbout == null) {
                        return;
                      } else {
                        _completeOnBoarding();
                      }
                    }
                    if (_currentStep < 4) {
                      _pageController.nextPage(duration: const Duration(microseconds: 500), curve: Curves.linear);
                      setState(() {
                        _currentStep++;
                      });
                    }
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
                    backgroundColor: (_currentStep == 1 && _selectedLanguageId.isEmpty)
                        ? disabledButtonColor
                        : (_currentStep == 2 && _selectedKnowledge == null)
                            ? disabledButtonColor
                            : (_currentStep == 3 && _selectedReason == null)
                                ? disabledButtonColor
                                : null,
                  ),
                  child: _loading
                      ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          _currentStep == 4 ? "Complete" : "Continue",
                          style: TextStyle(
                            fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
