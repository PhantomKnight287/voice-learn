import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/components/circular_progress.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/lesson.dart';
import 'package:app/models/module.dart';
import 'package:app/screens/generations/modules.dart';
import 'package:app/screens/loading/questions.dart';
import 'package:app/screens/questions/complete.dart';
import 'package:app/screens/questions/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';

class LessonsListScreen extends StatefulWidget {
  final Module module;
  const LessonsListScreen({
    super.key,
    required this.module,
  });

  @override
  State<LessonsListScreen> createState() => _LessonsListScreenState();
}

class _LessonsListScreenState extends State<LessonsListScreen> {
  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BASE_MARGIN * 3,
              vertical: BASE_MARGIN * 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          final userState = context.read<UserBloc>().state;
                          if (userState.lives < 1 && lesson.completed == false) {
                            toastification.show(
                              type: ToastificationType.warning,
                              style: ToastificationStyle.minimal,
                              autoCloseDuration: const Duration(seconds: 5),
                              title: const Text("Not enough lives"),
                              description: const Text(
                                "You don't have enough lives.",
                              ),
                              alignment: Alignment.topCenter,
                              showProgressBar: false,
                            );
                            return;
                          }

                          Navigator.of(context).push(
                            lesson.completed
                                ? CupertinoPageRoute(
                                    builder: (context) => LessonCompleteScreen(
                                      questionId: lesson.id,
                                      showAd: false,
                                    ),
                                  )
                                : CupertinoPageRoute(
                                    builder: (context) => QuestionsScreen(
                                      lessonId: lesson.id,
                                    ),
                                  ),
                          );
                        } else {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => QuestionsGenerationLoadingScreen(
                                lessonId: lesson.id,
                                status: lesson.status,
                              ),
                            ),
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
                        currentItems: lesson.correctAnswers.toDouble(),
                        maxItems: lesson.questions!.toDouble(),
                        bgColor: lesson.questions!.toDouble() > lesson.incorrectAnswers.toDouble() && lesson.correctAnswers.toDouble() > 1 ? Colors.red : null,
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
                ),
                const SizedBox(
                  height: BASE_MARGIN * 4,
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) {
                          return GenerationsScreen(
                            type: "lessons",
                            id: module.id,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
