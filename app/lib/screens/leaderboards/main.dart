import 'dart:convert';

import 'package:app/constants/main.dart';
import 'package:app/models/leaderboard_item.dart';
import 'package:app/screens/profile/main.dart';
import 'package:app/utils/error.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gravatar/flutter_gravatar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LeaderBoardScreen extends StatefulWidget {
  const LeaderBoardScreen({super.key});

  @override
  State<LeaderBoardScreen> createState() => _LeaderBoardScreenState();
}

class _LeaderBoardScreenState extends State<LeaderBoardScreen> {
  Future<List<LeaderboardItem>> _fetchLeaderboardItem(int page) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final req = await http.get(Uri.parse('$API_URL/leaderboard?page=$page'), headers: {"Authorization": "Bearer $token"});
    final res = await jsonDecode(req.body);
    if (req.statusCode != 200) throw ApiResponseHelper.getErrorMessage(res);
    return (res as List).map((e) => LeaderboardItem.fromJSON(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: BOTTOM,
        elevation: 0,
        scrolledUnderElevation: 0,
        forceMaterialTransparency: true,
        title: Text(
          "Leaderboard",
          style: TextStyle(
            fontSize: Theme.of(context).textTheme.titleMedium!.fontSize!,
            fontWeight: Theme.of(context).textTheme.titleMedium!.fontWeight,
            fontFamily: "CalSans",
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(
            height: BASE_MARGIN * 2,
          ),
          InfiniteQueryBuilder<List<LeaderboardItem>, Exception, int>(
            'leaderboard',
            (page) => _fetchLeaderboardItem(page),
            nextPage: (lastPage, lastPageData) {
              if (lastPageData.length < 20) return null;
              return lastPage + 1;
            },
            builder: (context, query) {
              final board = query.pages.map((e) => e).expand((e) => e).toList();
              if (board.isEmpty) {
                return const Center(
                  child: Text(
                    "It looks a little quiet here. Complete a lesson to get your name here.",
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return ListView.separated(
                separatorBuilder: (context, index) {
                  return const SizedBox(
                    height: BASE_MARGIN * 2,
                  );
                },
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final item = board[index];
                  final avatar = Gravatar(item.email);
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(CupertinoPageRoute(
                        builder: (context) {
                          return ProfileScreen(
                            userId: item.id,
                          );
                        },
                      ));
                    },
                    child: Container(
                      color: SECONDARY_BG_COLOR,
                      padding: const EdgeInsets.symmetric(
                        vertical: BASE_MARGIN * 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 20,
                              left: 20,
                            ),
                            child: Text(
                              (index + 1).toString(),
                              style: TextStyle(
                                fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey.shade800,
                            backgroundImage: NetworkImage(
                              avatar.imageUrl(),
                            ),
                          ),
                          const SizedBox(
                            width: BASE_MARGIN * 2,
                          ),
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.start,
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 20,
                              left: 20,
                            ),
                            child: Text(
                              "${item.xp} XP",
                              style: TextStyle(
                                fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  ListTile(
                    title: Text(
                      item.name,
                      style: TextStyle(
                        fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    leading: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade800,
                      backgroundImage: NetworkImage(
                        avatar.imageUrl(),
                      ),
                    ),
                    trailing: Text(
                      "${item.xp} XP",
                      style: TextStyle(
                        fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
                itemCount: board.length,
              );
            },
            initialPage: 1,
          ),
        ],
      ),
    );
  }
}
