import 'package:flutter/material.dart';

class RecallScreen extends StatefulWidget {
  const RecallScreen({super.key});

  @override
  State<RecallScreen> createState() => _RecallScreenState();
}

class _RecallScreenState extends State<RecallScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: EdgeInsets.all(
          10,
        ),
        child: Center(
          child: Text("WIP"),
        ),
      ),
    );
  }
}
