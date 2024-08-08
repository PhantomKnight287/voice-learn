import 'dart:convert';
import 'dart:ui';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/components/bottom_bar.dart';
import 'package:app/components/circular_progress.dart';
import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/handler/switcher.dart';
import 'package:app/main.dart';
import 'package:app/models/learning_path.dart';
import 'package:app/models/user.dart';
import 'package:app/screens/chat/main.dart';
import 'package:app/screens/generations/modules.dart';
import 'package:app/screens/leaderboards/main.dart';
import 'package:app/screens/lessons/main.dart';
import 'package:app/screens/profile/main.dart';
import 'package:app/screens/recall/main.dart';
import 'package:app/screens/shop/main.dart';
import 'package:app/screens/streaks/main.dart';
import 'package:app/utils/error.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:heroicons/heroicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:toastification/toastification.dart';
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
  bool buyOneLifeButtonLoading = false;
  bool refillLivesButtonLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<bool> _buyOneLife() async {
    final userBloc = context.read<UserBloc>();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final req = await http.post(
      Uri.parse(
        "$API_URL/lives/add-one",
      ),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    final body = jsonDecode(req.body);
    if (req.statusCode != 200) {
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
      return false;
    }
    final userState = userBloc.state;
    userBloc.add(UserLoggedInEvent.setEmeraldsAndLives(userState, body['emeralds'], body['lives']));
    return true;
  }

  Future<bool> _refillLives() async {
    final userBloc = context.read<UserBloc>();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final req = await http.post(
      Uri.parse(
        "$API_URL/lives/refill",
      ),
      headers: {"Authorization": "Bearer $token"},
    );
    final body = jsonDecode(req.body);
    if (req.statusCode != 200) {
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
      return false;
    }
    final userState = userBloc.state;
    userBloc.add(UserLoggedInEvent.setEmeraldsAndLives(userState, body['emeralds'], body['lives']));
    return true;
  }

  Future<void> _setupTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final req = await http.get(
      Uri.parse("$API_URL/tutorials"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    final body = await jsonDecode(req.body);
    bool shown = true;
    if (req.statusCode == 200) {
      shown = body['homeScreenTutorialShown'];
    }
    final olderShown = prefs.getBool("tutorial_shown");
    if (olderShown == true) {
      await http.put(
        Uri.parse(
          "$API_URL/tutorials/home",
        ),
        headers: {"Authorization": "Bearer $token"},
      );
      return;
    }
    if (!shown) {
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
            alignSkip: Alignment.topLeft,
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
          await http.put(
              Uri.parse(
                "$API_URL/tutorials/home",
              ),
              headers: {"Authorization": "Bearer $token"});
        },
        onSkip: () {
          http.put(
              Uri.parse(
                "$API_URL/tutorials/home",
              ),
              headers: {"Authorization": "Bearer $token"}).then(
            (value) {},
          );
          return true;
        },
      );
      if (mounted) {
        tutorial.show(context: context);
      }
    }
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
      refreshConfig: RefreshConfig.withDefaults(
        context,
        refreshOnMount: true,
      ),
      builder: (context, query) {
        if (query.isLoading) {
          return const Scaffold(
            appBar: null,
            body: Center(
              child: VoiceLearnLoading(),
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
        if (_currentIndex == 4) {
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
        } else if (_currentIndex == 3) {
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
        } else if (_currentIndex == 2) {
          return Scaffold(
            body: const LeaderBoardScreen(),
            bottomNavigationBar: BottomBar(
              currentIndex: _currentIndex,
              onPress: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          );
        } else if (_currentIndex == 1) {
          return Scaffold(
            body: const RecallScreen(),
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
              appBar: AppBar(
                scrolledUnderElevation: 0.0,
                forceMaterialTransparency: false,
                elevation: 0,
                toolbarHeight: 60,
                bottom: BOTTOM(context),
                title: BlocBuilder<UserBloc, UserState>(
                    bloc: userBloc,
                    builder: (context, state) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CachedNetworkImage(
                            imageUrl: data.language.flagUrl,
                            progressIndicatorBuilder: (context, url, progress) {
                              return const CircularProgressIndicator.adaptive();
                            },
                            width: 30,
                            height: 30,
                          ),
                          IconButton(
                            key: streaksKey,
                            onPressed: () {
                              Navigator.of(context).push(
                                NoSwipePageRoute(
                                  builder: (context) {
                                    return const StreaksScreen();
                                  },
                                ),
                              );
                            },
                            icon: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Hero(
                                  tag: "bolt",
                                  child: HeroIcon(
                                    HeroIcons.bolt,
                                    color: PRIMARY_COLOR,
                                    size: 30,
                                    style: state.isStreakActive ? HeroIconStyle.solid : HeroIconStyle.outline,
                                  ),
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
                                NoSwipePageRoute(
                                  builder: (context) {
                                    return const ShopScreen();
                                  },
                                ),
                              );
                            },
                            icon: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Hero(
                                  tag: "emerald",
                                  child: SvgPicture.asset(
                                    "assets/images/emerald.svg",
                                    width: 25,
                                    height: 25,
                                  ),
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
                              if (state.tier == Tiers.premium) return;
                              showModalBottomSheet(
                                context: context,
                                enableDrag: true,
                                showDragHandle: true,
                                builder: (context) {
                                  return StatefulBuilder(
                                    builder: (context, setState) {
                                      final bloc = context.read<UserBloc>();
                                      final state = bloc.state;
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
                                                return index < state.lives
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
                                              state.lives >= 5 ? "You have full lives" : "You have ${state.lives} ${state.lives == 1 ? "life" : "lives"}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: BASE_MARGIN * 4,
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                if (state.lives >= 5) return;
                                                setState(() {
                                                  refillLivesButtonLoading = true;
                                                });
                                                await _refillLives();
                                                setState(() {
                                                  refillLivesButtonLoading = false;
                                                });
                                              },
                                              style: ButtonStyle(
                                                backgroundColor: state.lives < 5
                                                    ? WidgetStateProperty.all(
                                                        getSecondaryColor(context),
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
                                              child: refillLivesButtonLoading
                                                  ? Container(
                                                      width: 24,
                                                      height: 24,
                                                      padding: const EdgeInsets.all(2.0),
                                                      child: const CupertinoActivityIndicator(
                                                        animating: true,
                                                        radius: 20,
                                                      ),
                                                    )
                                                  : Row(
                                                      children: [
                                                        SvgPicture.asset(
                                                          "assets/svgs/heart.svg",
                                                          width: 25,
                                                          height: 25,
                                                          colorFilter: state.lives > 5 ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) : null,
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
                                                              color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                                                            ),
                                                          ),
                                                        ),
                                                        state.lives > 5
                                                            ? ColorFiltered(
                                                                colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                                                                child: SvgPicture.asset(
                                                                  "assets/images/emerald.svg",
                                                                  width: 25,
                                                                  height: 25,
                                                                ),
                                                              )
                                                            : SvgPicture.asset(
                                                                "assets/images/emerald.svg",
                                                                width: 25,
                                                                height: 25,
                                                              ),
                                                        const SizedBox(
                                                          width: BASE_MARGIN * 2,
                                                        ),
                                                        Text(
                                                          state.lives >= 5 ? "20" : ((5 - state.lives) * 4).toString(),
                                                          style: TextStyle(
                                                            fontSize: Theme.of(context).textTheme.titleSmall!.fontSize!,
                                                            fontWeight: FontWeight.w600,
                                                            color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                            const SizedBox(
                                              height: BASE_MARGIN * 4,
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                if (state.lives >= 5) return;
                                                if (state.lives >= 5) return;
                                                setState(() {
                                                  buyOneLifeButtonLoading = true;
                                                });
                                                await _buyOneLife();
                                                setState(() {
                                                  buyOneLifeButtonLoading = false;
                                                });
                                              },
                                              style: ButtonStyle(
                                                backgroundColor: state.lives < 5
                                                    ? WidgetStateProperty.all(
                                                        getSecondaryColor(context),
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
                                              child: buyOneLifeButtonLoading
                                                  ? Container(
                                                      width: 24,
                                                      height: 24,
                                                      padding: const EdgeInsets.all(2.0),
                                                      child: const CupertinoActivityIndicator(
                                                        animating: true,
                                                        radius: 20,
                                                      ),
                                                    )
                                                  : Row(
                                                      children: [
                                                        SvgPicture.asset(
                                                          "assets/svgs/heart.svg",
                                                          width: 25,
                                                          height: 25,
                                                          colorFilter: state.lives > 5 ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) : null,
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
                                                              color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                                                            ),
                                                          ),
                                                        ),
                                                        state.lives > 5
                                                            ? ColorFiltered(
                                                                colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                                                                child: SvgPicture.asset(
                                                                  "assets/images/emerald.svg",
                                                                  width: 25,
                                                                  height: 25,
                                                                ),
                                                              )
                                                            : SvgPicture.asset(
                                                                "assets/images/emerald.svg",
                                                                width: 25,
                                                                height: 25,
                                                              ),
                                                        const SizedBox(
                                                          width: BASE_MARGIN * 2,
                                                        ),
                                                        Text(
                                                          "4",
                                                          style: TextStyle(
                                                            fontSize: Theme.of(context).textTheme.titleSmall!.fontSize!,
                                                            fontWeight: FontWeight.w600,
                                                            color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
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
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(
                    NoSwipePageRoute(
                      builder: (context) {
                        return const GenerationsScreen(
                          type: "modules",
                        );
                      },
                    ),
                  );
                },
                backgroundColor: PRIMARY_COLOR,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.black,
                ),
              ),
              body: SafeArea(
                child: BlocBuilder<UserBloc, UserState>(
                  bloc: userBloc,
                  builder: (context, state) {
                    return ListView.builder(
                      scrollDirection: Axis.vertical,
                      itemCount: data.modules.length,
                      shrinkWrap: true,
                      key: const PageStorageKey('modules'),
                      itemBuilder: (context, index) {
                        final module = data.modules[index];
                        final item = Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 0.0,
                            horizontal: 8.0,
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                10,
                              ),
                            ),
                            tileColor: getSecondaryColor(context),
                            leading: CircularProgressAnimated(
                              key: Key(module.id),
                              maxItems: module.lessons.length.toDouble(),
                              currentItems: module.lessons.where((lesson) => lesson.completed).length.toDouble(),
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                NoSwipePageRoute(
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
                          ),
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (index == 0)
                              const SizedBox(
                                height: BASE_MARGIN * 2,
                              ),
                            item,
                            const SizedBox(
                              height: BASE_MARGIN * 2,
                            ),
                          ],
                        );
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
