import 'dart:convert';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/question.dart';
import 'package:async_builder/async_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
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

  late Future<List<Question>> _fetchQuestions;

  Future<List<Question>> _fetchQuestionsFuture() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token")!;
    final req = await http.get(
        Uri.parse(
          "$API_URL/questions/${widget.lessonId}",
        ),
        headers: {"Authorization": "Bearer $token"});
    final body = jsonDecode(req.body);
    return (body as List).map((q) => Question.toJSON(q)).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchQuestions = _fetchQuestionsFuture();
  }

  @override
  Widget build(BuildContext context) {
    final userBloc = context.read<UserBloc>();

    return Scaffold(
      appBar: AppBar(
        leading: null,
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
                    width: (_currentStep / 20) * constraints.maxWidth,
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
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: AsyncBuilder(
        builder: (context, value) {
          return ListView.builder(
            shrinkWrap: true,
            itemCount: value!.length,
            itemBuilder: (context, index) {
              final question = value[index];
              return ListTile(
                title: Text(question.id),
              );
            },
          );
        },
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
      ),
    );
  }
}
