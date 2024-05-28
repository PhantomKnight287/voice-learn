import 'package:app/screens/auth/login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final String brandName = 'Voice Learn.';
  late TextStyle normalTextStyle;
  late TextStyle brandTextStyle;

  @override
  void initState() {
    super.initState();
    normalTextStyle = TextStyle(
      fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
      color: Colors.black,
    );
    brandTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
      color: Colors.black,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
        child: SafeArea(
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Practice New",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  "Languages",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(
                  height: 20,
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const textBeforeBrand = 'Practice your Language speaking with ';
                    final normalTextPainter = TextPainter(
                      text: TextSpan(text: textBeforeBrand, style: normalTextStyle),
                      textDirection: TextDirection.ltr,
                    )..layout(maxWidth: constraints.maxWidth);
                    final brandTextPainter = TextPainter(
                      text: TextSpan(text: brandName, style: brandTextStyle),
                      textDirection: TextDirection.ltr,
                    )..layout(maxWidth: constraints.maxWidth);

                    final remainingWidth = constraints.maxWidth - normalTextPainter.width;
                    // Check if the brand name can fit in the remaining width
                    final isBrandInNextLine = remainingWidth < brandTextPainter.width;
                    return RichText(
                      text: TextSpan(
                        style: normalTextStyle,
                        children: <TextSpan>[
                          const TextSpan(text: textBeforeBrand),
                          if (isBrandInNextLine) TextSpan(text: '\n$brandName', style: brandTextStyle) else TextSpan(text: brandName, style: brandTextStyle),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(
                  height: 40,
                ),
                const Spacer(),
                const SizedBox(
                  child: RiveAnimation.asset(
                    "assets/animations/flags.riv",
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    useArtboardSize: true,
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      CupertinoPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Get Started",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Icon(
                          Icons.arrow_forward,
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
