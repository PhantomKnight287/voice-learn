import 'package:app/constants/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LearningPathLoadingScreen extends StatefulWidget {
  final String pathId;
  const LearningPathLoadingScreen({
    super.key,
    required this.pathId,
  });

  @override
  State<LearningPathLoadingScreen> createState() => _LearningPathLoadingScreenState();
}

class _LearningPathLoadingScreenState extends State<LearningPathLoadingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Generating your personalized learning path. Please wait...",
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SpinKitRipple(
            color: PRIMARY_COLOR,
            size: 100,
          ),
        ],
      ),
    );
  }
}
