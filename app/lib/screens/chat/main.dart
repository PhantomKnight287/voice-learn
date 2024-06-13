import 'package:app/constants/main.dart';
import 'package:app/screens/chat/create.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(CupertinoPageRoute(
            builder: (context) {
              return const CreateChatScreen();
            },
          ));
        },
        backgroundColor: PRIMARY_COLOR,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.add_rounded,
        ),
      ),
      appBar: AppBar(
        title: Text(
          "Chats",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        centerTitle: true,
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
    );
  }
}
