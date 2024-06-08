import 'dart:convert';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/constants/main.dart';
import 'package:app/utils/error.dart';
import 'package:async_builder/async_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final imageHeight = 100;

  Future<dynamic> _getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final req = await http.get(Uri.parse("$API_URL/profile/@me"), headers: {"Authorization": "Bearer $token"});
    final body = jsonDecode(req.body);
    if (req.statusCode != 200) {
      throw ApiResponseHelper.getErrorMessage(body);
    }
    return body;
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.read<UserBloc>().state;
    DateTime dateTime = DateTime.parse(userState.createdAt);
    String monthName = DateFormat.MMMM().format(dateTime);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profile",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.settings_rounded,
            ),
          ),
        ],
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: AsyncBuilder(
              future: _getUserProfile(),
              waiting: (context) {
                return _buildBaseProfile(userState, context, monthName, dateTime);
              },
              error: (context, error, stackTrace) {
                return _buildBaseProfile(userState, context, monthName, dateTime);
              },
              builder: (context, value) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBaseProfile(
                      userState,
                      context,
                      monthName,
                      dateTime,
                      flags: value?['paths']?[0]?['language']?['flagUrl'] != null
                          ? [
                              value?['paths']?[0]?['language']?['flagUrl'],
                            ]
                          : [],
                    ),
                    const SizedBox(
                      height: BASE_MARGIN * 3,
                    ),
                    Text(
                      "Statistics",
                      style: TextStyle(
                        fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: BASE_MARGIN * 3,
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: Container(
                          padding: const EdgeInsets.all(
                            BASE_MARGIN * 2.5,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(
                              10,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const HeroIcon(
                                HeroIcons.bolt,
                                color: PRIMARY_COLOR,
                                size: 30,
                                style: HeroIconStyle.solid,
                              ),
                              const SizedBox(
                                width: BASE_MARGIN * 2,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    value['activeStreaks'].toString(),
                                    style: TextStyle(
                                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: BASE_MARGIN * 1,
                                  ),
                                  Text(
                                    "Active streak",
                                    style: Theme.of(context).textTheme.titleSmall,
                                  )
                                ],
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(
                          width: BASE_MARGIN * 2,
                        ),
                        Expanded(
                            child: Container(
                          padding: const EdgeInsets.all(
                            BASE_MARGIN * 2.5,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(
                              10,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(
                                "assets/images/coin.png",
                                width: 30,
                                height: 30,
                              ),
                              const SizedBox(
                                width: BASE_MARGIN * 2,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    value['xp'].toString(),
                                    style: TextStyle(
                                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: BASE_MARGIN * 1,
                                  ),
                                  Text(
                                    "Total XP",
                                    style: Theme.of(context).textTheme.titleSmall,
                                  )
                                ],
                              ),
                            ],
                          ),
                        ))
                      ],
                    ),
                    const SizedBox(
                      height: BASE_MARGIN * 2,
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: Container(
                          padding: const EdgeInsets.all(
                            BASE_MARGIN * 2.5,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(
                              10,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(
                                "assets/images/emerald.png",
                                width: 25,
                                height: 25,
                              ),
                              const SizedBox(
                                width: BASE_MARGIN * 2,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    value['emeralds'].toString(),
                                    style: TextStyle(
                                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: BASE_MARGIN * 1,
                                  ),
                                  Text(
                                    "Emeralds",
                                    style: Theme.of(context).textTheme.titleSmall,
                                  )
                                ],
                              ),
                            ],
                          ),
                        ))
                      ],
                    )
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Column _buildBaseProfile(
    UserState userState,
    BuildContext context,
    String monthName,
    DateTime dateTime, {
    List<String>? flags,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: BASE_MARGIN * 3,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  userState.name,
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: BASE_MARGIN * 2,
                ),
                Text("Joined $monthName ${dateTime.year}"),
                const SizedBox(
                  height: BASE_MARGIN * 2,
                ),
              ],
            ),
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey.shade800,
              backgroundImage: NetworkImage(
                "https://api.dicebear.com/8.x/initials/png?seed=${userState.name}",
              ),
            )
          ],
        ),
      ],
    );
  }
}
