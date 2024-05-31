import 'dart:convert';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/learning_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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
    return FutureBuilder<LearningPath>(
        future: _fetchLearningPath,
        builder: (context, snapshot) {
          final data = snapshot.data!;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData == false) return const Text("waiting");
          return Stack(
            children: [
              Scaffold(
                appBar: AppBar(
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
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
                        Icon(
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
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [],
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
