import 'dart:convert';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/user.dart';
import 'package:app/models/voice.dart';
import 'package:app/screens/shop/subscription.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heroicons/heroicons.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

class VoicesScreen extends StatefulWidget {
  const VoicesScreen({super.key});

  @override
  State<VoicesScreen> createState() => _VoicesScreenState();
}

class _VoicesScreenState extends State<VoicesScreen> {
  final player = AudioPlayer();
  String playing = "";
  Voice? selected;
  Future<List<Voice>> _fetchVoices() async {
    final req = await http.get(
      Uri.parse("$API_URL/voices"),
    );
    final body = jsonDecode(req.body);

    return (body as List).map((e) => Voice.fromJSON(e)).toList();
  }

  @override
  void initState() {
    _subscribeToPlayer();
    super.initState();
  }

  void _subscribeToPlayer() {
    player.onPlayerComplete.listen(
      (event) {
        setState(() {
          playing = "";
        });
      },
    );
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<UserBloc>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Voices",
        ),
        actions: selected != null
            ? [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop(selected);
                  },
                  icon: const HeroIcon(
                    HeroIcons.checkCircle,
                    style: HeroIconStyle.solid,
                    color: Colors.green,
                  ),
                )
              ]
            : null,
        centerTitle: true,
        bottom: BOTTOM(context),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            top: 0,
            bottom: 10,
            left: 10,
            right: 10,
          ),
          child: QueryBuilder(
            'voices',
            _fetchVoices,
            builder: (context, query) {
              if (query.isLoading) return _buildLoader();
              if (query.hasError) {
                return Center(
                  child: Text(query.error.toString()),
                );
              }
              final data = query.data;
              if (data == null) return _buildLoader();
              return ListView.separated(
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final voice = data[index];
                  final paid = voice.tiers.contains(Tiers.epic) || voice.tiers.contains(Tiers.premium);
                  final item = GestureDetector(
                    onTap: () {
                      if (paid && user.tier == Tiers.free) {
                        Navigator.of(context).push(
                          NoSwipePageRoute(
                            builder: (context) {
                              return const SubscriptionScreen();
                            },
                          ),
                        ).then(
                          (value) {
                            setState(() {});
                          },
                        );
                        return;
                      }
                      setState(() {
                        selected = voice;
                      });
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: getSecondaryColor(context),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(
                                10,
                              ),
                              bottomRight: Radius.circular(
                                10,
                              ),
                            ),
                            border: Border(
                              bottom: BorderSide(
                                color: selected?.id == voice.id ? Colors.green : Colors.transparent,
                                width: 2,
                              ),
                              left: BorderSide(
                                color: selected?.id == voice.id ? Colors.green : Colors.transparent,
                                width: 2,
                              ),
                              right: BorderSide(
                                color: selected?.id == voice.id ? Colors.green : Colors.transparent,
                                width: 2,
                              ),
                              top: BorderSide(
                                color: selected?.id == voice.id ? Colors.green : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          padding: paid
                              ? EdgeInsets.only(
                                  bottom: BASE_MARGIN * 0,
                                  right: BASE_MARGIN * 0,
                                  left: BASE_MARGIN.toDouble(),
                                  top: 0,
                                )
                              : EdgeInsets.zero,
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        voice.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (voice.chats != null)
                                        Text(
                                          "Used in ${voice.chats} chats",
                                          maxLines: 1,
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Theme.of(context).textTheme.titleSmall!.color,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: paid
                                    ? const EdgeInsets.only(
                                        right: BASE_MARGIN * 0,
                                      )
                                    : const EdgeInsets.all(8.0),
                                child: IconButton(
                                  onPressed: () async {
                                    if (playing == voice.id) {
                                      await player.pause();
                                      setState(() {
                                        playing = "";
                                      });
                                    } else {
                                      await player.play(
                                        UrlSource(voice.previewUrl),
                                      );
                                      setState(() {
                                        playing = voice.id;
                                      });
                                    }
                                  },
                                  icon: HeroIcon(
                                    playing == voice.id ? HeroIcons.pauseCircle : HeroIcons.playCircle,
                                    style: HeroIconStyle.solid,
                                    size: 30,
                                  ),
                                ),
                              ),
                              if (paid)
                                Container(
                                  width: 10,
                                  height: 64,
                                  decoration: const BoxDecoration(
                                    color: PRIMARY_COLOR,
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(
                                        10,
                                      ),
                                      bottomRight: Radius.circular(
                                        10,
                                      ),
                                    ),
                                  ),
                                )
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                  if (index == 0) {
                    return Column(
                      children: [
                        const SizedBox(
                          height: BASE_MARGIN * 4,
                        ),
                        item,
                      ],
                    );
                  }
                  return item;
                },
                separatorBuilder: (context, index) {
                  return const SizedBox(
                    height: BASE_MARGIN * 2,
                  );
                },
                itemCount: data.length,
              );
            },
            refreshConfig: RefreshConfig.withDefaults(
              context,
              refreshOnMount: true,
            ),
          ),
        ),
      ),
    );
  }

  Column _buildLoader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 60,
        ),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade400,
          child: Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(
          height: BASE_MARGIN * 2,
        ),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade400,
          child: Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(
          height: BASE_MARGIN * 2,
        ),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade400,
          child: Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(
          height: BASE_MARGIN * 2,
        ),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade400,
          child: Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(
          height: BASE_MARGIN * 2,
        ),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade400,
          child: Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}

class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.2); // Adjust the size of the triangle
    path.lineTo(size.width * 0.8, 0); // Adjust the size of the triangle
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
