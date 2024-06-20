import 'dart:convert';
import 'dart:ui';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/components/bottom_bar.dart';
import 'package:app/components/circular_progress.dart';
import 'package:app/constants/main.dart';
import 'package:app/main.dart';
import 'package:app/models/learning_path.dart';
import 'package:app/screens/chat/main.dart';
import 'package:app/screens/generations/modules.dart';
import 'package:app/screens/lessons/main.dart';
import 'package:app/screens/profile/main.dart';
import 'package:app/screens/shop/main.dart';
import 'package:app/screens/streaks/main.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:heroicons/heroicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  int _currentIndex = 0;
  final streaksKey = GlobalKey();
  final emeraldsKey = GlobalKey();
  final livesKey = GlobalKey();
  List<TargetFocus> targets = [];

  @override
  void initState() {
    super.initState();
    _setUpPusher();
  }

  Future<void> _setupTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool("tutorial_shown");
    if (shown == null || !shown) {
      TutorialCoachMark tutorial = TutorialCoachMark(
        colorShadow: Colors.white,
        textSkip: "SKIP",
        alignSkip: Alignment.bottomCenter,
        textStyleSkip: const TextStyle(
          color: Colors.green,
        ),
        paddingFocus: 10,
        opacityShadow: 0.5,
        imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        targets: [
          TargetFocus(
            keyTarget: streaksKey,
            identify: "streaks",
            alignSkip: Alignment.topRight,
            enableOverlayTab: true,
            shape: ShapeLightFocus.RRect,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                builder: (context, controller) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Streaks",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                        ),
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 2,
                      ),
                      Text(
                        "Complete a lesson every day to keep your streak intact.",
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                        ),
                      )
                    ],
                  );
                },
              ),
            ],
          ),
          TargetFocus(
            keyTarget: emeraldsKey,
            identify: "emeralds",
            alignSkip: Alignment.topRight,
            enableOverlayTab: true,
            shape: ShapeLightFocus.RRect,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                builder: (context, controller) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Emeralds",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                        ),
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 2,
                      ),
                      Text(
                        "These are in app currency which you can use to buy lives and voice chat access.",
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                        ),
                      )
                    ],
                  );
                },
              ),
            ],
          ),
          TargetFocus(
            keyTarget: livesKey,
            identify: "lives",
            alignSkip: Alignment.topRight,
            enableOverlayTab: true,
            shape: ShapeLightFocus.RRect,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                builder: (context, controller) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Lives",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                        ),
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 2,
                      ),
                      Text(
                        "These determine how many mistakes you can make, but don't worry—if you run out of lives during a lesson, we won't stop you from completing it. ",
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                        ),
                      )
                    ],
                  );
                },
              ),
            ],
          ),
        ],
        onFinish: () async {
          final prefs = await SharedPreferences.getInstance();
          prefs.setBool("tutorial_shown", true);
        },
        onSkip: () {
          SharedPreferences.getInstance().then(
            (value) {
              value.setBool("tutorial_shown", true);
            },
          );
          return true;
        },
      );
      tutorial.show(context: context);
    }
  }

  Future<void> _setUpPusher() async {
    // await pusher.init(apiKey: PUSHER_API_KEY, cluster: PUSHER_CLUSTER);
    // await pusher.subscribe(
    //     channelName: 'modules',
    //     onEvent: (event) {
    //       if (context.read<UserBloc>().state.id == event.data) {
    //         QueryClient.of(context).refreshQuery('learning_path');
    //       }
    //     });
    // await pusher.connect();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(
      this,
      ModalRoute.of(context)!,
    );
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
    // pusher.disconnect().then(
    //       (value) {},
    //     );
  }

  @override
  void didPopNext() {
    QueryClient.of(context).refreshQuery('learning_path');
    QueryClient.of(context).refreshQuery('profile_stats');
    QueryClient.of(context).refreshQuery('chats');
  }

  Future<LearningPath> _fetchLearningPathFuture() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final req = await http.get(Uri.parse("$API_URL/onboarding"), headers: {"Authorization": "Bearer $token"});

    final body = await jsonDecode(req.body);
    await _setupTutorial();

    if (req.statusCode == 200) {
      return LearningPath.fromJSON(body);
    }
    throw 'Failed to load learning path';
  }

  @override
  Widget build(BuildContext context) {
    final userBloc = context.read<UserBloc>();
    return QueryBuilder<LearningPath, dynamic>(
      'learning_path',
      _fetchLearningPathFuture,
      initial: null,
      enabled: true,
      builder: (context, query) {
        if (query.isLoading) {
          return Scaffold(
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
          );
        } else if (query.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Text(query.error.toString()),
              ),
            ),
          );
        }
        final data = query.data;
        if (data == null) {
          return const Scaffold(
            body: SafeArea(
              child: Center(
                child: null,
              ),
            ),
          );
        }
        if (_currentIndex == 3) {
          return Scaffold(
            body: const ProfileScreen(),
            bottomNavigationBar: BottomBar(
              currentIndex: _currentIndex,
              onPress: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          );
        } else if (_currentIndex == 2) {
          return Scaffold(
            body: const ChatsScreen(),
            bottomNavigationBar: BottomBar(
              currentIndex: _currentIndex,
              onPress: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          );
        }
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
                    height: 2.0,
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
                            key: streaksKey,
                            onPressed: () {
                              Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (context) {
                                    return const StreaksScreen();
                                  },
                                ),
                              );
                            },
                            icon: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                HeroIcon(
                                  HeroIcons.bolt,
                                  color: PRIMARY_COLOR,
                                  size: 30,
                                  style: state.isStreakActive ? HeroIconStyle.solid : HeroIconStyle.outline,
                                ),
                                const SizedBox(
                                  width: BASE_MARGIN * 2,
                                ),
                                Text(
                                  state.streaks.toString(),
                                  style: TextStyle(
                                    fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            key: emeraldsKey,
                            onPressed: () {
                              Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (context) {
                                    return ShopScreen();
                                  },
                                ),
                              );
                            },
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
                                  style: TextStyle(
                                    fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            key: livesKey,
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                enableDrag: true,
                                showDragHandle: true,
                                builder: (context) {
                                  final userBloc = context.read<UserBloc>();
                                  final userState = userBloc.state;
                                  return StatefulBuilder(
                                    builder: (context, setState) {
                                      return Padding(
                                        padding: const EdgeInsets.all(BASE_MARGIN * 2),
                                        child: Column(
                                          children: [
                                            const SizedBox(
                                              height: BASE_MARGIN * 2,
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: List.generate(5, (index) {
                                                return index < userState.lives
                                                    ? Padding(
                                                        padding: EdgeInsets.symmetric(
                                                          horizontal: BASE_MARGIN.toDouble(),
                                                        ),
                                                        child: SvgPicture.asset(
                                                          "assets/svgs/heart.svg",
                                                          width: 30,
                                                          height: 30,
                                                        ),
                                                      )
                                                    : Padding(
                                                        padding: EdgeInsets.symmetric(
                                                          horizontal: BASE_MARGIN.toDouble(),
                                                        ),
                                                        child: const Icon(
                                                          Icons.favorite,
                                                          color: Colors.grey,
                                                          size: 30,
                                                        ),
                                                      );
                                              }),
                                            ),
                                            const SizedBox(
                                              height: BASE_MARGIN * 4,
                                            ),
                                            Text(
                                              userState.lives >= 5 ? "You have full lives" : "You have ${userState.lives} ${userState.lives == 1 ? "life" : "lives"}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: BASE_MARGIN * 4,
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                if (userState.lives >= 5) return;
                                              },
                                              style: ButtonStyle(
                                                backgroundColor: userState.lives < 5
                                                    ? WidgetStateProperty.all(
                                                        SECONDARY_BG_COLOR,
                                                      )
                                                    : WidgetStateProperty.all(
                                                        Colors.grey.shade500,
                                                      ),
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
                                              child: Row(
                                                children: [
                                                  SvgPicture.asset(
                                                    "assets/svgs/heart.svg",
                                                    width: 25,
                                                    height: 25,
                                                    colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                                                  ),
                                                  const SizedBox(
                                                    width: BASE_MARGIN * 2,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      "Refill lives",
                                                      style: TextStyle(
                                                        fontSize: Theme.of(context).textTheme.titleSmall!.fontSize!,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  ColorFiltered(
                                                    colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                                                    child: Image.asset(
                                                      "assets/images/emerald.png",
                                                      width: 25,
                                                      height: 25,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: BASE_MARGIN * 2,
                                                  ),
                                                  Text(
                                                    userState.lives >= 5 ? "20" : ((5 - userState.lives) * 4).toString(),
                                                    style: TextStyle(
                                                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize!,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(
                                              height: BASE_MARGIN * 4,
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                if (userState.lives >= 5) return;
                                              },
                                              style: ButtonStyle(
                                                backgroundColor: userState.lives < 5
                                                    ? WidgetStateProperty.all(
                                                        SECONDARY_BG_COLOR,
                                                      )
                                                    : WidgetStateProperty.all(
                                                        Colors.grey.shade500,
                                                      ),
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
                                              child: Row(
                                                children: [
                                                  SvgPicture.asset(
                                                    "assets/svgs/heart.svg",
                                                    width: 25,
                                                    height: 25,
                                                    colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                                                  ),
                                                  const SizedBox(
                                                    width: BASE_MARGIN * 2,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      "Refill 1 life",
                                                      style: TextStyle(
                                                        fontSize: Theme.of(context).textTheme.titleSmall!.fontSize!,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  ColorFiltered(
                                                    colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                                                    child: Image.asset(
                                                      "assets/images/emerald.png",
                                                      width: 25,
                                                      height: 25,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: BASE_MARGIN * 2,
                                                  ),
                                                  Text(
                                                    "4",
                                                    style: TextStyle(
                                                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize!,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
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
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                centerTitle: true,
              ),
              bottomNavigationBar: BottomBar(
                currentIndex: _currentIndex,
                onPress: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
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
                            key: Key(module.id),
                            maxItems: module.lessons.length.toDouble(),
                            currentItems: module.lessons.where((lesson) => lesson.completed).length.toDouble(),
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) {
                                  return LessonsListScreen(module: module);
                                },
                              ),
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
                        if (index == data.modules.length - 1) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              item,
                              const SizedBox(
                                height: BASE_MARGIN * 2,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(
                                  BASE_MARGIN * 4,
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      CupertinoPageRoute(
                                        builder: (context) {
                                          return const GenerationsScreen(
                                            type: "modules",
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  style: ButtonStyle(
                                    alignment: Alignment.center,
                                    foregroundColor: WidgetStateProperty.all(Colors.black),
                                    backgroundColor: WidgetStateProperty.all(SECONDARY_BG_COLOR),
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
                                    "Generate more",
                                  ),
                                ),
                              ),
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
      },
    );
  }
}
