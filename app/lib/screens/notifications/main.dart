import 'dart:convert';
import 'dart:io';

import 'package:app/constants/main.dart';
import 'package:app/main.dart';
import 'package:app/models/notification.dart';
import 'package:app/utils/error.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:toastification/toastification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  InfiniteQuery<List<NotificationModel>, HttpException, int>? query;
  final _scrollController = ScrollController();
  bool loading = false;
  bool isActive = false;
  Future<List<NotificationModel>> _fetchNotifications(int page) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final url = Uri.parse(
      "$API_URL/notifications?page=$page&limit=100",
    );
    logger.t("Fetching Notifications ${url.toString()}");
    final req = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    final body = jsonDecode(req.body);
    if (req.statusCode != 200) {
      final message = ApiResponseHelper.getErrorMessage(body);
      logger.e("Failed to fetch notifications: $message");
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("An Error Occurred"),
        description: Text(message),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
      return [];
    }
    setState(() {
      isActive = body['hasUnread'];
    });
    return (body['notifications'] as List).map((notif) => NotificationModel.fromJSON(notif)).toList();
  }

  void _scrollListener() async {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (query != null) {
        if (query!.hasNextPage) {
          await query!.fetchNext();
        }
      }
    }
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: BOTTOM(context),
        title: const Text(
          "Notifications",
        ),
        actions: [
          if (isActive)
            IconButton(
              tooltip: "Mark all as read",
              onPressed: () async {
                if (loading || !isActive) return;
                HapticFeedback.heavyImpact();
                setState(() {
                  loading = true;
                });
                final url = Uri.parse("$API_URL/notifications/read");
                logger.t("Marking Notifications as read: $url");
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString("token");
                final req = await http.patch(
                  url,
                  headers: {"Authorization": "Bearer $token"},
                );
                final body = jsonDecode(req.body);
                setState(() {
                  loading = false;
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
                  logger.e("Failed to mark notifications as read: $message");
                  return;
                }
                setState(() {
                  isActive = false;
                });
                toastification.show(
                  type: ToastificationType.success,
                  style: ToastificationStyle.minimal,
                  autoCloseDuration: const Duration(seconds: 5),
                  title: Text("Marked ${body['count']} notifications as read"),
                  alignment: Alignment.topCenter,
                  showProgressBar: false,
                );
                logger.t("Marked ${body['count']} as read");
              },
              icon: loading
                  ? const CircularProgressIndicator.adaptive()
                  : Icon(
                      Icons.check,
                      color: isActive ? PRIMARY_COLOR : Colors.grey,
                    ),
            ),
        ],
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(BASE_MARGIN * 2),
        child: InfiniteQueryBuilder<List<NotificationModel>, HttpException, int>(
          "notifications",
          (page) => _fetchNotifications(page),
          nextPage: (lastPage, lastPageData) {
            if (lastPageData.length == 100) return lastPage + 1;
            return null;
          },
          builder: (context, query) {
            this.query = query;
            final notifications = query.pages.map((e) => e).expand((e) => e).toList();
            if (notifications.isEmpty) {
              return const Center(
                child: Text("No notifications"),
              );
            }
            return ListView.separated(
              controller: _scrollController,
              separatorBuilder: (context, index) {
                return const SizedBox(
                  height: BASE_MARGIN * 1,
                );
              },
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final visuals = NotificationModel.getProperties(notification.type);
                return ListTile(
                  tileColor: getSecondaryColor(context),
                  title: Text(notification.title),
                  leading: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: visuals['color'].withOpacity(
                        0.2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        visuals['icon'],
                        color: visuals['color'],
                      ),
                    ),
                  ),
                  subtitle: Text(
                    notification.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                  ),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return Container(
                          height: 200,
                          width: double.infinity,
                          padding: const EdgeInsets.all(
                            16,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: TextStyle(
                                  fontFamily: "CalSans",
                                  fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                                ),
                              ),
                              const SizedBox(
                                height: BASE_MARGIN * 2,
                              ),
                              Text(notification.description),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
              itemCount: notifications.length,
            );
          },
          initialPage: 1,
          refreshConfig: RefreshConfig.withDefaults(
            context,
            refreshOnMount: true,
          ),
        ),
      ),
    );
  }
}
