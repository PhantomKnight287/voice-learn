import 'dart:convert';

import 'package:app/constants/main.dart';
import 'package:app/models/language.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  int _maxSteps = 4;
  late Future<List<Language>> _languagesFuture;
  bool _loading = false;
  String _selectedLanguage = "";

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
    return body.map<Language>((dynamic lang) => Language.fromJSON(lang)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
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
          ];
        },
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
                    print(value);
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
                          return Expanded(
                            child: ListView.separated(
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
                                  splashColor: Colors.transparent,
                                  onTap: () {
                                    setState(() {
                                      _selectedLanguage = language.id;
                                    });
                                  },
                                  tileColor: _selectedLanguage == language.id ? Colors.green.shade500 : SECONDARY_BG_COLOR,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  title: Text(
                                    language.name,
                                    style: TextStyle(
                                      color: _selectedLanguage == language.id ? Colors.white : Theme.of(context).textTheme.titleSmall!.color,
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
                            ),
                          );
                        }
                      },
                    ),
                    Text("hello")
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
                      _pageController.nextPage(duration: Duration(microseconds: 500), curve: Curves.linear);
                      setState(() {
                        _currentStep++;
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
                      backgroundColor: _currentStep == 1
                          ? _selectedLanguage.isNotEmpty
                              ? null
                              : WidgetStateProperty.all(
                                  const Color(0x0ffFFDF80),
                                )
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
                            "Continue",
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
      ),
    );
  }
}
