import 'dart:convert';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/user.dart';
import 'package:app/models/voice.dart';
import 'package:app/screens/shop/subscription.dart';
import 'package:app/utils/print.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/cupertino.dart';
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
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          "Voices",
          style: Theme.of(context).textTheme.titleMedium,
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: PRIMARY_COLOR,
            height: 2.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
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
              itemBuilder: (context, index) {
                final voice = data[index];
                final paid = voice.tiers.contains(Tiers.epic) || voice.tiers.contains(Tiers.premium);
                return GestureDetector(
                  onTap: () {
                    if (paid && user.tier == Tiers.free) {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
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
                          color: SECONDARY_BG_COLOR,
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
                                // bottom: BASE_MARGIN * 2,
                                // right: BASE_MARGIN * 2,
                                left: BASE_MARGIN.toDouble(),
                              )
                            : EdgeInsets.all(
                                BASE_MARGIN.toDouble(),
                              ),
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
                                    const SizedBox(
                                      height: BASE_MARGIN * 2,
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
                                      right: BASE_MARGIN * 2,
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
                                height: 80,
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
