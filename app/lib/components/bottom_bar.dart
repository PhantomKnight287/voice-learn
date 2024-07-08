import 'package:app/constants/main.dart';
import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';

class BottomBar extends StatefulWidget {
  final int currentIndex;
  final Function(int index) onPress;
  const BottomBar({
    super.key,
    required this.currentIndex,
    required this.onPress,
  });

  @override
  State<BottomBar> createState() => _BottomNavigationBarState();
}

class _BottomNavigationBarState extends State<BottomBar> {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: (value) {
        widget.onPress(value);
        logger.i("Navigating to screen with index: $value");
      },
      selectedItemColor: PRIMARY_COLOR,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(
        color: Colors.black,
      ),
      unselectedLabelStyle: const TextStyle(
        color: Colors.black,
      ),
      items: [
        BottomNavigationBarItem(
          icon: HeroIcon(
            HeroIcons.home,
            style: widget.currentIndex == 0 ? HeroIconStyle.solid : null,
          ),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(
            widget.currentIndex == 1 ? Icons.school_rounded : Icons.school_outlined,
          ),
          label: "Recall",
        ),
        BottomNavigationBarItem(
          icon: HeroIcon(
            HeroIcons.chartBar,
            style: widget.currentIndex == 2 ? HeroIconStyle.solid : null,
          ),
          label: "Leaderboard",
        ),
        BottomNavigationBarItem(
          icon: HeroIcon(
            HeroIcons.chatBubbleBottomCenterText,
            style: widget.currentIndex == 3 ? HeroIconStyle.solid : null,
          ),
          label: "Chat",
        ),
        BottomNavigationBarItem(
          icon: HeroIcon(
            HeroIcons.user,
            style: widget.currentIndex == 4 ? HeroIconStyle.solid : null,
          ),
          label: "Profile",
        )
      ],
    );
  }
}
