import 'dart:convert';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/components/circular_progress.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/learning_path.dart';
import 'package:app/models/lesson.dart';
import 'package:app/screens/loading/questions.dart';
import 'package:app/screens/questions/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:async_builder/async_builder.dart';
import 'package:shimmer/shimmer.dart';

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
                  title: BlocBuilder<UserBloc, UserState>(
                      bloc: userBloc,
                      builder: (context, state) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.network(
                              data.language.flagUrl,
                              width: 30,
                              height: 30,
                            ),
                            IconButton(
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
                                    state.lives.toString(),
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    "assets/images/emerald.png",
                                    width: 25,
                                    height: 25,
                                  ),
                                  const SizedBox(
                                    width: BASE_MARGIN * 2,
                                  ),
                                  Text(
                                    state.emeralds.toString(),
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
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
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                  centerTitle: true,
                  // actions: [
                  //   IconButton(
                  //     onPressed: () {},
                  //     icon: const Icon(
                  //       Icons.notifications_rounded,
                  //       size: 30,
                  //     ),
                  //   )
                  // ],
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
                      return ListView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: data.modules.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final module = data.modules[index];
                          final item = ListTile(
                            leading: CircularProgressAnimated(
                              maxItems: module.lessons.length.toDouble(),
                              currentItems: 0,
                            ),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                enableDrag: true,
                                showDragHandle: true,
                                builder: (BuildContext context) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: BASE_MARGIN * 3,
                                      vertical: BASE_MARGIN * 4,
                                    ),
                                    child: ListView(
                                      children: <Widget>[
                                        Text(
                                          module.name,
                                          style: TextStyle(
                                            fontSize: Theme.of(context).textTheme.titleLarge!.fontSize! * 0.85,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: BASE_MARGIN * 1,
                                        ),
                                        Text(
                                          module.description,
                                          style: Theme.of(context).textTheme.titleSmall,
                                        ),
                                        const SizedBox(
                                          height: BASE_MARGIN * 3,
                                        ),
                                        Text(
                                          "Lessons",
                                          style: TextStyle(
                                            fontSize: Theme.of(context).textTheme.titleLarge!.fontSize! * 0.8,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: BASE_MARGIN * 3,
                                        ),
                                        ListView.separated(
                                          separatorBuilder: (context, index) {
                                            return const SizedBox(
                                              height: BASE_MARGIN * 2,
                                            );
                                          },
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemBuilder: (context, index) {
                                            final lesson = module.lessons[index];
                                            return ListTile(
                                              title: Text(
                                                lesson.name,
                                              ),
                                              onTap: () {
                                                if (lesson.status == QuestionsStatus.generated) {
                                                  Navigator.of(context)
                                                      .push(
                                                    CupertinoPageRoute(
                                                      builder: (context) => QuestionsScreen(
                                                        lessonId: lesson.id,
                                                      ),
                                                    ),
                                                  )
                                                      .then(
                                                    (value) {
                                                      setState(() {
                                                        _fetchLearningPath = _fetchLearningPathFuture();
                                                      });
                                                    },
                                                  );
                                                } else {
                                                  Navigator.of(context)
                                                      .push(
                                                    CupertinoPageRoute(
                                                      builder: (context) => QuestionsGenerationLoadingScreen(
                                                        lessonId: lesson.id,
                                                        status: lesson.status,
                                                      ),
                                                    ),
                                                  )
                                                      .then(
                                                    (value) {
                                                      setState(() {
                                                        _fetchLearningPath = _fetchLearningPathFuture();
                                                      });
                                                    },
                                                  );
                                                }
                                              },
                                              subtitle: Text(
                                                "${lesson.questions} questions • ${(lesson.questions == 0 ? 1 : lesson.questions!) * 4} xp",
                                                style: TextStyle(
                                                  color: Theme.of(context).textTheme.titleSmall!.color,
                                                ),
                                              ),
                                              leading: CircularProgressAnimated(
                                                currentItems: lesson.questions!.toDouble(),
                                                maxItems: lesson.questions!.toDouble(),
                                              ),
                                              tileColor: SECONDARY_BG_COLOR,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(BASE_MARGIN * 2),
                                              ),
                                              enabled: true,
                                              trailing: SizedBox(
                                                width: 40,
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    Image.asset(
                                                      "assets/images/emerald.png",
                                                      width: 25,
                                                      height: 25,
                                                    ),
                                                    const SizedBox(
                                                      width: BASE_MARGIN * 1,
                                                    ),
                                                    Text(
                                                      "1",
                                                      style: Theme.of(context).textTheme.titleSmall,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                          shrinkWrap: true,
                                          itemCount: module.lessons.length,
                                        )
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            title: Text(
                              module.name,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              module.description,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          );
                          if (index == 0) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  height: BASE_MARGIN * 2,
                                ),
                                item
                              ],
                            );
                          }
                          return item;
                        },
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
