import 'dart:convert';
import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:app/components/input.dart';
import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/main.dart';
import 'package:app/models/recall.dart';
import 'package:app/screens/recall/id.dart';
import 'package:app/utils/error.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:toastification/toastification.dart';

class RecallScreen extends StatefulWidget {
  const RecallScreen({super.key});

  @override
  State<RecallScreen> createState() => _RecallScreenState();
}

class _RecallScreenState extends State<RecallScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  late InfiniteQuery<List<RecallStack>, HttpException, int> query;
  Future<List<RecallStack>> _fetchStacks(int page) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    logger.t("Fetching Stack");
    final req = await http.get(
        Uri.parse(
          "$API_URL/recalls/stacks?page=$page",
        ),
        headers: {
          "Authorization": "Bearer $token",
        });
    final body = jsonDecode(req.body);
    if (req.statusCode != 200) {
      final message = ApiResponseHelper.getErrorMessage(body);
      logger.e("Failed to load Stack. $message");
      throw ApiResponseHelper.getErrorMessage(message);
    }
    logger.i("Fetched ${body.length} stacks");
    return (body as List).map((item) => RecallStack.fromJSON(item)).toList();
  }

  Future<void> _createStack() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    logger.t("Creating Stack");
    final req = await http.post(
      Uri.parse(
        "$API_URL/recalls/stacks",
      ),
      headers: {
        "Authorization": "Bearer $token",
        "Content-type": "application/json",
      },
      body: jsonEncode(
        {
          "name": _nameController.text,
        },
      ),
    );
    final body = jsonDecode(req.body);
    if (req.statusCode != 201) {
      final message = ApiResponseHelper.getErrorMessage(body);
      logger.e("Failed to create Stack. $message");
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("An Error Occurred"),
        description: Text(
          message,
        ),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
      return;
    }
    logger.i("Created stack with id:${body['id']}");
    await query.refreshAll();

    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Recall",
        ),
        centerTitle: true,
        bottom: BOTTOM(context),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                ),
                title: const Text(
                  'Create Stack',
                ),
                content: Form(
                  key: _formKey,
                  child: InputField(
                    hintText: "Name",
                    keyboardType: TextInputType.name,
                    controller: _nameController,
                    autoFocus: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter title of your stack.';
                      }
                      return null;
                    },
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                      ),
                    ),
                    onPressed: () {
                      if (_loading) return;
                      Navigator.of(context).pop();
                    },
                  ),
                  StatefulBuilder(builder: (context, statefulSetState) {
                    return TextButton(
                      child: _loading
                          ? const CupertinoActivityIndicator(
                              animating: true,
                            )
                          : Text(
                              'Create',
                              style: TextStyle(
                                color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                              ),
                            ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate() == false) return;
                        if (_loading) return;
                        statefulSetState(() {
                          _loading = true;
                        });
                        setState(() {
                          _loading = true;
                        });
                        await _createStack();
                        statefulSetState(() {
                          _loading = false;
                        });
                        setState(() {
                          _loading == false;
                        });
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    );
                  }),
                ],
              );
            },
          );
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
            padding: const EdgeInsets.all(8),
            child: InfiniteQueryBuilder<List<RecallStack>, HttpException, int>(
              'stacks',
              (page) => _fetchStacks(page),
              nextPage: (lastPage, lastPageData) {
                if (lastPageData.length == 20) return lastPage + 1;
                return null;
              },
              builder: (context, query) {
                this.query = query;
                final stacks = query.pages.map((e) => e).expand((e) => e).toList();
                if (stacks.isEmpty) {
                  return const Center(
                    child: Text(
                      "It looks a little quiet here. Create a new stack!",
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
                  itemBuilder: (_, index) {
                    final stack = stacks[index];
                    return ListTile(
                      title: Text(stack.name),
                      subtitle: Text("${stack.notes} note${stack.notes > 1 ? "s" : stack.notes == 0 ? "s" : ""}"),
                      tileColor: getSecondaryColor(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          10,
                        ),
                      ),
                      onTap: () {
                        logger.i("Moving to Stack Screen with id:${stack.id}");
                        Navigator.of(context).push(
                          NoSwipePageRoute(
                            builder: (context) {
                              return StackScreen(
                                id: stack.id,
                                name: stack.name,
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                  itemCount: stacks.length,
                  shrinkWrap: true,
                );
              },
              initialPage: 1,
              refreshConfig: RefreshConfig.withDefaults(
                context,
                refreshOnMount: true,
                staleDuration: Duration(
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
