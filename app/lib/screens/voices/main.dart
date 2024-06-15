import 'dart:convert';

import 'package:app/constants/main.dart';
import 'package:app/models/voice.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
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
      extendBodyBehindAppBar: true,
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
                return ListTile(
                  title: Text(
                    voice.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  tileColor: SECONDARY_BG_COLOR,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: selected?.id == voice.id
                        ? BorderSide(
                            color: Colors.green.shade500,
                            strokeAlign: 2,
                            style: BorderStyle.solid,
                            width: 2,
                          )
                        : BorderSide.none,
                  ),
                  enabled: true,
                  onTap: () {
                    setState(() {
                      selected = voice;
                    });
                  },
                  subtitle: voice.chats != null
                      ? Text(
                          "Used in ${voice.chats} chats",
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.titleSmall!.color,
                          ),
                        )
                      : null,
                  trailing: IconButton(
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
