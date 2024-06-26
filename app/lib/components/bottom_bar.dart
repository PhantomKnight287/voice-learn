import 'package:app/constants/main.dart';
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
      onTap: (value) => {widget.onPress(value)},
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
          icon: HeroIcon(
            HeroIcons.chartBar,
            style: widget.currentIndex == 1 ? HeroIconStyle.solid : null,
          ),
          label: "Leaderboard",
        ),
        BottomNavigationBarItem(
          icon: HeroIcon(
            HeroIcons.chatBubbleBottomCenterText,
            style: widget.currentIndex == 2 ? HeroIconStyle.solid : null,
          ),
          label: "Chat",
        ),
        BottomNavigationBarItem(
          icon: HeroIcon(
            HeroIcons.user,
            style: widget.currentIndex == 3 ? HeroIconStyle.solid : null,
          ),
          label: "Profile",
        )
      ],
    );
  }
}
