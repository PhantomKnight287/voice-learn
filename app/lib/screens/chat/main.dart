import 'dart:convert';
import 'dart:io';

import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/main.dart';
import 'package:app/models/chat.dart';
import 'package:app/screens/chat/create.dart';
import 'package:app/screens/chat/id.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> with RouteAware {
  final _scrollController = ScrollController();
  late InfiniteQuery<List<Chat>, HttpException, int> query;
  Future<List<Chat>> _fetchChats(int page) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final req = await http.get(Uri.parse("$API_URL/chats?page=$page"), headers: {
      "Authorization": "Bearer $token",
    });
    final body = jsonDecode(req.body);
    final res = (body as List).map((e) => Chat.fromJSON(e)).toList();
    return res;
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
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    routeObserver.unsubscribe(this);

    super.dispose();
  }

  @override
  void didPopNext() {
    QueryClient.of(context).refreshQuery('learning_path');
    QueryClient.of(context).refreshQuery('profile_stats');
    QueryClient.of(context).refreshInfiniteQuery('chats');
  }

  void _scrollListener() async {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (query != null) {
        if (query.hasNextPage) {
          await query.fetchNext();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(NoSwipePageRoute(
            builder: (context) {
              return const CreateChatScreen();
            },
          ));
        },
        backgroundColor: PRIMARY_COLOR,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.add_rounded,
        ),
      ),
      appBar: AppBar(
        title: const Text(
          "Chats",
        ),
        centerTitle: true,
        scrolledUnderElevation: 0.0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
        bottom: BOTTOM,
      ),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(10),
        child: InfiniteQueryBuilder<List<Chat>, HttpException, int>(
          'chats',
          (page) => _fetchChats(page),
          builder: (context, query) {
            this.query = query;
            final chats = query.pages.map((e) => e).expand((e) => e).toList();
            if (chats.isEmpty) {
              return const Center(
                child: Text(
                  "It looks a little quiet here. Start a new chat to get the conversation going!",
                  textAlign: TextAlign.center,
                ),
              );
            }
            return ListView.separated(
              controller: _scrollController,
              itemBuilder: (context, index) {
                final chat = chats[index];

                return ListTile(
                  title: Text(
                    chat.name,
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.titleMedium!.fontSize! * 0.9,
                    ),
                  ),
                  subtitle: chat.lastMessage.isNotEmpty
                      ? Text(
                          chat.lastMessage,
                          style: const TextStyle(
                            color: SECONDARY_TEXT_COLOR,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          chat.initialPrompt ?? "",
                          style: const TextStyle(
                            color: SECONDARY_TEXT_COLOR,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  tileColor: SECONDARY_BG_COLOR,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(BASE_MARGIN * 2),
                  ),
                  enabled: true,
                  leading: Image.network(
                    chat.flag!,
                    width: 40,
                    height: 40,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      NoSwipePageRoute(
                        builder: (context) {
                          return ChatScreen(id: chat.id);
                        },
                      ),
                    );
                  },
                );
              },
              itemCount: chats.length,
              separatorBuilder: (context, index) {
                return const SizedBox(
                  height: BASE_MARGIN * 2,
                );
              },
            );
          },
          initialPage: 1,
          nextPage: (lastPage, lastPageData) {
            if (lastPageData.length < 20) return null;
            return lastPage + 1;
          },
        ),
      )),
    );
  }
}
