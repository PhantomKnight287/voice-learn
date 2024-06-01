import 'dart:convert';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/learning_path.dart';
import 'package:app/screens/loading/questions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:async_builder/async_builder.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_stepper/easy_stepper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late Future<LearningPath> _fetchLearningPath;

  @override
  void initState() {
    super.initState();
    _fetchLearningPath = _fetchLearningPathFuture();
  }

  Future<LearningPath> _fetchLearningPathFuture() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final req = await http.get(Uri.parse("$API_URL/onboarding"), headers: {"Authorization": "Bearer $token"});

    final body = await jsonDecode(req.body);
    if (req.statusCode == 200) {
      return LearningPath.fromJSON(body);
    }
    throw 'Failed to load learning path';
  }

  @override
  Widget build(BuildContext context) {
    final userBloc = context.read<UserBloc>();
    return AsyncBuilder<LearningPath>(
        future: _fetchLearningPath,
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
        error: (context, error, stackTrace) => Scaffold(
              body: SafeArea(
                child: Center(
                  child: Text(error.toString()),
                ),
              ),
            ),
        builder: (context, value) {
          final data = value!;
          return Stack(
            children: [
              Scaffold(
                extendBodyBehindAppBar: true,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  scrolledUnderElevation: 0.0,
                  systemOverlayStyle: SystemUiOverlayStyle.dark,
                  elevation: 0,
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(4.0),
                    child: Container(
                      color: PRIMARY_COLOR,
                      height: 1.0,
                    ),
                  ),
                  leading: Padding(
                    padding: const EdgeInsets.all(BASE_MARGIN * 2.5),
                    child: Image.network(
                      data.language.flagUrl,
                      width: 30,
                      height: 30,
                    ),
                  ),
                  title: IconButton(
                    onPressed: () {},
                    icon: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.bolt,
                          color: PRIMARY_COLOR,
                          size: 30,
                        ),
                        Text(
                          "69",
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_rounded,
                        size: 30,
                      ),
                    )
                  ],
                ),
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (value) => {
                    setState(() {
                      _currentIndex = value;
                    })
                  },
                  selectedItemColor: PRIMARY_COLOR,
                  type: BottomNavigationBarType.fixed,
                  selectedLabelStyle: const TextStyle(
                    color: Colors.black,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    color: Colors.black,
                  ),
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.home_rounded,
                      ),
                      label: "Home",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.leaderboard_rounded,
                      ),
                      label: "Leaderboard",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.chat_rounded,
                      ),
                      label: "Chat",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.person_rounded,
                      ),
                      label: "Profile",
                    )
                  ],
                ),
                body: SafeArea(
                  child: BlocBuilder<UserBloc, UserState>(
                    bloc: userBloc,
                    builder: (context, state) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(BASE_MARGIN * 4, 0, BASE_MARGIN * 4, BASE_MARGIN * 4),
                        child: ListView.builder(
                          scrollDirection: Axis.vertical,
                          itemCount: data.modules.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            final module = data.modules[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (index == 0)
                                  const SizedBox(
                                    height: BASE_MARGIN * 4,
                                  ),
                                Text(
                                  module.name,
                                  style: TextStyle(
                                    fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(
                                  height: BASE_MARGIN.toDouble(),
                                ),
                                Text(
                                  "${module.lessons.length} lesson${module.lessons.length > 1 ? "s" : ""}",
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.titleSmall!.color,
                                  ),
                                ),
                                SizedBox(
                                  height: BASE_MARGIN.toDouble(),
                                ),
                                Theme(
                                  data: ThemeData(
                                    colorScheme: Theme.of(context).colorScheme.copyWith(
                                          primary: PRIMARY_COLOR,
                                        ),
                                  ),
                                  child: Stepper(
                                    onStepTapped: (value) {
                                      Navigator.of(context).push(
                                        CupertinoPageRoute(
                                          builder: (context) => QuestionsGenerationLoadingScreen(
                                            lessonId: module.lessons[value]!.id,
                                          ),
                                        ),
                                      );
                                    },
                                    connectorColor: WidgetStateProperty.all(PRIMARY_COLOR),
                                    connectorThickness: 2,
                                    currentStep: 1,
                                    controlsBuilder: (BuildContext context, ControlsDetails controls) {
                                      return Row(
                                        children: <Widget>[
                                          Container(),
                                        ],
                                      );
                                    },
                                    physics: const NeverScrollableScrollPhysics(),
                                    steps: module.lessons
                                        .map(
                                          (e) => Step(
                                            title: Text(
                                              e.name,
                                            ),
                                            // content: SizedBox(),
                                            content: Container(
                                              alignment: Alignment.bottomLeft,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  if (e.description != null)
                                                    Text(
                                                      e.description!,
                                                    ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "${e.questions} questions • ${(e.questions == 0 ? 1 : e.questions!) * 4} xp",
                                                        style: TextStyle(
                                                          color: Theme.of(context).textTheme.titleSmall!.color,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // subtitle: e.description != null ? Text(e.description!) : null,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        });
  }
}
