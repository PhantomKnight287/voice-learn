import 'dart:convert';
import 'dart:io';

import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/main.dart';
import 'package:app/models/note.dart';
import 'package:app/screens/recall/notes/create.dart';
import 'package:app/screens/recall/notes/id.dart';
import 'package:app/utils/error.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class StackScreen extends StatefulWidget {
  final String id;
  final String name;
  const StackScreen({
    super.key,
    required this.id,
    required this.name,
  });

  @override
  State<StackScreen> createState() => _StackScreenState();
}

class _StackScreenState extends State<StackScreen> with RouteAware {
  late InfiniteQuery<List<Note>, HttpException, int> query;
  final controller = ScrollController();
  Future<List<Note>> _fetchNotes(int page) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final url = Uri.parse(
      "$API_URL/recalls/${widget.id}/notes?page=$page",
    );
    logger.d("Requesting ${url.toString()}");
    final req = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    final body = jsonDecode(req.body);
    if (req.statusCode != 200) {
      final errorMessage = ApiResponseHelper.getErrorMessage(body);
      logger.e("Failed to fetch notes: $errorMessage");
      throw errorMessage;
    }
    logger.d("Fetched ${body.length} notes");
    return (body as List).map((item) => Note.fromJSON(item)).toList();
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(
      () async {
        if (controller.position.pixels == controller.position.maxScrollExtent) {
          if (query != null) {
            if (query.hasNextPage) {
              await query.fetchNext();
            }
          }
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(
      this,
      ModalRoute.of(context)!,
    );
  }

  @override
  void didPopNext() {
    QueryClient.of(context).refreshQuery('stacks');
    QueryClient.of(context).refreshQuery('notes_${widget.id}');
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    routeObserver.unsubscribe(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        centerTitle: true,
        bottom: BOTTOM(context),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(NoSwipePageRoute(
            builder: (context) {
              return CreateNoteScreen(
                stackId: widget.id,
              );
            },
          ));
        },
        backgroundColor: PRIMARY_COLOR,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.add_rounded,
          color: Colors.black,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(BASE_MARGIN * 3),
            child: InfiniteQueryBuilder<List<Note>, HttpException, int>(
              'notes_${widget.id}',
              (page) => _fetchNotes(page),
              builder: (context, query) {
                this.query = query;
                final notes = query.pages.map((e) => e).expand((e) => e).toList();
                if (notes.isEmpty) {
                  return const Center(
                    child: Text(
                      "Long press underlined text anywhere in the app to add a note or press the floating button.",
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.separated(
                  separatorBuilder: (context, index) {
                    return const SizedBox(
                      height: BASE_MARGIN * 2,
                    );
                  },
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return ListTile(
                      title: Text(
                        note.title,
                      ),
                      tileColor: getSecondaryColor(context),
                      subtitle: Text(
                        note.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          10,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          NoSwipePageRoute(
                            builder: (context) {
                              return NoteScreen(
                                id: note.id,
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                  shrinkWrap: true,
                  itemCount: notes.length,
                  controller: controller,
                );
              },
              initialPage: 1,
              nextPage: (lastPage, lastPageData) {
                if (lastPageData.length == 20) return lastPage + 1;
                return null;
              },
              refreshConfig: RefreshConfig.withDefaults(
                context,
                refreshOnMount: true,
                staleDuration: const Duration(
                  seconds: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
