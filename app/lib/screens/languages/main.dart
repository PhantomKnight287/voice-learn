import 'dart:convert';

import 'package:app/constants/main.dart';
import 'package:app/models/language.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

class LanguagesScreen extends StatefulWidget {
  const LanguagesScreen({super.key});

  @override
  State<LanguagesScreen> createState() => _LanguagesScreenState();
}

class _LanguagesScreenState extends State<LanguagesScreen> {
  String playing = "";
  Language? selected;
  Future<List<Language>> _fetchLanguages() async {
    final req = await http.get(
      Uri.parse("$API_URL/languages"),
    );
    final body = jsonDecode(req.body);

    return (body as List).map((e) => Language.fromJSON(e)).toList();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          "Languages",
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
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: QueryBuilder(
          'languages',
          _fetchLanguages,
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
                final language = data[index];
                return ListTile(
                  title: Text(
                    language.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  tileColor: getSecondaryColor(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: selected?.id == language.id
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
                      selected = language;
                    });
                  },
                  leading: CachedNetworkImage(
                    imageUrl: language.flagUrl,
                    width: 35,
                    height: 35,
                    progressIndicatorBuilder: (context, url, progress) {
                      return const CircularProgressIndicator.adaptive();
                    },
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
