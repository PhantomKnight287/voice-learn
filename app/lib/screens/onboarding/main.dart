import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/screens/auth/login.dart';
import 'package:app/screens/auth/register.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          BASE_MARGIN * 2,
          BASE_MARGIN * 5,
          BASE_MARGIN * 2,
          BASE_MARGIN * 2,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Practice New",
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.titleLarge!.fontSize,
                    fontWeight: Theme.of(context).textTheme.titleLarge!.fontWeight,
                    fontFamily: "CalSans",
                  ),
                ),
                Text(
                  "Languages",
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.titleLarge!.fontSize,
                    fontWeight: Theme.of(context).textTheme.titleLarge!.fontWeight,
                    fontFamily: "CalSans",
                  ),
                ),
                const SizedBox(
                  height: BASE_MARGIN * 2,
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const textBeforeBrand = 'Practice your Language speaking with ';
                    final normalTextPainter = TextPainter(
                      text: TextSpan(
                        text: textBeforeBrand,
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                          color: Colors.black,
                        ),
                      ),
                      textDirection: TextDirection.ltr,
                    )..layout(maxWidth: constraints.maxWidth);
                    final brandTextPainter = TextPainter(
                      text: TextSpan(
                        text: brandName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                          color: Colors.black,
                        ),
                      ),
                      textDirection: TextDirection.ltr,
                    )..layout(maxWidth: constraints.maxWidth);

                    final remainingWidth = constraints.maxWidth - normalTextPainter.width;
                    // Check if the brand name can fit in the remaining width
                    final isBrandInNextLine = remainingWidth < brandTextPainter.width;
                    return RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                          color: Colors.black,
                        ),
                        children: <TextSpan>[
                          const TextSpan(text: textBeforeBrand),
                          if (isBrandInNextLine)
                            TextSpan(
                              text: '\n$brandName',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                                color: Colors.black,
                              ),
                            )
                          else
                            TextSpan(
                              text: brandName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                                color: Colors.black,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const Spacer(),
                const SizedBox(
                  child: Center(
                    child: RiveAnimation.asset(
                      "assets/animations/flags.riv",
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      useArtboardSize: true,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      NoSwipePageRoute(
                        builder: (context) => const RegisterScreen(),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Get Started".toUpperCase(),
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        const Icon(
                          Icons.arrow_forward,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: BASE_MARGIN * 3,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      NoSwipePageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "I already have an account".toUpperCase(),
                          style: TextStyle(
                            color: PRIMARY_COLOR,
                            fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                            fontWeight: FontWeight.w600,
                          ),
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
