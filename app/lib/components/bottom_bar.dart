import 'package:app/constants/main.dart';
import 'package:flutter/material.dart';

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
      items: const [
        BottomNavigationBarItem(
          icon: Icon(
            Icons.home_rounded,
          ),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.leaderboard_rounded,
          ),
          label: "Leaderboard",
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.chat_rounded,
          ),
          label: "Chat",
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.person_rounded,
          ),
          label: "Profile",
        )
      ],
    );
  }
}
