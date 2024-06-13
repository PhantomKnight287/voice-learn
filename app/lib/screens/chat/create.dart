import 'package:app/constants/main.dart';
import 'package:flutter/material.dart';

class CreateChatScreen extends StatefulWidget {
  const CreateChatScreen({super.key});

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  @override
  Widget build(BuildContext context) {
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
              children: [
                Text(
                  "Create new chat",
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.titleLarge!.fontSize! * 0.85,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: BASE_MARGIN * 1,
                ),
                Text(
                  "Create new chat to practice your learning skills.",
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
