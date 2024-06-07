import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/components/bottom_bar.dart';
import 'package:app/screens/home/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final imageHeight = 144;
  final coverHeight = 280;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          _buildCoverImage(),
          Positioned(
            top: coverHeight - imageHeight / 2,
            child: _buildProfilePicture(),
          ),
        ],
      ),
    );
  }

  CircleAvatar _buildProfilePicture() {
    final userBloc = context.read<UserBloc>();
    final state = userBloc.state;
    return CircleAvatar(
      radius: imageHeight / 2,
      backgroundColor: Colors.grey.shade800,
      backgroundImage: NetworkImage(
        "https://api.dicebear.com/8.x/initials/png?seed=${state.name}",
      ),
    );
  }

  Container _buildCoverImage() {
    return Container(
      height: coverHeight.toDouble(),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xffc2e59c),
            Color(0xff64b3f4),
          ],
          stops: [0.0, 1.0],
          begin: FractionalOffset.topLeft,
          end: FractionalOffset.topRight,
          tileMode: TileMode.decal,
        ),
      ),
    );
  }
}
