import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class SubscriptionPurchasedScreen extends StatefulWidget {
  const SubscriptionPurchasedScreen({super.key});

  @override
  State<SubscriptionPurchasedScreen> createState() => _SubscriptionPurchasedScreenState();
}

class _SubscriptionPurchasedScreenState extends State<SubscriptionPurchasedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: RiveAnimation.asset(
          "assets/animations/rocket.riv",
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
