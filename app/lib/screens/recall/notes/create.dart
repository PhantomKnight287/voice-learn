import 'dart:convert';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:app/components/input.dart';
import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/main.dart';
import 'package:app/models/language.dart';
import 'package:app/screens/languages/main.dart';
import 'package:app/utils/error.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:toastification/toastification.dart';

class CreateNoteScreen extends StatefulWidget {
  final String? title;
  final String? description;
  final String? stackId;
  final Language? language;
  const CreateNoteScreen({
    super.key,
    this.description,
    this.title,
    this.stackId,
    this.language,
  });

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> with RouteAware {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Language? language;

  Future<List<dynamic>> _fetchStacks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final uri = Uri.parse("$API_URL/recalls/stacks/all");
    logger.d("Requesting ${uri.toString()}");
    final req = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    final body = jsonDecode(req.body);
    if (req.statusCode != 200) {
      final message = ApiResponseHelper.getErrorMessage(body);
      logger.e("Failed to fetch all stacks: $message");
      throw message;
    }
    logger.d("Loaded ${body.length} stacks for dropdown");
    return (body as List);
  }

  String _stackId = "";

  bool _loading = false;

  Future<void> _createNote() async {
    if (_loading) return;
    if (_stackId.isEmpty) {
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("An Error Occurred"),
        description: const Text("Please select a stack"),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
      return;
    }

    if (_formKey.currentState!.validate() == false) return;
    setState(() {
      _loading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final uri = Uri.parse(
      "$API_URL/recalls/$_stackId/notes",
    );
    logger.d("Requesting ${uri.toString()}");
    final req = await http.post(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(
        {
          "title": _titleController.text,
          "description": _descriptionController.text,
          "languageId": language?.id,
        },
      ),
    );
    final body = jsonDecode(req.body);
    setState(() {
      _loading = false;
    });
    if (req.statusCode != 201) {
      final message = ApiResponseHelper.getErrorMessage(body);
      logger.e("Failed to create note: $message");
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("An Error Occurred"),
        description: Text(message),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
      return;
    }
    logger.i("Created Note with id: ${body['id']}");
    setState(() {
      _loading = false;
    });
    toastification.show(
      type: ToastificationType.success,
      style: ToastificationStyle.minimal,
      autoCloseDuration: const Duration(seconds: 5),
      title: const Text("Note Created"),
      alignment: Alignment.topCenter,
      showProgressBar: false,
    );
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.title != null) {
      _titleController.text = widget.title!;
    }
    if (widget.description != null) {
      _descriptionController.text = widget.description!;
    }
    if (widget.stackId != null) {
      _stackId = widget.stackId!;
    }
    if (widget.language != null) {
      language = widget.language!;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    routeObserver.unsubscribe(this);
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
    if (widget.stackId != null) {
      QueryClient.of(context).refreshQuery('notes_$_stackId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create Note",
        ),
        centerTitle: true,
        bottom: BOTTOM(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(BASE_MARGIN * 3),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Title",
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 2,
                  ),
                  InputField(
                    hintText: "KrankenWagen",
                    keyboardType: TextInputType.text,
                    controller: _titleController,
                    minLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter title of your note.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 3,
                  ),
                  Center(
                    child: IconButton(
                      onPressed: () {
                        final title = _titleController.text;
                        _titleController.text = _descriptionController.text;
                        _descriptionController.text = title;
                      },
                      icon: const HeroIcon(
                        HeroIcons.arrowsUpDown,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 3,
                  ),
                  Text(
                    "Description",
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 2,
                  ),
                  InputField(
                    hintMaxLines: 3,
                    hintText: "Ambulance",
                    keyboardType: TextInputType.text,
                    minLines: 5,
                    controller: _descriptionController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter description of your note.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 6,
                  ),
                  Text(
                    "Stack",
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 2,
                  ),
                  QueryBuilder(
                    "all_stacks",
                    _fetchStacks,
                    builder: (context, query) {
                      if (query.isLoading) return const CupertinoActivityIndicator();
                      if (query.hasError) return Text(query.error.toString());
                      final data = query.data;
                      if (data == null || data.isEmpty) return Container();
                      if (_stackId.isEmpty) {
                        return DropdownButtonFormField(
                          hint: Center(
                            child: Text(
                              "Select a stack",
                              style: TextStyle(
                                fontSize: Theme.of(context).textTheme.titleSmall?.fontSize,
                              ),
                            ),
                          ),
                          decoration: InputDecoration(
                            hintText: "Select a stack",
                            contentPadding: const EdgeInsets.all(8.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                            prefixIconColor: Colors.black,
                            filled: true,
                            hintStyle: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall?.fontSize,
                            ),
                            errorStyle: TextStyle(
                              color: Colors.red,
                              fontSize: Theme.of(context).textTheme.titleSmall?.fontSize,
                            ),
                          ),
                          items: data
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item['id'],
                                  child: Text(
                                    item['name'],
                                    style: TextStyle(
                                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _stackId = value as String;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || (value as String).isEmpty) {
                              return 'Please select a stack.';
                            }
                            return null;
                          },
                        );
                      }
                      return DropdownButtonFormField(
                        value: _stackId,
                        hint: Center(
                          child: Text(
                            "Select a stack",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall?.fontSize,
                            ),
                          ),
                        ),
                        decoration: InputDecoration(
                          hintText: "Select a stack",
                          contentPadding: const EdgeInsets.all(8.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none,
                          ),
                          prefixIconColor: Colors.black,
                          filled: true,
                          hintStyle: TextStyle(
                            fontSize: Theme.of(context).textTheme.titleSmall?.fontSize,
                          ),
                          errorStyle: TextStyle(
                            color: Colors.red,
                            fontSize: Theme.of(context).textTheme.titleSmall?.fontSize,
                          ),
                        ),
                        items: data
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item['id'],
                                child: Text(
                                  item['name'],
                                  style: TextStyle(
                                    fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _stackId = value as String;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || (value as String).isEmpty) {
                            return 'Please select a stack.';
                          }
                          return null;
                        },
                      );
                    },
                    refreshConfig: RefreshConfig.withDefaults(
                      context,
                      refreshOnMount: true,
                      refreshInterval: const Duration(
                        minutes: 1,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 6,
                  ),
                  Text(
                    "Language",
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 2,
                  ),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.of(context).push(
                        NoSwipePageRoute(
                          builder: (context) {
                            return const LanguagesScreen();
                          },
                        ),
                      );
                      if (!context.mounted) return;

                      setState(() {
                        language = result;
                      });
                    },
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Color(0xffe7e0e8) : Color(0xff36343a),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            if (language != null) ...{
                              CachedNetworkImage(
                                imageUrl: language!.flagUrl,
                                progressIndicatorBuilder: (context, url, progress) {
                                  return const CircularProgressIndicator.adaptive();
                                },
                                width: 35,
                                height: 35,
                              ),
                              const SizedBox(
                                width: BASE_MARGIN * 1,
                              )
                            },
                            Text(
                              language == null ? "Select a language" : language!.name,
                              style: TextStyle(
                                color: language == null
                                    ? Theme.of(context).hintColor
                                    : AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light
                                        ? Colors.black
                                        : Colors.white,
                                fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 4,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await _createNote();
                    },
                    style: ButtonStyle(
                      alignment: Alignment.center,
                      foregroundColor: WidgetStateProperty.all(Colors.black),
                      padding: WidgetStateProperty.resolveWith<EdgeInsetsGeometry>(
                        (Set<WidgetState> states) {
                          return const EdgeInsets.all(15);
                        },
                      ),
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    child: _loading
                        ? const Center(
                            child: CupertinoActivityIndicator(),
                          )
                        : Text(
                            "Create",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
