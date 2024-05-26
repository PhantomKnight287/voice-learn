import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/constants/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    final userBloc = context.read<UserBloc>();
    return Scaffold(
      appBar: null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (value) => {
          setState(() {
            _currentIndex = value;
          })
        },
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
      ),
      body: SafeArea(
        child: BlocBuilder<UserBloc, UserState>(
          bloc: userBloc,
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    "Welcome ${state.name.split(" ")[0]}",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
