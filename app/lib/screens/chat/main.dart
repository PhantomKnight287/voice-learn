import 'dart:convert';
import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/main.dart';
import 'package:app/models/chat.dart';
import 'package:app/screens/chat/create.dart';
import 'package:app/screens/chat/id.dart';
import 'package:app/utils/error.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:toastification/toastification.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> with RouteAware {
  final _scrollController = ScrollController();
  late InfiniteQuery<List<Chat>, HttpException, int> query;
  bool isDeleting = false;

  Future<List<Chat>> _fetchChats(int page) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final req = await http.get(Uri.parse("$API_URL/chats?page=$page"), headers: {
      "Authorization": "Bearer $token",
    });
    final body = jsonDecode(req.body);
    logger.d("Fetched ${body.length} chats");
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
          color: Colors.black,
        ),
      ),
      appBar: AppBar(
        title: const Text(
          "Chats",
        ),
        centerTitle: true,
        scrolledUnderElevation: 0.0,
        elevation: 0,
        bottom: BOTTOM(context),
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

                return Slidable(
                  endActionPane: ActionPane(
                    motion: const StretchMotion(),
                    children: [
                      SlidableAction(
                        flex: 2,
                        onPressed: (context) {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return StatefulBuilder(builder: (context, setState) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      10,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        setState(() {
                                          isDeleting = false;
                                        });
                                      },
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        if (isDeleting) return;
                                        setState(() {
                                          isDeleting = true;
                                        });
                                        final prefs = await SharedPreferences.getInstance();
                                        final token = prefs.getString('token');
                                        final url = Uri.parse("$API_URL/chats/${chat.id}");
                                        logger.t("Deleting Note with id:${chat.id}");
                                        final req = await http.delete(
                                          url,
                                          headers: {
                                            "Authorization": "Bearer $token",
                                          },
                                        );
                                        final body = jsonDecode(req.body);
                                        setState(() {
                                          isDeleting = false;
                                        });
                                        if (req.statusCode != 200) {
                                          final message = ApiResponseHelper.getErrorMessage(body);
                                          toastification.show(
                                            type: ToastificationType.error,
                                            style: ToastificationStyle.minimal,
                                            autoCloseDuration: const Duration(seconds: 5),
                                            title: const Text("An Error Occurred"),
                                            description: Text(message),
                                            alignment: Alignment.topCenter,
                                            showProgressBar: false,
                                          );
                                          logger.e("Failed to delete note: $message");
                                          return;
                                        }
                                        await query.refreshAll();
                                        if (context.mounted) Navigator.of(context).pop();
                                      },
                                      child: isDeleting
                                          ? const CircularProgressIndicator()
                                          : const Text(
                                              "Delete",
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                    ),
                                  ],
                                  title: const Text("Delete Chat?"),
                                  content: const Text("This action is irreversible!"),
                                );
                              });
                            },
                          );
                        },
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: ListTile(
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
                        : chat.initialPrompt != null && chat.initialPrompt!.isNotEmpty
                            ? Text(
                                chat.initialPrompt ?? "",
                                style: const TextStyle(
                                  color: SECONDARY_TEXT_COLOR,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                    tileColor: getSecondaryColor(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(BASE_MARGIN * 2),
                    ),
                    enabled: true,
                    leading: CachedNetworkImage(
                      imageUrl: chat.flag!,
                      progressIndicatorBuilder: (context, url, progress) {
                        return const CircularProgressIndicator.adaptive();
                      },
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
                  ),
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
